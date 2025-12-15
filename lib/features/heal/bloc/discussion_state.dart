import 'package:equatable/equatable.dart';
import '../models/discussion_models.dart';
import '../services/discussion_api_service.dart';

/// Base class for all discussion states
abstract class DiscussionState extends Equatable {
  const DiscussionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DiscussionInitial extends DiscussionState {
  const DiscussionInitial();
}

/// Loading discussions
class DiscussionLoading extends DiscussionState {
  const DiscussionLoading();
}

/// Discussions loaded successfully
class DiscussionLoaded extends DiscussionState {
  final List<DiscussionPost> discussions;
  final PaginationInfo pagination;
  final String? selectedCategory;
  final bool isLoadingMore;
  final bool isRefreshing;

  const DiscussionLoaded({
    required this.discussions,
    required this.pagination,
    this.selectedCategory,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        discussions,
        pagination,
        selectedCategory,
        isLoadingMore,
        isRefreshing,
      ];

  DiscussionLoaded copyWith({
    List<DiscussionPost>? discussions,
    PaginationInfo? pagination,
    String? selectedCategory,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return DiscussionLoaded(
      discussions: discussions ?? this.discussions,
      pagination: pagination ?? this.pagination,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Error loading discussions
class DiscussionError extends DiscussionState {
  final String message;

  const DiscussionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Creating a new discussion
class DiscussionCreating extends DiscussionState {
  const DiscussionCreating();
}

/// Discussion created successfully
class DiscussionCreated extends DiscussionState {
  final DiscussionPost discussion;

  const DiscussionCreated(this.discussion);

  @override
  List<Object?> get props => [discussion];
}

// ============ Comment States ============

/// Loading comments for a discussion
class CommentsLoading extends DiscussionState {
  final String discussionId;

  const CommentsLoading(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

/// Comments loaded successfully
class CommentsLoaded extends DiscussionState {
  final String discussionId;
  final List<DiscussionComment> comments;
  final PaginationInfo pagination;
  final bool isRefreshing;

  const CommentsLoaded({
    required this.discussionId,
    required this.comments,
    required this.pagination,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [discussionId, comments, pagination, isRefreshing];

  CommentsLoaded copyWith({
    String? discussionId,
    List<DiscussionComment>? comments,
    PaginationInfo? pagination,
    bool? isRefreshing,
  }) {
    return CommentsLoaded(
      discussionId: discussionId ?? this.discussionId,
      comments: comments ?? this.comments,
      pagination: pagination ?? this.pagination,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Error loading comments
class CommentsError extends DiscussionState {
  final String discussionId;
  final String message;

  const CommentsError({
    required this.discussionId,
    required this.message,
  });

  @override
  List<Object?> get props => [discussionId, message];
}

/// Adding a comment
class CommentAdding extends DiscussionState {
  final String discussionId;

  const CommentAdding(this.discussionId);

  @override
  List<Object?> get props => [discussionId];
}

/// Comment added successfully
class CommentAdded extends DiscussionState {
  final DiscussionComment comment;

  const CommentAdded(this.comment);

  @override
  List<Object?> get props => [comment];
}

// ============ Action States ============

/// Like toggle in progress
class LikeToggling extends DiscussionState {
  final String targetId;
  final bool isComment;

  const LikeToggling({
    required this.targetId,
    this.isComment = false,
  });

  @override
  List<Object?> get props => [targetId, isComment];
}

/// Like toggled successfully
class LikeToggled extends DiscussionState {
  final String targetId;
  final bool isLiked;
  final int likesCount;
  final bool isComment;

  const LikeToggled({
    required this.targetId,
    required this.isLiked,
    required this.likesCount,
    this.isComment = false,
  });

  @override
  List<Object?> get props => [targetId, isLiked, likesCount, isComment];
}

/// Deleting in progress
class Deleting extends DiscussionState {
  final String targetId;
  final bool isComment;

  const Deleting({
    required this.targetId,
    this.isComment = false,
  });

  @override
  List<Object?> get props => [targetId, isComment];
}

/// Deleted successfully
class Deleted extends DiscussionState {
  final String targetId;
  final bool isComment;

  const Deleted({
    required this.targetId,
    this.isComment = false,
  });

  @override
  List<Object?> get props => [targetId, isComment];
}

/// Action error (for likes, deletes, etc.)
class ActionError extends DiscussionState {
  final String message;
  final String? targetId;

  const ActionError({
    required this.message,
    this.targetId,
  });

  @override
  List<Object?> get props => [message, targetId];
}

