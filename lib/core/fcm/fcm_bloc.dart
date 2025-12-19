import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:astrologer_app/core/di/service_locator.dart';
import 'package:astrologer_app/core/services/storage_service.dart';
import '../services/fcm_service.dart';
import 'fcm_event.dart';
import 'fcm_state.dart';

/// BLoC for managing FCM notifications
/// Follows proper BLoC architecture: Events → BLoC → States
/// Reusable for both Astrologer and Customer apps
class FcmBloc extends Bloc<FcmEvent, FcmState> {
  final FcmService _fcmService;

  StreamSubscription<Map<String, dynamic>>? _callSubscription;
  StreamSubscription<Map<String, dynamic>>? _videoCallSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  FcmBloc(this._fcmService) : super(const FcmInitial()) {
    on<InitializeFcmEvent>(_onInitialize);
    on<FcmTokenReceivedEvent>(_onTokenReceived);
    on<FcmNotificationReceivedEvent>(_onNotificationReceived);
    on<FcmNotificationTappedEvent>(_onNotificationTapped);
    on<RegisterFcmTokenEvent>(_onRegisterToken);
  }

  /// Initialize FCM service
  Future<void> _onInitialize(
    InitializeFcmEvent event,
    Emitter<FcmState> emit,
  ) async {
    try {
      print('🔔 [FcmBloc] Initializing FCM...');
      emit(const FcmInitializing());

      await _fcmService.initialize();

      // Subscribe to FCM service streams
      _subscribeToFcmStreams();

      final token = _fcmService.fcmToken;
      emit(FcmReady(
        fcmToken: token,
        permissionGranted: token != null,
      ));

      if (token != null) {
        add(FcmTokenReceivedEvent(token));
      }

      print('✅ [FcmBloc] FCM initialized successfully');
    } catch (e) {
      print('❌ [FcmBloc] Initialization failed: $e');
      emit(FcmError('Failed to initialize FCM: $e'));
    }
  }

  /// Subscribe to FCM service streams
  void _subscribeToFcmStreams() {
    // Listen for voice calls
    _callSubscription = _fcmService.callStream.listen((data) {
      print('📞 [FcmBloc] Voice call notification');
      add(FcmNotificationReceivedEvent(data));
    });

    // Listen for video calls
    _videoCallSubscription = _fcmService.videoCallStream.listen((data) {
      print('📹 [FcmBloc] Video call notification');
      add(FcmNotificationReceivedEvent(data));
    });

    // Listen for messages
    _messageSubscription = _fcmService.messageStream.listen((data) {
      print('💬 [FcmBloc] Message notification');
      add(FcmNotificationReceivedEvent(data));
    });
  }

  /// Handle FCM token received/refreshed
  Future<void> _onTokenReceived(
    FcmTokenReceivedEvent event,
    Emitter<FcmState> emit,
  ) async {
    print('🔔 [FcmBloc] FCM token received: ${event.token.substring(0, 20)}...');
    // Don't emit state here, just log it
    // Backend registration will be triggered separately via RegisterFcmTokenEvent
  }

  /// Handle notification received (foreground)
  Future<void> _onNotificationReceived(
    FcmNotificationReceivedEvent event,
    Emitter<FcmState> emit,
  ) async {
    final type = event.data['type'] as String?;
    final timestamp = DateTime.now();
    final isTapped = event.data['tapped'] == true;
    final action = event.data['action'] as String?;

    print('🔔 [FcmBloc] Processing notification type: $type (action: $action, tapped: $isTapped)');

    switch (type) {
      case 'call':
      case 'voice_call':
        final isVideo = type == 'video_call';
        
        // Check if user performed an action on the notification
        switch (action) {
          case 'accept':
            print('✅ [FcmBloc] Call accepted from notification');
            emit(FcmCallAccepted(
              callData: event.data,
              isVideo: isVideo,
              timestamp: timestamp,
            ));
            break;
            
          case 'decline':
            print('❌ [FcmBloc] Call declined from notification');
            emit(FcmCallDeclined(
              callData: event.data,
              isVideo: isVideo,
              timestamp: timestamp,
            ));
            break;
            
          default:
            // Regular incoming call or tapped notification
            emit(FcmIncomingCallNotification(
              callData: event.data,
              isVideo: isVideo,
              timestamp: timestamp,
            ));
            break;
        }
        break;

      case 'video_call':
        // Check if user performed an action on the notification
        switch (action) {
          case 'accept':
            print('✅ [FcmBloc] Video call accepted from notification');
            emit(FcmCallAccepted(
              callData: event.data,
              isVideo: true,
              timestamp: timestamp,
            ));
            break;
            
          case 'decline':
            print('❌ [FcmBloc] Video call declined from notification');
            emit(FcmCallDeclined(
              callData: event.data,
              isVideo: true,
              timestamp: timestamp,
            ));
            break;
            
          default:
            // Regular incoming call or tapped notification
            emit(FcmIncomingCallNotification(
              callData: event.data,
              isVideo: true,
              timestamp: timestamp,
            ));
            break;
        }
        break;

      case 'message':
      case 'chat':
        // If user tapped notification, navigate to the exact chat
        if (isTapped) {
          final conversationId = event.data['conversationId'] as String? ?? '';
          final senderId = event.data['senderId'] as String? ?? '';
          final senderType = event.data['senderType'] as String? ?? 'admin';
          final senderName = event.data['senderName'] as String? ?? 'User';

          if (conversationId.isNotEmpty) {
            emit(FcmNavigateToChat(
              conversationId: conversationId,
              senderId: senderId,
              senderType: senderType,
              senderName: senderName,
            ));
            break;
          }
        }

        // Otherwise, just expose it as a "new message" notification state
        emit(FcmIncomingMessageNotification(
          messageData: event.data,
          timestamp: timestamp,
        ));
        break;

      default:
        emit(FcmOtherNotification(
          data: event.data,
          type: type ?? 'unknown',
          timestamp: timestamp,
        ));
    }
  }

  /// Handle notification tap (background/terminated)
  Future<void> _onNotificationTapped(
    FcmNotificationTappedEvent event,
    Emitter<FcmState> emit,
  ) async {
    print('🔔 [FcmBloc] Notification tapped');
    // Process same as received notification
    add(FcmNotificationReceivedEvent(event.data));
  }

  /// Register FCM token with backend
  Future<void> _onRegisterToken(
    RegisterFcmTokenEvent event,
    Emitter<FcmState> emit,
  ) async {
    final token = _fcmService.fcmToken;
    if (token == null) {
      print('⚠️ [FcmBloc] No FCM token to register');
      return;
    }

    try {
      print('🔔 [FcmBloc] Registering token with backend...');
      
      // Get auth token from storage
      final storage = getIt<StorageService>();
      final authToken = await storage.getString('auth_token') ?? '';
      
      if (authToken.isEmpty) {
        print('⚠️ [FcmBloc] No auth token found in storage');
        return;
      }
      
      print('✅ [FcmBloc] Got auth token from storage');
      print('📡 [FcmBloc] Calling registerTokenWithBackend...');
      
      final success = await _fcmService.registerTokenWithBackend(
        apiUrl: '', // Not used anymore, API URL is in fcm_service.dart
        authToken: authToken,
        userId: event.userId,
        userType: event.userType,
      );

      if (success) {
        emit(FcmTokenRegistered(token));
        print('✅ [FcmBloc] Token registered successfully');
      } else {
        print('⚠️ [FcmBloc] Token registration failed');
      }
    } catch (e) {
      print('❌ [FcmBloc] Token registration error: $e');
    }
  }

  @override
  Future<void> close() {
    _callSubscription?.cancel();
    _videoCallSubscription?.cancel();
    _messageSubscription?.cancel();
    return super.close();
  }
}

