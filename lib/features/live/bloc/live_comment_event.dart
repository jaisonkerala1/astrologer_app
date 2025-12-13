import 'package:equatable/equatable.dart';
import '../models/live_comment_model.dart';

/// Live Comment Events
abstract class LiveCommentEvent extends Equatable {
  const LiveCommentEvent();
  
  @override
  List<Object?> get props => [];
}

/// Subscribe to live comments for a stream
class LiveCommentSubscribeEvent extends LiveCommentEvent {
  final String streamId;
  
  const LiveCommentSubscribeEvent(this.streamId);
  
  @override
  List<Object?> get props => [streamId];
}

/// New comment received from socket
class LiveCommentReceivedEvent extends LiveCommentEvent {
  final LiveCommentModel comment;
  
  const LiveCommentReceivedEvent(this.comment);
  
  @override
  List<Object?> get props => [comment];
}

/// Send a comment
class LiveCommentSendEvent extends LiveCommentEvent {
  final String streamId;
  final String message;
  
  const LiveCommentSendEvent({
    required this.streamId,
    required this.message,
  });
  
  @override
  List<Object?> get props => [streamId, message];
}

/// Unsubscribe from live comments
class LiveCommentUnsubscribeEvent extends LiveCommentEvent {
  const LiveCommentUnsubscribeEvent();
}

/// Clear all comments (when stream ends)
class LiveCommentClearEvent extends LiveCommentEvent {
  const LiveCommentClearEvent();
}

