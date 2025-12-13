import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/socket_service.dart';
import '../models/live_comment_model.dart';
import 'live_comment_event.dart';
import 'live_comment_state.dart';

/// Live Comment BLoC
/// Manages real-time comments for live streaming
class LiveCommentBloc extends Bloc<LiveCommentEvent, LiveCommentState> {
  final SocketService socketService;
  StreamSubscription<Map<String, dynamic>>? _commentSubscription;
  String? _currentStreamId;
  
  // Constants
  static const int maxFloatingComments = 4; // Show last 4 comments
  static const int maxStoredComments = 200; // Keep max 200 in memory
  
  LiveCommentBloc({
    required this.socketService,
  }) : super(const LiveCommentInitial()) {
    on<LiveCommentSubscribeEvent>(_onSubscribe);
    on<LiveCommentReceivedEvent>(_onCommentReceived);
    on<LiveCommentSendEvent>(_onSendComment);
    on<LiveCommentUnsubscribeEvent>(_onUnsubscribe);
    on<LiveCommentClearEvent>(_onClear);
  }
  
  /// Subscribe to comments for a stream
  Future<void> _onSubscribe(
    LiveCommentSubscribeEvent event,
    Emitter<LiveCommentState> emit,
  ) async {
    try {
      _currentStreamId = event.streamId;
      emit(const LiveCommentLoading());
      
      debugPrint('🔔 [COMMENT BLOC] Subscribing to stream: ${event.streamId}');
      debugPrint('🔔 [COMMENT BLOC] Socket connected: ${socketService.isConnected}');
      
      // Cancel any existing subscription
      await _commentSubscription?.cancel();
      
      // Subscribe to comment stream
      _commentSubscription = socketService.liveCommentStream.listen((data) {
        debugPrint('📥 [COMMENT BLOC] Raw comment data received: $data');
        // Only process comments for our stream
        if (data['streamId'] == _currentStreamId) {
          try {
            final comment = LiveCommentModel.fromJson(data);
            debugPrint('📥 [COMMENT BLOC] Parsed comment: ${comment.userName}: ${comment.message}');
            add(LiveCommentReceivedEvent(comment));
          } catch (e) {
            debugPrint('❌ [COMMENT BLOC] Failed to parse comment: $e');
          }
        } else {
          debugPrint('🔕 [COMMENT BLOC] Comment for different stream: ${data['streamId']} vs $_currentStreamId');
        }
      });
      
      // Emit initial loaded state
      emit(const LiveCommentLoaded(
        allComments: [],
        floatingComments: [],
      ));
      
      debugPrint('✅ [COMMENT BLOC] Subscribed to stream: ${event.streamId}');
      
    } catch (e) {
      debugPrint('❌ [COMMENT BLOC] Subscribe error: $e');
      emit(LiveCommentError('Failed to subscribe to comments: $e'));
    }
  }
  
  /// Handle new comment received from socket
  Future<void> _onCommentReceived(
    LiveCommentReceivedEvent event,
    Emitter<LiveCommentState> emit,
  ) async {
    if (state is LiveCommentLoaded) {
      final currentState = state as LiveCommentLoaded;
      
      // Add to all comments
      final updatedAll = [...currentState.allComments, event.comment];
      
      // Limit stored comments to prevent memory issues
      if (updatedAll.length > maxStoredComments) {
        updatedAll.removeRange(0, updatedAll.length - maxStoredComments);
      }
      
      // Update floating comments (keep only last N)
      final updatedFloating = [...currentState.floatingComments, event.comment];
      if (updatedFloating.length > maxFloatingComments) {
        updatedFloating.removeAt(0);
      }
      
      emit(currentState.copyWith(
        allComments: updatedAll,
        floatingComments: updatedFloating,
      ));
      
      debugPrint('💬 [COMMENT BLOC] Comment received: ${event.comment.userName}: ${event.comment.message}');
    }
  }
  
  /// Send a comment
  Future<void> _onSendComment(
    LiveCommentSendEvent event,
    Emitter<LiveCommentState> emit,
  ) async {
    try {
      // Validate message
      final message = event.message.trim();
      if (message.isEmpty) {
        debugPrint('⚠️ [COMMENT BLOC] Empty message, not sending');
        return;
      }
      
      if (message.length > 200) {
        emit(const LiveCommentError('Message too long (max 200 characters)'));
        return;
      }
      
      // Send via socket
      socketService.sendLiveComment(
        streamId: event.streamId,
        message: message,
      );
      
      debugPrint('📤 [COMMENT BLOC] Sent comment: $message');
      
      // Note: We don't add the comment locally here
      // We'll receive it back via the socket broadcast
      
    } catch (e) {
      debugPrint('❌ [COMMENT BLOC] Send error: $e');
      emit(LiveCommentError('Failed to send comment: $e'));
    }
  }
  
  /// Unsubscribe from comments
  Future<void> _onUnsubscribe(
    LiveCommentUnsubscribeEvent event,
    Emitter<LiveCommentState> emit,
  ) async {
    await _commentSubscription?.cancel();
    _commentSubscription = null;
    _currentStreamId = null;
    emit(const LiveCommentInitial());
    
    debugPrint('👋 [COMMENT BLOC] Unsubscribed from comments');
  }
  
  /// Clear all comments
  Future<void> _onClear(
    LiveCommentClearEvent event,
    Emitter<LiveCommentState> emit,
  ) async {
    if (state is LiveCommentLoaded) {
      emit(const LiveCommentLoaded(
        allComments: [],
        floatingComments: [],
      ));
      debugPrint('🗑️ [COMMENT BLOC] Cleared all comments');
    }
  }
  
  @override
  Future<void> close() {
    _commentSubscription?.cancel();
    return super.close();
  }
}

