import 'package:equatable/equatable.dart';
import '../models/communication_item.dart';

/// Base event for Call BLoC
abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

/// Event when an incoming call is received
class IncomingCallEvent extends CallEvent {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerType;
  final String? callerAvatar;
  final String callType; // 'voice' or 'video'
  final String? agoraToken;
  final String? agoraAppId;
  final String? channelName;
  final int? uid;

  const IncomingCallEvent({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerType,
    this.callerAvatar,
    required this.callType,
    this.agoraToken,
    this.agoraAppId,
    this.channelName,
    this.uid,
  });

  @override
  List<Object?> get props => [
        callId,
        callerId,
        callerName,
        callerType,
        callerAvatar,
        callType,
        agoraToken,
        agoraAppId,
        channelName,
        uid,
      ];

  /// Get ContactType from callerType string
  ContactType get contactType {
    switch (callerType.toLowerCase()) {
      case 'admin':
        return ContactType.admin;
      case 'user':
        return ContactType.user;
      case 'astrologer':
        return ContactType.astrologer;
      default:
        return ContactType.user;
    }
  }
}

/// Event when user accepts the call
class AcceptCallEvent extends CallEvent {
  final String callId;
  final String contactId;

  const AcceptCallEvent({
    required this.callId,
    required this.contactId,
  });

  @override
  List<Object?> get props => [callId, contactId];
}

/// Event when user rejects the call
class RejectCallEvent extends CallEvent {
  final String callId;
  final String contactId;
  final String reason;

  const RejectCallEvent({
    required this.callId,
    required this.contactId,
    this.reason = 'declined',
  });

  @override
  List<Object?> get props => [callId, contactId, reason];
}

/// Event when call is connected
class CallConnectedEvent extends CallEvent {
  final String callId;

  const CallConnectedEvent({required this.callId});

  @override
  List<Object?> get props => [callId];
}

/// Event when call ends
class EndCallEvent extends CallEvent {
  final String callId;
  final String? contactId;
  final int? duration;
  final String reason;

  const EndCallEvent({
    required this.callId,
    this.contactId,
    this.duration,
    this.reason = 'completed',
  });

  @override
  List<Object?> get props => [callId, contactId, duration, reason];
}

/// Event to dismiss call (after rejected/ended)
class DismissCallEvent extends CallEvent {
  const DismissCallEvent();
}
