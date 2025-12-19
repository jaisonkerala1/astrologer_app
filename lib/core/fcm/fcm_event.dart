import 'package:equatable/equatable.dart';

/// Base class for FCM events
abstract class FcmEvent extends Equatable {
  const FcmEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize FCM service
class InitializeFcmEvent extends FcmEvent {
  const InitializeFcmEvent();
}

/// FCM token received/refreshed
class FcmTokenReceivedEvent extends FcmEvent {
  final String token;

  const FcmTokenReceivedEvent(this.token);

  @override
  List<Object?> get props => [token];
}

/// Push notification received (foreground)
class FcmNotificationReceivedEvent extends FcmEvent {
  final Map<String, dynamic> data;

  const FcmNotificationReceivedEvent(this.data);

  @override
  List<Object?> get props => [data];
}

/// Push notification tapped (background/terminated)
class FcmNotificationTappedEvent extends FcmEvent {
  final Map<String, dynamic> data;

  const FcmNotificationTappedEvent(this.data);

  @override
  List<Object?> get props => [data];
}

/// Register FCM token with backend
class RegisterFcmTokenEvent extends FcmEvent {
  final String userId;
  final String userType;

  const RegisterFcmTokenEvent({
    required this.userId,
    required this.userType,
  });

  @override
  List<Object?> get props => [userId, userType];
}





