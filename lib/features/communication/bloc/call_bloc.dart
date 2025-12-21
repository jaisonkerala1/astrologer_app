import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/di/service_locator.dart';
import 'call_event.dart';
import 'call_state.dart';

/// BLoC for managing voice and video calls
/// Handles incoming calls, accept/reject, and call lifecycle
class CallBloc extends Bloc<CallEvent, CallState> {
  final SocketService socketService;
  StreamSubscription? _callIncomingSubscription;
  StreamSubscription? _callAcceptedSubscription;
  StreamSubscription? _callRejectedSubscription;
  StreamSubscription? _callEndedSubscription;
  Timer? _connectRetryTimer;
  int _connectRetries = 0;
  // CallIds that have been acted upon locally (accepted/declined/ended) so we
  // can ignore late/duplicate incoming events (e.g. accept from notification
  // before Socket.IO "incoming" arrives).
  final Set<String> _handledCallIds = <String>{};

  CallBloc({required this.socketService}) : super(const CallIdle()) {
    // Use sequential() transformer to process events one at a time
    // This ensures AcceptCallEvent is fully processed (including adding to _handledCallIds)
    // before any subsequent IncomingCallEvent can be processed
    on<IncomingCallEvent>(_onIncomingCall, transformer: sequential());
    on<AcceptCallEvent>(_onAcceptCall, transformer: sequential());
    on<RejectCallEvent>(_onRejectCall, transformer: sequential());
    on<DeclineCallEvent>(_onDeclineCall, transformer: sequential());
    on<MarkCallHandledEvent>(_onMarkCallHandled, transformer: sequential());
    on<CallConnectedEvent>(_onCallConnected);
    on<EndCallEvent>(_onEndCall);
    on<DismissCallEvent>(_onDismissCall);

    // Ensure socket is connected on app startup so incoming calls/messages
    // arrive even before opening the chat screen.
    _ensureSocketConnected();

    // Subscribe to global call events from Socket.IO
    _subscribeToCallEvents();
  }

  void _ensureSocketConnected() {
    if (socketService.isConnected) return;

    // Try to connect immediately
    socketService.connect();

    // If token wasn't ready yet, retry a few times with backoff
    _connectRetryTimer?.cancel();
    _connectRetries = 0;
    _connectRetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (socketService.isConnected) {
        timer.cancel();
        return;
      }
      if (_connectRetries >= 5) {
        timer.cancel();
        return;
      }
      _connectRetries += 1;
      socketService.connect();
    });
  }

  void _subscribeToCallEvents() {
    print('📞 [CallBloc] Subscribing to global call events');

    // Listen for incoming calls
    _callIncomingSubscription = socketService.callIncomingStream.listen((data) {
      print('📞 [CallBloc] Incoming call received: $data');
      
      try {
        add(IncomingCallEvent(
          callId: data['callId'] ?? '',
          callerId: data['callerId'] ?? '',
          callerName: data['callerName'] ?? 'Unknown',
          callerType: data['callerType'] ?? 'user',
          callerAvatar: data['callerAvatar'],
          callType: data['callType'] ?? 'voice',
          agoraToken: data['agoraToken'],
          agoraAppId: data['agoraAppId'],
          channelName: data['channelName'],
          uid: data['uid'],
        ));
      } catch (e) {
        print('❌ [CallBloc] Error parsing incoming call: $e');
      }
    });

    // Listen for call accepted (if we're the caller)
    _callAcceptedSubscription = socketService.callAcceptedStream.listen((data) {
      print('✅ [CallBloc] Call accepted: $data');
      // Handle if needed
    });

    // Listen for call rejected
    _callRejectedSubscription = socketService.callRejectedStream.listen((data) {
      print('❌ [CallBloc] Call rejected: $data');
      add(EndCallEvent(
        callId: data['callId'] ?? '',
        reason: data['reason'] ?? 'rejected',
      ));
    });

    // Listen for call ended
    _callEndedSubscription = socketService.callEndedStream.listen((data) {
      print('📴 [CallBloc] Call ended: $data');
      add(EndCallEvent(
        callId: data['callId'] ?? '',
        duration: data['duration'],
        reason: data['reason'] ?? 'ended',
      ));
    });
  }

  Future<void> _onIncomingCall(
    IncomingCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('📞 [CallBloc] Processing incoming call from ${event.callerName}');

    if (_handledCallIds.contains(event.callId)) {
      print('⏭️ [CallBloc] Ignoring incoming call ${event.callId} (already handled locally)');
      return;
    }
    
    // Deduplicate: if already showing this exact call, ignore duplicate
    if (state is CallIncoming) {
      final currentCall = state as CallIncoming;
      if (currentCall.callId == event.callId) {
        print('! [CallBloc] Ignoring duplicate call: ${event.callId}');
        return;
      }
    }
    
    // Double-check right before emitting (race condition protection)
    if (_handledCallIds.contains(event.callId)) {
      print('⏭️ [CallBloc] Call ${event.callId} was handled while processing (race condition avoided)');
      return;
    }
    
    emit(CallIncoming(
      callId: event.callId,
      callerId: event.callerId,
      callerName: event.callerName,
      contactType: event.contactType,
      callerAvatar: event.callerAvatar,
      callType: event.callType,
      agoraToken: event.agoraToken,
      agoraAppId: event.agoraAppId,
      channelName: event.channelName,
      uid: event.uid,
    ));
  }

  Future<void> _onMarkCallHandled(
    MarkCallHandledEvent event,
    Emitter<CallState> emit,
  ) async {
    if (event.callId.isEmpty) return;
    _handledCallIds.add(event.callId);
    print('🧷 [CallBloc] Marked call as handled: ${event.callId}');
  }

  Future<void> _onAcceptCall(
    AcceptCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('✅ [CallBloc] Accepting call: ${event.callId}');
    _handledCallIds.add(event.callId);

    // Cancel notification
    try {
      final fcmService = getIt<FcmService>();
      await fcmService.cancelCallNotification(event.callId);
    } catch (e) {
      print('⚠️ [CallBloc] Failed to cancel notification: $e');
    }

    // Always emit accept via Socket.IO.
    // IMPORTANT: Accept can come from notification before CallIncoming state is set.
    socketService.acceptCall(
      callId: event.callId,
      contactId: event.contactId,
    );

    if (state is CallIncoming) {
      final incomingState = state as CallIncoming;

      // Transition to connecting state
      emit(CallConnecting(
        callId: event.callId,
        contactId: incomingState.callerId,
        contactName: incomingState.callerName,
        contactType: incomingState.contactType,
        callType: incomingState.callType,
        agoraToken: incomingState.agoraToken,
        agoraAppId: incomingState.agoraAppId,
        channelName: incomingState.channelName,
        uid: incomingState.uid,
      ));
    } else {
      print('⚠️ [CallBloc] Accept received while not in CallIncoming (${state.runtimeType}). Sent accept to backend anyway.');
    }
  }

  Future<void> _onRejectCall(
    RejectCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('❌ [CallBloc] Rejecting call: ${event.callId}');
    _handledCallIds.add(event.callId);

    // Cancel notification
    try {
      final fcmService = getIt<FcmService>();
      await fcmService.cancelCallNotification(event.callId);
    } catch (e) {
      print('⚠️ [CallBloc] Failed to cancel notification: $e');
    }

    // Emit reject via Socket.IO
    socketService.rejectCall(
      callId: event.callId,
      contactId: event.contactId,
      reason: event.reason,
    );

    // End the call
    emit(CallEnded(reason: event.reason));

    // Auto-dismiss after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    emit(const CallIdle());
  }

  Future<void> _onDeclineCall(
    DeclineCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('❌ [CallBloc] Declining call from notification: ${event.callId}');
    _handledCallIds.add(event.callId);

    // Cancel notification
    try {
      final fcmService = getIt<FcmService>();
      await fcmService.cancelCallNotification(event.callId);
    } catch (e) {
      print('⚠️ [CallBloc] Failed to cancel notification: $e');
    }

    // Emit reject via Socket.IO (no contactId needed - server can figure it out from callId)
    socketService.rejectCall(
      callId: event.callId,
      contactId: '', // Server will derive from callId
      reason: 'declined',
    );

    // If we're in incoming state, end it; otherwise just stay idle
    if (state is CallIncoming) {
      emit(const CallEnded(reason: 'declined'));
      await Future.delayed(const Duration(seconds: 1));
      emit(const CallIdle());
    }
  }

  Future<void> _onCallConnected(
    CallConnectedEvent event,
    Emitter<CallState> emit,
  ) async {
    print('🔗 [CallBloc] Call connected: ${event.callId}');

    if (state is CallConnecting) {
      final connectingState = state as CallConnecting;
      
      emit(CallActive(
        callId: event.callId,
        contactId: connectingState.contactId,
        contactName: connectingState.contactName,
        contactType: connectingState.contactType,
        callType: connectingState.callType,
        startTime: DateTime.now(),
      ));
    }
  }

  Future<void> _onEndCall(
    EndCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('📴 [CallBloc] Ending call: ${event.callId} (current state: ${state.runtimeType})');
    _handledCallIds.add(event.callId);

    // Cancel notification (critical for incoming calls ended by other party)
    try {
      final fcmService = getIt<FcmService>();
      await fcmService.cancelCallNotification(event.callId);
      print('✅ [CallBloc] Notification cancelled for call: ${event.callId}');
    } catch (e) {
      print('⚠️ [CallBloc] Failed to cancel notification: $e');
    }

    // Emit end via Socket.IO ONLY if we're ending it from our side
    if (event.contactId != null) {
      socketService.endCall(
        callId: event.callId,
        contactId: event.contactId!,
        duration: event.duration,
      );
    }

    // If call was incoming (not answered yet), just go to idle immediately
    if (state is CallIncoming) {
      print('📴 [CallBloc] Call ended while still ringing, going to idle');
      emit(const CallIdle());
      return;
    }

    // Otherwise, show ended state briefly
    emit(CallEnded(
      reason: event.reason,
      duration: event.duration,
    ));

    // Auto-dismiss after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    emit(const CallIdle());

    // Clear handled call after UI settles (so future calls work)
    _handledCallIds.remove(event.callId);
  }

  Future<void> _onDismissCall(
    DismissCallEvent event,
    Emitter<CallState> emit,
  ) async {
    print('🚪 [CallBloc] Dismissing call UI');
    emit(const CallIdle());
  }

  @override
  Future<void> close() {
    _callIncomingSubscription?.cancel();
    _callAcceptedSubscription?.cancel();
    _callRejectedSubscription?.cancel();
    _callEndedSubscription?.cancel();
    _connectRetryTimer?.cancel();
    return super.close();
  }
}
