import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:astrologer_app/core/constants/api_constants.dart';
import 'storage_service.dart';

/// Top-level function to handle background FCM messages
/// MUST be at top level (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM Background] Message received: ${message.messageId}');
  print('🔔 [FCM Background] Type: ${message.data['type']}');
  // Background notifications are automatically shown by FCM
}

/// FCM Service for handling push notifications
/// Integrates with existing LocalNotificationService
/// Reusable for both Astrologer App and Customer App
class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StorageService _storage = StorageService();

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
  /// LocalNotificationService will handle the actual notification display
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 [FCM] Foreground message: ${message.messageId}');
    print('🔔 [FCM] Data: ${message.data}');

    final notificationType = message.data['type'] as String?;
    
    switch (notificationType) {
      case 'call':
      case 'voice_call':
        print('📞 [FCM] Incoming voice call notification');
        _callController.add(message.data);
        break;
        
      case 'video_call':
        print('📹 [FCM] Incoming video call notification');
        _videoCallController.add(message.data);
        break;
        
      case 'message':
      case 'chat':
        print('💬 [FCM] New message notification');
        _messageController.add(message.data);
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
        _messageController.add(message.data);
        break;
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
      final url = '${ApiConstants.baseUrl}/fcm/register';
      
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

