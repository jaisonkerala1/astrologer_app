import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:astrologer_app/core/constants/api_constants.dart';
import 'storage_service.dart';

/// Top-level function to handle background FCM messages
/// MUST be at top level (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM Background] Message received: ${message.messageId}');
  print('🔔 [FCM Background] Type: ${message.data['type']}');
  
  final notificationType = message.data['type'] as String?;
  
  // For calls, show full-screen notification with Accept/Decline actions
  if (notificationType == 'call' || notificationType == 'video_call') {
    await showIncomingCallNotification(message);
  }
  // Messages are handled by default FCM
}

/// Top-level helper to show incoming call notification (works on locked screen)
/// Must be at top level for background isolate
@pragma('vm:entry-point')
Future<void> showIncomingCallNotification(RemoteMessage message) async {
  if (!Platform.isAndroid) return;
  
  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize with minimal settings for background isolate
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    final callData = message.data;
    final isVideo = callData['type'] == 'video_call';
    final callerName = callData['callerName'] ?? 'Unknown';
    final callId = callData['callId'] ?? '';
    
    // Encode all call data as JSON in payload for later retrieval
    final payloadJson = jsonEncode({
      'type': callData['type'],
      'callId': callId,
      'callerId': callData['callerId'],
      'callerName': callerName,
      'callerType': callData['callerType'],
      'channelName': callData['channelName'],
      'agoraToken': callData['agoraToken'],
      'agoraAppId': callData['agoraAppId'],
      'callerAvatar': callData['callerAvatar'],
    });
    
    print('📞 [FCM Background] Showing incoming ${isVideo ? 'video' : 'voice'} call from $callerName');
    
    // High-priority heads-up notification with actions
    // This will show on locked screen on most Android versions
    final androidDetails = AndroidNotificationDetails(
      'calls',
      'Calls',
      channelDescription: 'Incoming voice and video calls',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public, // Show on lock screen
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      usesChronometer: false,
      timeoutAfter: 30000, // Auto-dismiss after 30 seconds
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'CALL_ACCEPT',
          'Accept',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_call_accept'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'CALL_DECLINE',
          'Decline',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_call_decline'),
          cancelNotification: true,
        ),
      ],
    );
    
    await flutterLocalNotificationsPlugin.show(
      callId.hashCode,
      'Incoming ${isVideo ? 'Video' : 'Voice'} Call',
      callerName,
      NotificationDetails(android: androidDetails),
      payload: payloadJson,
    );
    
    print('✅ [FCM Background] Call notification shown');
  } catch (e) {
    print('❌ [FCM Background] Error showing call notification: $e');
  }
}

/// FCM Service for handling push notifications
/// Integrates with existing LocalNotificationService
/// Reusable for both Astrologer App and Customer App
class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StorageService _storage = StorageService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Streams for different notification types (CallBloc/MessageBloc can subscribe)
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _callController = StreamController<Map<String, dynamic>>.broadcast();
  final _videoCallController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get callStream => _callController.stream;
  Stream<Map<String, dynamic>> get videoCallStream => _videoCallController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM (call this on app startup)
  Future<void> initialize() async {
    try {
      print('🔔 [FCM] Initializing Firebase Cloud Messaging...');

      // Initialize local notifications with channels
      await _initializeLocalNotifications();

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 [FCM] Permission status: ${settings.authorizationStatus}');

      // Request full-screen intent permission for Android 12+ (API 31+)
      if (Platform.isAndroid) {
        try {
          // This permission is needed for full-screen call notifications
          final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.status;
          print('🔔 [FCM] Schedule exact alarm permission: $scheduleExactAlarmStatus');
          
          // Note: USE_FULL_SCREEN_INTENT is a normal permission on Android 10-11
          // but requires user approval via Settings on Android 12+
          print('🔔 [FCM] Full-screen intent permission added to manifest');
        } catch (e) {
          print('⚠️ [FCM] Could not check exact alarm permission: $e');
        }
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('🔔 [FCM] Token: $_fcmToken');
        
        if (_fcmToken != null) {
          await _storage.saveFcmToken(_fcmToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('🔔 [FCM] Token refreshed: $newToken');
          _fcmToken = newToken;
          _storage.saveFcmToken(newToken);
        });

        // Setup message handlers
        _setupMessageHandlers();

        print('✅ [FCM] Initialization complete');
      } else {
        print('⚠️ [FCM] Notification permission denied');
      }
    } catch (e) {
      print('❌ [FCM] Initialization error: $e');
    }
  }

  /// Initialize local notifications with proper channels
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 [FCM] Notification response: action=${response.actionId}, payload=${response.payload}');
        _handleLocalNotificationResponse(response);
      },
    );

    // Create Android notification channels with sound, vibration, and wake-up
    if (Platform.isAndroid) {
      // Calls channel (HIGH importance, max priority)
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'calls',
              'Calls',
              description: 'Incoming voice and video calls',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
              // Use default sound
            ),
          );

      // Messages channel (HIGH importance)
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'messages',
              'Messages',
              description: 'New messages from admin and users',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
              // Use default sound
            ),
          );

      // Default channel (HIGH importance)
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'default',
              'Default Notifications',
              description: 'General app notifications',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
              // Use default sound
            ),
          );

      print('✅ [FCM] Android notification channels created');
    }
  }

  /// Setup FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle messages that opened the app from terminated state
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        print('🔔 [FCM] App opened from terminated state');
        _handleBackgroundMessageTap(message);
      }
    });
  }

  /// Handle messages received while app is in foreground
  /// Shows local notification that user can tap to navigate
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 [FCM] Foreground message: ${message.messageId}');
    print('🔔 [FCM] Data: ${message.data}');

    final notificationType = message.data['type'] as String?;
    
    // For calls: don't show notification in foreground since Socket.IO already handles it
    // We only show call notifications when app is background/terminated
    // For messages: show notification
    if (Platform.isAndroid && notificationType == 'message' || notificationType == 'chat') {
      final conversationId = message.data['conversationId'] ?? '';
      final senderId = message.data['senderId'] ?? '';
      final senderType = message.data['senderType'] ?? 'admin';
      final senderName = message.data['senderName'] ?? 'User';
      
      // Simple message notification
      final payload = 'message:$conversationId:$senderId:$senderType';
      await _localNotifications.show(
        message.hashCode,
        senderName,
        message.data['content'] ?? 'New message',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages',
            'Messages',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        ),
        payload: payload,
      );
    }
    
    // Emit to streams for in-app handling (for messages only)
    // Calls are already handled by Socket.IO in foreground
    switch (notificationType) {
      case 'message':
      case 'chat':
        print('💬 [FCM] New message notification');
        _messageController.add(message.data);
        break;
        
      case 'call':
      case 'voice_call':
      case 'video_call':
        print('📞 [FCM] Call in foreground - Socket.IO already handling, skipping');
        break;
        
      default:
        print('⚠️ [FCM] Unknown notification type: $notificationType');
    }
  }

  /// Handle notification tap (background/terminated)
  /// Routes to appropriate screen via streams (CallBloc/MessageBloc listen)
  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('🔔 [FCM] Background message tapped: ${message.messageId}');
    
    final notificationType = message.data['type'] as String?;
    
    switch (notificationType) {
      case 'call':
      case 'voice_call':
        _callController.add(message.data);
        break;
        
      case 'video_call':
        _videoCallController.add(message.data);
        break;
        
      case 'message':
      case 'chat':
        _messageController.add({...message.data, 'tapped': true});
        break;
    }
  }

  /// Handle local notification response (tap or action button)
  void _handleLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;
    
    if (payload == null) return;
    
    try {
      // Try to parse as JSON (call notifications)
      if (payload.startsWith('{')) {
        final callData = jsonDecode(payload) as Map<String, dynamic>;
        final type = callData['type'] as String?;
        
        if (type == 'call' || type == 'video_call') {
          // Handle call notification action
          switch (actionId) {
            case 'CALL_ACCEPT':
              print('✅ [FCM] Call accepted from notification');
              callData['action'] = 'accept';
              _callController.add(callData);
              break;
              
            case 'CALL_DECLINE':
              print('❌ [FCM] Call declined from notification');
              callData['action'] = 'decline';
              _callController.add(callData);
              break;
              
            default:
              // Tap on notification body
              print('👆 [FCM] Call notification tapped');
              callData['action'] = 'tap';
              _callController.add(callData);
              break;
          }
        }
        return;
      }
      
      // Legacy format for message notifications: "type:conversationId:senderId:senderType"
      final parts = payload.split(':');
      if (parts.isEmpty) return;
      
      final type = parts[0];
      
      switch (type) {
        case 'message':
        case 'chat':
          if (parts.length >= 4) {
            _messageController.add({
              'type': 'message',
              'conversationId': parts[1],
              'senderId': parts[2],
              'senderType': parts[3],
              'tapped': true,
            });
          }
          break;
      }
    } catch (e) {
      print('❌ [FCM] Error parsing notification response: $e');
    }
  }
  
  /// Cancel a call notification by ID
  Future<void> cancelCallNotification(String callId) async {
    try {
      await _localNotifications.cancel(callId.hashCode);
      print('🔕 [FCM] Cancelled call notification for $callId');
    } catch (e) {
      print('❌ [FCM] Error cancelling notification: $e');
    }
  }

  /// Send FCM token to backend (call this after login)
  Future<bool> registerTokenWithBackend({
    required String apiUrl,
    required String authToken,
    required String userId,
    required String userType, // 'astrologer' or 'customer'
  }) async {
    if (_fcmToken == null) {
      print('⚠️ [FCM] No token to register');
      return false;
    }

    try {
      print('🔔 [FCM] Registering token with backend...');
      
      final dio = Dio();
      final url = '${ApiConstants.baseUrl}/api/fcm/register';
      
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      
      print('📡 [FCM] POST $url');
      print('📡 [FCM] Platform: $platform');
      
      final response = await dio.post(
        url,
        data: {
          'fcmToken': _fcmToken,
          'platform': platform,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ [FCM] Token registered successfully');
        print('📡 [FCM] Response: ${response.data['message']}');
        return true;
      } else {
        print('⚠️ [FCM] Registration failed: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ [FCM] Token registration failed: $e');
      return false;
    }
  }

  /// Dispose streams
  void dispose() {
    _messageController.close();
    _callController.close();
    _videoCallController.close();
  }
}

/// Extension for StorageService to handle FCM token
extension FcmTokenStorage on StorageService {
  static const _fcmTokenKey = 'fcm_token';

  Future<void> saveFcmToken(String token) async {
    await setString(_fcmTokenKey, token);
    print('💾 [FCM] Token saved to storage');
  }

  Future<String?> getFcmToken() async {
    return getString(_fcmTokenKey);
  }
}

