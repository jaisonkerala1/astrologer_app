import 'package:equatable/equatable.dart';
import '../models/communication_item.dart';

/// Base state for Call BLoC
abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no active call
class CallIdle extends CallState {
  const CallIdle();
}

/// State when there's an incoming call
class CallIncoming extends CallState {
  final String callId;
  final String callerId;
  final String callerName;
  final ContactType contactType;
  final String? callerAvatar;
  final String callType; // 'voice' or 'video'
  final String? agoraToken;
  final String? agoraAppId;
  final String? channelName;
  final int? uid;

  const CallIncoming({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.contactType,
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
        contactType,
        callerAvatar,
        callType,
        agoraToken,
        agoraAppId,
        channelName,
        uid,
      ];
}

/// State when call is being connected
class CallConnecting extends CallState {
  final String callId;
  final String contactId;
  final String contactName;
  final ContactType contactType;
  final String callType;
  final String? agoraToken;
  final String? agoraAppId;
  final String? channelName;
  final int? uid;

  const CallConnecting({
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    required this.callType,
    this.agoraToken,
    this.agoraAppId,
    this.channelName,
    this.uid,
  });

  @override
  List<Object?> get props => [
        callId,
        contactId,
        contactName,
        contactType,
        callType,
        agoraToken,
        agoraAppId,
        channelName,
        uid,
      ];
}

/// State when call is active
class CallActive extends CallState {
  final String callId;
  final String contactId;
  final String contactName;
  final ContactType contactType;
  final String callType;
  final DateTime startTime;

  const CallActive({
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    required this.callType,
    required this.startTime,
  });

  @override
  List<Object?> get props => [
        callId,
        contactId,
        contactName,
        contactType,
        callType,
        startTime,
      ];
}

/// State when call has ended
class CallEnded extends CallState {
  final String reason;
  final int? duration;

  const CallEnded({
    required this.reason,
    this.duration,
  });

  @override
  List<Object?> get props => [reason, duration];
}

/// State when there's a call error
class CallError extends CallState {
  final String message;

  const CallError({required this.message});

  @override
  List<Object?> get props => [message];
}
