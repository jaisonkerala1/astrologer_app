import 'package:equatable/equatable.dart';

/// Base class for FCM states
abstract class FcmState extends Equatable {
  const FcmState();

  @override
  List<Object?> get props => [];
}

/// Initial state before FCM is initialized
class FcmInitial extends FcmState {
  const FcmInitial();
}

/// FCM is being initialized
class FcmInitializing extends FcmState {
  const FcmInitializing();
}

/// FCM initialized and ready
class FcmReady extends FcmState {
  final String? fcmToken;
  final bool permissionGranted;

  const FcmReady({
    this.fcmToken,
    required this.permissionGranted,
  });

  @override
  List<Object?> get props => [fcmToken, permissionGranted];
}

/// FCM token registered with backend
class FcmTokenRegistered extends FcmState {
  final String token;

  const FcmTokenRegistered(this.token);

  @override
  List<Object?> get props => [token];
}

/// Incoming call notification (voice or video)
class FcmIncomingCallNotification extends FcmState {
  final Map<String, dynamic> callData;
  final bool isVideo;
  final DateTime timestamp;

  const FcmIncomingCallNotification({
    required this.callData,
    required this.isVideo,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [callData, isVideo, timestamp];
}

/// Incoming message notification
class FcmIncomingMessageNotification extends FcmState {
  final Map<String, dynamic> messageData;
  final DateTime timestamp;

  const FcmIncomingMessageNotification({
    required this.messageData,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [messageData, timestamp];
}

/// Other notification type
class FcmOtherNotification extends FcmState {
  final Map<String, dynamic> data;
  final String type;
  final DateTime timestamp;

  const FcmOtherNotification({
    required this.data,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [data, type, timestamp];
}

/// FCM error
class FcmError extends FcmState {
  final String message;

  const FcmError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Navigate to chat screen (when notification is tapped)
class FcmNavigateToChat extends FcmState {
  final String conversationId;
  final String senderId;
  final String senderType;
  final String senderName;

  const FcmNavigateToChat({
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    this.senderName = 'User',
  });

  @override
  List<Object?> get props => [conversationId, senderId, senderType, senderName];
}

/// Call accepted from notification action button
class FcmCallAccepted extends FcmState {
  final Map<String, dynamic> callData;
  final bool isVideo;
  final DateTime timestamp;

  const FcmCallAccepted({
    required this.callData,
    required this.isVideo,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [callData, isVideo, timestamp];
}

/// Call declined from notification action button
class FcmCallDeclined extends FcmState {
  final Map<String, dynamic> callData;
  final bool isVideo;
  final DateTime timestamp;

  const FcmCallDeclined({
    required this.callData,
    required this.isVideo,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [callData, isVideo, timestamp];
}





