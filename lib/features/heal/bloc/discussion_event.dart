import 'package:equatable/equatable.dart';

/// Base class for all discussion events
abstract class DiscussionEvent extends Equatable {
  const DiscussionEvent();

  @override
  List<Object?> get props => [];
}

/// Load discussions (paginated)
class LoadDiscussionsEvent extends DiscussionEvent {
  final int page;
  final String? category;
  final bool refresh;

  const LoadDiscussionsEvent({
    this.page = 1,
    this.category,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, category, refresh];
}

/// Load more discussions (pagination)
class LoadMoreDiscussionsEvent extends DiscussionEvent {
  const LoadMoreDiscussionsEvent();
}

/// Create new discussion
class CreateDiscussionEvent extends DiscussionEvent {
  final String title;
  final String content;
  final String category;
  final String visibility;

  const CreateDiscussionEvent({
    required this.title,
    required this.content,
    required this.category,
    this.visibility = 'public',
  });

  @override
  List<Object?> get props => [title, content, category, visibility];
}

/// Delete discussion
class DeleteDiscussionEvent extends DiscussionEvent {
  final String discussionId;

  const DeleteDiscussionEvent(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

/// Toggle like on discussion
class ToggleDiscussionLikeEvent extends DiscussionEvent {
  final String discussionId;

  const ToggleDiscussionLikeEvent(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

/// Load comments for a discussion
class LoadCommentsEvent extends DiscussionEvent {
  final String discussionId;
  final bool refresh;

  const LoadCommentsEvent({
    required this.discussionId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [discussionId, refresh];
}

/// Add comment to discussion
class AddCommentEvent extends DiscussionEvent {
  final String discussionId;
  final String content;
  final String? parentCommentId;

  const AddCommentEvent({
    required this.discussionId,
    required this.content,
    this.parentCommentId,
  });

  @override
  List<Object?> get props => [discussionId, content, parentCommentId];
}

/// Toggle like on comment
class ToggleCommentLikeEvent extends DiscussionEvent {
  final String commentId;
  final String discussionId;

  const ToggleCommentLikeEvent({
    required this.commentId,
    required this.discussionId,
  });

  @override
  List<Object?> get props => [commentId, discussionId];
}

/// Delete comment
class DeleteCommentEvent extends DiscussionEvent {
  final String commentId;
  final String discussionId;

  const DeleteCommentEvent({
    required this.commentId,
    required this.discussionId,
  });

  @override
  List<Object?> get props => [commentId, discussionId];
}

/// Real-time: New comment received via socket
class CommentReceivedEvent extends DiscussionEvent {
  final Map<String, dynamic> commentData;

  const CommentReceivedEvent(this.commentData);

  @override
  List<Object?> get props => [commentData];
}

/// Real-time: Like update received via socket
class LikeUpdateReceivedEvent extends DiscussionEvent {
  final Map<String, dynamic> likeData;

  const LikeUpdateReceivedEvent(this.likeData);

  @override
  List<Object?> get props => [likeData];
}

/// Real-time: Discussion update received via socket
class DiscussionUpdateReceivedEvent extends DiscussionEvent {
  final Map<String, dynamic> updateData;

  const DiscussionUpdateReceivedEvent(this.updateData);

  @override
  List<Object?> get props => [updateData];
}

/// Join discussion room for real-time updates
class JoinDiscussionRoomEvent extends DiscussionEvent {
  final String discussionId;

  const JoinDiscussionRoomEvent(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

/// Leave discussion room
class LeaveDiscussionRoomEvent extends DiscussionEvent {
  final String discussionId;

  const LeaveDiscussionRoomEvent(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

