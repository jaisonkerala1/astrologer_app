import 'package:equatable/equatable.dart';
import '../models/live_comment_model.dart';

/// Live Comment States
abstract class LiveCommentState extends Equatable {
  const LiveCommentState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state - not subscribed yet
class LiveCommentInitial extends LiveCommentState {
  const LiveCommentInitial();
}

/// Loading state - subscribing to stream
class LiveCommentLoading extends LiveCommentState {
  const LiveCommentLoading();
}

/// Loaded state - comments are being received
class LiveCommentLoaded extends LiveCommentState {
  final List<LiveCommentModel> allComments;
  final List<LiveCommentModel> floatingComments; // Last 4-5 for display
  
  const LiveCommentLoaded({
    required this.allComments,
    required this.floatingComments,
  });
  
  /// Copy with new comments
  LiveCommentLoaded copyWith({
    List<LiveCommentModel>? allComments,
    List<LiveCommentModel>? floatingComments,
  }) {
    return LiveCommentLoaded(
      allComments: allComments ?? this.allComments,
      floatingComments: floatingComments ?? this.floatingComments,
    );
  }
  
  @override
  List<Object?> get props => [allComments, floatingComments];
}

/// Error state
class LiveCommentError extends LiveCommentState {
  final String message;
  
  const LiveCommentError(this.message);
  
  @override
  List<Object?> get props => [message];
}

