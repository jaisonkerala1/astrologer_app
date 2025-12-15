import '../../../core/services/api_service.dart';
import '../models/discussion_models.dart';

/// API Service for Discussion feature
/// Handles all HTTP calls to the discussion endpoints
class DiscussionApiService {
  final ApiService _apiService;

  DiscussionApiService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  // ============ Discussions ============

  /// Get all discussions (paginated)
  /// [page] - Page number (1-indexed)
  /// [limit] - Number of items per page
  /// [category] - Optional category filter
  /// [sortBy] - Field to sort by (default: createdAt)
  /// [sortOrder] - asc or desc (default: desc)
  Future<DiscussionListResponse> getDiscussions({
    int page = 1,
    int limit = 20,
    String? category,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiService.get(
        '/api/discussion',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> discussionsJson = response.data['data'] ?? [];
        final discussions = discussionsJson
            .map((json) => DiscussionPost.fromApiJson(json))
            .toList();

        final pagination = response.data['pagination'] != null
            ? PaginationInfo.fromJson(response.data['pagination'])
            : PaginationInfo(page: page, limit: limit, total: discussions.length, pages: 1, hasMore: false);

        return DiscussionListResponse(
          discussions: discussions,
          pagination: pagination,
        );
      }

      throw Exception(response.data['message'] ?? 'Failed to fetch discussions');
    } catch (e) {
      print('Error fetching discussions: $e');
      rethrow;
    }
  }

  /// Get discussions by current user
  Future<DiscussionListResponse> getMyDiscussions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/discussion/my-posts',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data['success'] == true) {
        final List<dynamic> discussionsJson = response.data['data'] ?? [];
        final discussions = discussionsJson
            .map((json) => DiscussionPost.fromApiJson(json))
            .toList();

        final pagination = response.data['pagination'] != null
            ? PaginationInfo.fromJson(response.data['pagination'])
            : PaginationInfo(page: page, limit: limit, total: discussions.length, pages: 1, hasMore: false);

        return DiscussionListResponse(
          discussions: discussions,
          pagination: pagination,
        );
      }

      throw Exception(response.data['message'] ?? 'Failed to fetch your discussions');
    } catch (e) {
      print('Error fetching my discussions: $e');
      rethrow;
    }
  }

  /// Get single discussion by ID
  Future<DiscussionPost> getDiscussion(String id) async {
    try {
      final response = await _apiService.get('/api/discussion/$id');

      if (response.data['success'] == true) {
        return DiscussionPost.fromApiJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Discussion not found');
    } catch (e) {
      print('Error fetching discussion: $e');
      rethrow;
    }
  }

  /// Create new discussion
  Future<DiscussionPost> createDiscussion({
    required String title,
    required String content,
    required String category,
    String visibility = 'public',
    List<String>? tags,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/discussion',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'visibility': visibility,
          if (tags != null) 'tags': tags,
        },
      );

      if (response.data['success'] == true) {
        return DiscussionPost.fromApiJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to create discussion');
    } catch (e) {
      print('Error creating discussion: $e');
      rethrow;
    }
  }

  /// Update discussion
  Future<DiscussionPost> updateDiscussion({
    required String id,
    String? title,
    String? content,
    String? category,
    String? visibility,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (category != null) data['category'] = category;
      if (visibility != null) data['visibility'] = visibility;

      final response = await _apiService.put('/api/discussion/$id', data: data);

      if (response.data['success'] == true) {
        return DiscussionPost.fromApiJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to update discussion');
    } catch (e) {
      print('Error updating discussion: $e');
      rethrow;
    }
  }

  /// Delete discussion (soft delete)
  Future<void> deleteDiscussion(String id) async {
    try {
      final response = await _apiService.delete('/api/discussion/$id');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete discussion');
      }
    } catch (e) {
      print('Error deleting discussion: $e');
      rethrow;
    }
  }

  /// Toggle like on discussion
  Future<LikeResponse> toggleDiscussionLike(String id) async {
    try {
      final response = await _apiService.post('/api/discussion/$id/like');

      if (response.data['success'] == true) {
        return LikeResponse.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to toggle like');
    } catch (e) {
      print('Error toggling discussion like: $e');
      rethrow;
    }
  }

  // ============ Comments ============

  /// Get comments for a discussion
  /// [nested] - If true, returns comments with replies nested (default: true)
  Future<CommentListResponse> getComments(
    String discussionId, {
    int page = 1,
    int limit = 50,
    bool nested = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/discussion/$discussionId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
          'flat': !nested ? 'true' : 'false',
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> commentsJson = response.data['data'] ?? [];
        final comments = commentsJson
            .map((json) => DiscussionComment.fromApiJson(json))
            .toList();

        final pagination = response.data['pagination'] != null
            ? PaginationInfo.fromJson(response.data['pagination'])
            : PaginationInfo(page: page, limit: limit, total: comments.length, pages: 1, hasMore: false);

        return CommentListResponse(
          comments: comments,
          pagination: pagination,
        );
      }

      throw Exception(response.data['message'] ?? 'Failed to fetch comments');
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  /// Add comment to discussion
  Future<DiscussionComment> addComment({
    required String discussionId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/discussion/$discussionId/comments',
        data: {
          'content': content,
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
        },
      );

      if (response.data['success'] == true) {
        return DiscussionComment.fromApiJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to add comment');
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Toggle like on comment
  Future<LikeResponse> toggleCommentLike(String commentId) async {
    try {
      final response = await _apiService.post('/api/discussion/comment/$commentId/like');

      if (response.data['success'] == true) {
        return LikeResponse.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to toggle like');
    } catch (e) {
      print('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiService.delete('/api/discussion/comment/$commentId');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // ============ Categories ============

  /// Get available discussion categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiService.get('/api/discussion/meta/categories');

      if (response.data['success'] == true) {
        final List<dynamic> categories = response.data['data'] ?? [];
        return categories.cast<String>();
      }

      throw Exception(response.data['message'] ?? 'Failed to fetch categories');
    } catch (e) {
      print('Error fetching categories: $e');
      // Return default categories as fallback
      return [
        'Astrology & Horoscopes',
        'Yoga, Meditation & Mindfulness',
        'Healing & Wellness',
        'Spiritual Growth & Practices',
        'Vedic Rituals & Puja',
        'Vastu & Feng Shui',
        'Tarot & Divination',
        'Numerology & Palmistry',
        'Community Support & Life Talk',
        'General Discussion',
      ];
    }
  }
}

// ============ Response Models ============

/// Response wrapper for discussion list with pagination
class DiscussionListResponse {
  final List<DiscussionPost> discussions;
  final PaginationInfo pagination;

  DiscussionListResponse({
    required this.discussions,
    required this.pagination,
  });
}

/// Response wrapper for comment list with pagination
class CommentListResponse {
  final List<DiscussionComment> comments;
  final PaginationInfo pagination;

  CommentListResponse({
    required this.comments,
    required this.pagination,
  });
}

/// Pagination information
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Like toggle response
class LikeResponse {
  final bool isLiked;
  final int likesCount;

  LikeResponse({
    required this.isLiked,
    required this.likesCount,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      isLiked: json['isLiked'] ?? false,
      likesCount: json['likesCount'] ?? 0,
    );
  }
}

