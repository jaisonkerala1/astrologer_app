import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/socket_service.dart';
import '../models/discussion_models.dart';
import '../services/discussion_api_service.dart';
import 'discussion_event.dart';
import 'discussion_state.dart';

/// BLoC for managing Discussion feature
/// Handles CRUD operations, pagination, and real-time updates
class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  final DiscussionApiService _apiService;
  final SocketService _socketService;

  // Stream subscriptions for real-time updates
  StreamSubscription? _commentSubscription;
  StreamSubscription? _likeSubscription;
  StreamSubscription? _updateSubscription;

  // Cache for discussions and comments
  List<DiscussionPost> _cachedDiscussions = [];
  PaginationInfo? _cachedPagination;
  String? _currentCategory;

  Map<String, List<DiscussionComment>> _commentsCache = {};
  Map<String, PaginationInfo> _commentsPaginationCache = {};

  DiscussionBloc({
    DiscussionApiService? apiService,
    SocketService? socketService,
  })  : _apiService = apiService ?? DiscussionApiService(),
        _socketService = socketService ?? SocketService(),
        super(const DiscussionInitial()) {
    // Register event handlers
    on<LoadDiscussionsEvent>(_onLoadDiscussions);
    on<LoadMoreDiscussionsEvent>(_onLoadMoreDiscussions);
    on<CreateDiscussionEvent>(_onCreateDiscussion);
    on<DeleteDiscussionEvent>(_onDeleteDiscussion);
    on<ToggleDiscussionLikeEvent>(_onToggleDiscussionLike);
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<ToggleCommentLikeEvent>(_onToggleCommentLike);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<CommentReceivedEvent>(_onCommentReceived);
    on<LikeUpdateReceivedEvent>(_onLikeUpdateReceived);
    on<DiscussionUpdateReceivedEvent>(_onDiscussionUpdateReceived);
    on<JoinDiscussionRoomEvent>(_onJoinDiscussionRoom);
    on<LeaveDiscussionRoomEvent>(_onLeaveDiscussionRoom);

    // Setup socket listeners
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new comments
    _commentSubscription = _socketService.discussionCommentStream.listen((data) {
      add(CommentReceivedEvent(data));
    });

    // Listen for like updates
    _likeSubscription = _socketService.discussionLikeStream.listen((data) {
      add(LikeUpdateReceivedEvent(data));
    });
  }

  // ============ Discussion Handlers ============

  Future<void> _onLoadDiscussions(
    LoadDiscussionsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    try {
      // If refreshing or first load, show appropriate state
      if (event.refresh || _cachedDiscussions.isEmpty) {
        if (_cachedDiscussions.isNotEmpty) {
          // Show cached data with refresh indicator
          emit(DiscussionLoaded(
            discussions: _cachedDiscussions,
            pagination: _cachedPagination!,
            selectedCategory: event.category,
            isRefreshing: true,
          ));
        } else {
          emit(const DiscussionLoading());
        }
      }

      _currentCategory = event.category;

      final response = await _apiService.getDiscussions(
        page: event.page,
        category: event.category,
      );

      _cachedDiscussions = response.discussions;
      _cachedPagination = response.pagination;

      emit(DiscussionLoaded(
        discussions: response.discussions,
        pagination: response.pagination,
        selectedCategory: event.category,
        isRefreshing: false,
      ));
    } catch (e) {
      print('❌ [DiscussionBloc] Error loading discussions: $e');
      
      // If we have cached data, show it with error message
      if (_cachedDiscussions.isNotEmpty) {
        emit(DiscussionLoaded(
          discussions: _cachedDiscussions,
          pagination: _cachedPagination!,
          selectedCategory: _currentCategory,
          isRefreshing: false,
        ));
      } else {
        emit(DiscussionError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMoreDiscussions(
    LoadMoreDiscussionsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    if (state is! DiscussionLoaded) return;
    
    final currentState = state as DiscussionLoaded;
    if (!currentState.pagination.hasMore || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.pagination.page + 1;
      final response = await _apiService.getDiscussions(
        page: nextPage,
        category: currentState.selectedCategory,
      );

      final allDiscussions = [...currentState.discussions, ...response.discussions];
      _cachedDiscussions = allDiscussions;
      _cachedPagination = response.pagination;

      emit(DiscussionLoaded(
        discussions: allDiscussions,
        pagination: response.pagination,
        selectedCategory: currentState.selectedCategory,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('❌ [DiscussionBloc] Error loading more: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onCreateDiscussion(
    CreateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(const DiscussionCreating());

    try {
      final discussion = await _apiService.createDiscussion(
        title: event.title,
        content: event.content,
        category: event.category,
        visibility: event.visibility,
      );

      // Add to cache at the beginning
      _cachedDiscussions.insert(0, discussion);

      emit(DiscussionCreated(discussion));

      // Re-emit loaded state with new discussion
      if (_cachedPagination != null) {
        emit(DiscussionLoaded(
          discussions: _cachedDiscussions,
          pagination: _cachedPagination!,
          selectedCategory: _currentCategory,
        ));
      }
    } catch (e) {
      print('❌ [DiscussionBloc] Error creating discussion: $e');
      emit(ActionError(message: e.toString()));
      
      // Re-emit previous state
      if (_cachedDiscussions.isNotEmpty && _cachedPagination != null) {
        emit(DiscussionLoaded(
          discussions: _cachedDiscussions,
          pagination: _cachedPagination!,
          selectedCategory: _currentCategory,
        ));
      }
    }
  }

  Future<void> _onDeleteDiscussion(
    DeleteDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(Deleting(targetId: event.discussionId));

    try {
      await _apiService.deleteDiscussion(event.discussionId);

      // Remove from cache
      _cachedDiscussions.removeWhere((d) => d.id == event.discussionId);

      emit(Deleted(targetId: event.discussionId));

      // Re-emit loaded state without deleted discussion
      if (_cachedPagination != null) {
        emit(DiscussionLoaded(
          discussions: _cachedDiscussions,
          pagination: _cachedPagination!,
          selectedCategory: _currentCategory,
        ));
      }
    } catch (e) {
      print('❌ [DiscussionBloc] Error deleting discussion: $e');
      emit(ActionError(message: e.toString(), targetId: event.discussionId));
    }
  }

  Future<void> _onToggleDiscussionLike(
    ToggleDiscussionLikeEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    // Optimistic update
    final index = _cachedDiscussions.indexWhere((d) => d.id == event.discussionId);
    if (index != -1) {
      final discussion = _cachedDiscussions[index];
      final wasLiked = discussion.isLiked;
      
      // Update cache optimistically
      _cachedDiscussions[index] = discussion.copyWith(
        isLiked: !wasLiked,
        likes: wasLiked ? discussion.likes - 1 : discussion.likes + 1,
      );

      // Emit updated state immediately
      if (_cachedPagination != null) {
        emit(DiscussionLoaded(
          discussions: List.from(_cachedDiscussions),
          pagination: _cachedPagination!,
          selectedCategory: _currentCategory,
        ));
      }

      try {
        // Make API call
        final response = await _apiService.toggleDiscussionLike(event.discussionId);
        
        // Update with server values
        _cachedDiscussions[index] = _cachedDiscussions[index].copyWith(
          isLiked: response.isLiked,
          likes: response.likesCount,
        );

        emit(LikeToggled(
          targetId: event.discussionId,
          isLiked: response.isLiked,
          likesCount: response.likesCount,
        ));
      } catch (e) {
        print('❌ [DiscussionBloc] Error toggling like: $e');
        // Revert optimistic update
        _cachedDiscussions[index] = discussion;
        
        if (_cachedPagination != null) {
          emit(DiscussionLoaded(
            discussions: List.from(_cachedDiscussions),
            pagination: _cachedPagination!,
            selectedCategory: _currentCategory,
          ));
        }
      }
    }
  }

  // ============ Comment Handlers ============

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    try {
      // Check cache first
      if (!event.refresh && _commentsCache.containsKey(event.discussionId)) {
        emit(CommentsLoaded(
          discussionId: event.discussionId,
          comments: _commentsCache[event.discussionId]!,
          pagination: _commentsPaginationCache[event.discussionId]!,
          isRefreshing: true,
        ));
      } else {
        emit(CommentsLoading(event.discussionId));
      }

      final response = await _apiService.getComments(event.discussionId);

      _commentsCache[event.discussionId] = response.comments;
      _commentsPaginationCache[event.discussionId] = response.pagination;

      emit(CommentsLoaded(
        discussionId: event.discussionId,
        comments: response.comments,
        pagination: response.pagination,
        isRefreshing: false,
      ));
    } catch (e) {
      print('❌ [DiscussionBloc] Error loading comments: $e');
      emit(CommentsError(
        discussionId: event.discussionId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(CommentAdding(event.discussionId));

    try {
      final comment = await _apiService.addComment(
        discussionId: event.discussionId,
        content: event.content,
        parentCommentId: event.parentCommentId,
      );

      // Update cache
      final comments = _commentsCache[event.discussionId] ?? [];
      
      if (event.parentCommentId != null) {
        // Add as reply to parent comment
        final parentIndex = comments.indexWhere((c) => c.id == event.parentCommentId);
        if (parentIndex != -1) {
          comments[parentIndex].replies.insert(0, comment);
        }
      } else {
        // Add as top-level comment
        comments.insert(0, comment);
      }
      
      _commentsCache[event.discussionId] = comments;

      // Update discussion comment count
      final discussionIndex = _cachedDiscussions.indexWhere((d) => d.id == event.discussionId);
      if (discussionIndex != -1) {
        _cachedDiscussions[discussionIndex] = _cachedDiscussions[discussionIndex].copyWith(
          commentsCount: _cachedDiscussions[discussionIndex].commentsCount + 1,
        );
      }

      emit(CommentAdded(comment));

      // Re-emit comments loaded state
      final pagination = _commentsPaginationCache[event.discussionId];
      if (pagination != null) {
        emit(CommentsLoaded(
          discussionId: event.discussionId,
          comments: List.from(comments),
          pagination: pagination,
        ));
      }
    } catch (e) {
      print('❌ [DiscussionBloc] Error adding comment: $e');
      emit(ActionError(message: e.toString()));
    }
  }

  Future<void> _onToggleCommentLike(
    ToggleCommentLikeEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    final comments = _commentsCache[event.discussionId];
    if (comments == null) return;

    // Find comment (could be top-level or reply)
    DiscussionComment? targetComment;
    int? parentIndex;
    int? replyIndex;

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == event.commentId) {
        targetComment = comments[i];
        parentIndex = i;
        break;
      }
      for (int j = 0; j < comments[i].replies.length; j++) {
        if (comments[i].replies[j].id == event.commentId) {
          targetComment = comments[i].replies[j];
          parentIndex = i;
          replyIndex = j;
          break;
        }
      }
      if (targetComment != null) break;
    }

    if (targetComment == null) return;

    // Optimistic update
    final wasLiked = targetComment.isLiked;
    final updatedComment = targetComment.copyWith(
      isLiked: !wasLiked,
      likes: wasLiked ? targetComment.likes - 1 : targetComment.likes + 1,
    );

    if (replyIndex != null) {
      comments[parentIndex!].replies[replyIndex] = updatedComment;
    } else {
      comments[parentIndex!] = updatedComment;
    }

    // Emit updated state
    final pagination = _commentsPaginationCache[event.discussionId];
    if (pagination != null) {
      emit(CommentsLoaded(
        discussionId: event.discussionId,
        comments: List.from(comments),
        pagination: pagination,
      ));
    }

    try {
      final response = await _apiService.toggleCommentLike(event.commentId);

      // Update with server values
      final serverUpdatedComment = updatedComment.copyWith(
        isLiked: response.isLiked,
        likes: response.likesCount,
      );

      if (replyIndex != null) {
        comments[parentIndex!].replies[replyIndex] = serverUpdatedComment;
      } else {
        comments[parentIndex!] = serverUpdatedComment;
      }

      emit(LikeToggled(
        targetId: event.commentId,
        isLiked: response.isLiked,
        likesCount: response.likesCount,
        isComment: true,
      ));
    } catch (e) {
      print('❌ [DiscussionBloc] Error toggling comment like: $e');
      // Revert on error
      if (replyIndex != null) {
        comments[parentIndex!].replies[replyIndex] = targetComment;
      } else {
        comments[parentIndex!] = targetComment;
      }

      if (pagination != null) {
        emit(CommentsLoaded(
          discussionId: event.discussionId,
          comments: List.from(comments),
          pagination: pagination,
        ));
      }
    }
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(Deleting(targetId: event.commentId, isComment: true));

    try {
      await _apiService.deleteComment(event.commentId);

      // Remove from cache
      final comments = _commentsCache[event.discussionId];
      if (comments != null) {
        // Check top-level comments
        comments.removeWhere((c) => c.id == event.commentId);
        // Check replies
        for (final comment in comments) {
          comment.replies.removeWhere((r) => r.id == event.commentId);
        }
        _commentsCache[event.discussionId] = comments;
      }

      // Update discussion comment count
      final discussionIndex = _cachedDiscussions.indexWhere((d) => d.id == event.discussionId);
      if (discussionIndex != -1) {
        _cachedDiscussions[discussionIndex] = _cachedDiscussions[discussionIndex].copyWith(
          commentsCount: (_cachedDiscussions[discussionIndex].commentsCount - 1).clamp(0, 999999),
        );
      }

      emit(Deleted(targetId: event.commentId, isComment: true));

      // Re-emit comments
      final pagination = _commentsPaginationCache[event.discussionId];
      if (pagination != null && comments != null) {
        emit(CommentsLoaded(
          discussionId: event.discussionId,
          comments: List.from(comments),
          pagination: pagination,
        ));
      }
    } catch (e) {
      print('❌ [DiscussionBloc] Error deleting comment: $e');
      emit(ActionError(message: e.toString(), targetId: event.commentId));
    }
  }

  // ============ Real-time Event Handlers ============

  Future<void> _onCommentReceived(
    CommentReceivedEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    try {
      final data = event.commentData;
      final discussionId = data['discussionId'] as String?;
      if (discussionId == null) return;

      final comment = DiscussionComment.fromApiJson(data);

      // Update cache
      final comments = _commentsCache[discussionId];
      if (comments != null) {
        final parentCommentId = data['parentCommentId'] as String?;
        
        if (parentCommentId != null) {
          // Add as reply
          final parentIndex = comments.indexWhere((c) => c.id == parentCommentId);
          if (parentIndex != -1) {
            // Check if reply already exists (avoid duplicates)
            if (!comments[parentIndex].replies.any((r) => r.id == comment.id)) {
              comments[parentIndex].replies.insert(0, comment);
            }
          }
        } else {
          // Add as top-level comment (avoid duplicates)
          if (!comments.any((c) => c.id == comment.id)) {
            comments.insert(0, comment);
          }
        }

        _commentsCache[discussionId] = comments;

        // Emit updated state
        final pagination = _commentsPaginationCache[discussionId];
        if (pagination != null) {
          emit(CommentsLoaded(
            discussionId: discussionId,
            comments: List.from(comments),
            pagination: pagination,
          ));
        }
      }

      // Update discussion comment count
      final commentsCount = data['commentsCount'] as int?;
      if (commentsCount != null) {
        final discussionIndex = _cachedDiscussions.indexWhere((d) => d.id == discussionId);
        if (discussionIndex != -1) {
          _cachedDiscussions[discussionIndex] = _cachedDiscussions[discussionIndex].copyWith(
            commentsCount: commentsCount,
          );
        }
      }

      print('📥 [DiscussionBloc] Real-time comment received');
    } catch (e) {
      print('❌ [DiscussionBloc] Error processing real-time comment: $e');
    }
  }

  Future<void> _onLikeUpdateReceived(
    LikeUpdateReceivedEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    try {
      final data = event.likeData;
      final type = data['type'] as String?;
      final likesCount = data['likesCount'] as int?;

      if (likesCount == null) return;

      if (type == 'comment') {
        final commentId = data['commentId'] as String?;
        final discussionId = data['discussionId'] as String?;
        if (commentId == null || discussionId == null) return;

        final comments = _commentsCache[discussionId];
        if (comments != null) {
          // Find and update comment
          for (int i = 0; i < comments.length; i++) {
            if (comments[i].id == commentId) {
              comments[i] = comments[i].copyWith(likes: likesCount);
              break;
            }
            for (int j = 0; j < comments[i].replies.length; j++) {
              if (comments[i].replies[j].id == commentId) {
                comments[i].replies[j] = comments[i].replies[j].copyWith(likes: likesCount);
                break;
              }
            }
          }

          final pagination = _commentsPaginationCache[discussionId];
          if (pagination != null) {
            emit(CommentsLoaded(
              discussionId: discussionId,
              comments: List.from(comments),
              pagination: pagination,
            ));
          }
        }
      } else {
        // Discussion like
        final discussionId = data['discussionId'] as String?;
        if (discussionId == null) return;

        final index = _cachedDiscussions.indexWhere((d) => d.id == discussionId);
        if (index != -1) {
          _cachedDiscussions[index] = _cachedDiscussions[index].copyWith(
            likes: likesCount,
          );

          if (_cachedPagination != null) {
            emit(DiscussionLoaded(
              discussions: List.from(_cachedDiscussions),
              pagination: _cachedPagination!,
              selectedCategory: _currentCategory,
            ));
          }
        }
      }

      print('📥 [DiscussionBloc] Real-time like update received');
    } catch (e) {
      print('❌ [DiscussionBloc] Error processing like update: $e');
    }
  }

  Future<void> _onDiscussionUpdateReceived(
    DiscussionUpdateReceivedEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    try {
      final data = event.updateData;
      final type = data['type'] as String?;

      if (type == 'new_post') {
        // Add new discussion to the list
        final discussion = DiscussionPost.fromApiJson(data['discussion']);
        if (!_cachedDiscussions.any((d) => d.id == discussion.id)) {
          _cachedDiscussions.insert(0, discussion);
          
          if (_cachedPagination != null) {
            emit(DiscussionLoaded(
              discussions: List.from(_cachedDiscussions),
              pagination: _cachedPagination!,
              selectedCategory: _currentCategory,
            ));
          }
        }
      } else if (type == 'comment_added') {
        // Update comment count
        final discussionId = data['discussionId'] as String?;
        final commentsCount = data['commentsCount'] as int?;
        
        if (discussionId != null && commentsCount != null) {
          final index = _cachedDiscussions.indexWhere((d) => d.id == discussionId);
          if (index != -1) {
            _cachedDiscussions[index] = _cachedDiscussions[index].copyWith(
              commentsCount: commentsCount,
            );
            
            if (_cachedPagination != null) {
              emit(DiscussionLoaded(
                discussions: List.from(_cachedDiscussions),
                pagination: _cachedPagination!,
                selectedCategory: _currentCategory,
              ));
            }
          }
        }
      }

      print('📥 [DiscussionBloc] Real-time update received: $type');
    } catch (e) {
      print('❌ [DiscussionBloc] Error processing discussion update: $e');
    }
  }

  // ============ Socket Room Management ============

  Future<void> _onJoinDiscussionRoom(
    JoinDiscussionRoomEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    _socketService.joinDiscussionRoom(event.discussionId);
    print('📥 [DiscussionBloc] Joined discussion room: ${event.discussionId}');
  }

  Future<void> _onLeaveDiscussionRoom(
    LeaveDiscussionRoomEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    _socketService.leaveDiscussionRoom(event.discussionId);
    print('📤 [DiscussionBloc] Left discussion room: ${event.discussionId}');
  }

  @override
  Future<void> close() {
    _commentSubscription?.cancel();
    _likeSubscription?.cancel();
    _updateSubscription?.cancel();
    return super.close();
  }
}

