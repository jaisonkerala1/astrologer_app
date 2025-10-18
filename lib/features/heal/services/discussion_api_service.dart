import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/storage_service.dart';
import '../models/discussion_models.dart';

/// Professional API Service for Discussion Module
/// Handles all HTTP requests to the Railway backend
/// Includes error handling, token management, and response parsing
class DiscussionApiService {
  // Base URL - Railway production server
  static const String _baseUrl = 'https://astrologerapp-production.up.railway.app/api';
  
  final StorageService _storageService = StorageService();

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  /// Get JWT token from storage
  Future<String?> _getToken() async {
    try {
      return await _storageService.getToken();
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  /// Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle API errors and throw user-friendly messages
  void _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'An error occurred');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error. Please check your connection.');
    }
  }

  // ============================================
  // DISCUSSION CRUD OPERATIONS
  // ============================================

  /// Create a new discussion
  Future<DiscussionPost> createDiscussion({
    required String title,
    required String content,
    String? imageUrl,
    List<String>? tags,
    String? category,
    String? visibleTo,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'tags': tags ?? [],
        'category': category ?? 'general',
        'visibleTo': visibleTo ?? 'both',
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/discussions'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DiscussionPost.fromJson(data['data']);
      } else {
        _handleError(response);
        throw Exception('Failed to create discussion');
      }
    } catch (e) {
      print('Error creating discussion: $e');
      rethrow;
    }
  }

  /// Get all discussions with pagination and filters
  Future<Map<String, dynamic>> getDiscussions({
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? category,
    String? tags,
    String? authorId,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: false);
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
        if (authorId != null) 'authorId': authorId,
        if (search != null) 'search': search,
      };

      final uri = Uri.parse('$_baseUrl/discussions').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'discussions': (data['data'] as List)
              .map((json) => DiscussionPost.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        _handleError(response);
        throw Exception('Failed to load discussions');
      }
    } catch (e) {
      print('Error getting discussions: $e');
      rethrow;
    }
  }

  /// Get a single discussion by ID
  Future<DiscussionPost> getDiscussionById(String discussionId) async {
    try {
      final headers = await _getHeaders(requiresAuth: false);
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/discussions/$discussionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiscussionPost.fromJson(data['data']);
      } else {
        _handleError(response);
        throw Exception('Failed to load discussion');
      }
    } catch (e) {
      print('Error getting discussion: $e');
      rethrow;
    }
  }

  /// Update a discussion (author only)
  Future<DiscussionPost> updateDiscussion({
    required String discussionId,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? tags,
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (tags != null) 'tags': tags,
        if (category != null) 'category': category,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/discussions/$discussionId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiscussionPost.fromJson(data['data']);
      } else {
        _handleError(response);
        throw Exception('Failed to update discussion');
      }
    } catch (e) {
      print('Error updating discussion: $e');
      rethrow;
    }
  }

  /// Delete a discussion (author only)
  Future<void> deleteDiscussion(String discussionId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/discussions/$discussionId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      print('Error deleting discussion: $e');
      rethrow;
    }
  }

  /// Get current user's discussions
  Future<Map<String, dynamic>> getMyDiscussions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/discussions/my-posts').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'discussions': (data['data'] as List)
              .map((json) => DiscussionPost.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        _handleError(response);
        throw Exception('Failed to load your discussions');
      }
    } catch (e) {
      print('Error getting my discussions: $e');
      rethrow;
    }
  }

  // ============================================
  // ENGAGEMENT: LIKES
  // ============================================

  /// Toggle like on a discussion
  Future<Map<String, dynamic>> toggleDiscussionLike(String discussionId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // {liked: bool, likeCount: int}
      } else {
        _handleError(response);
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementView(String discussionId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/view'),
      );
    } catch (e) {
      // Silent fail - view count is not critical
      print('Error incrementing view: $e');
    }
  }

  /// Increment share count
  Future<int> incrementShare(String discussionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/share'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['shareCount'];
      }
      return 0;
    } catch (e) {
      print('Error incrementing share: $e');
      return 0;
    }
  }

  // ============================================
  // COMMENTS
  // ============================================

  /// Add a comment to a discussion
  Future<DiscussionComment> addComment({
    required String discussionId,
    required String text,
    String? imageUrl,
    String? parentCommentId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/comments'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DiscussionComment.fromJson(data['data']);
      } else {
        _handleError(response);
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for a discussion
  Future<Map<String, dynamic>> getComments({
    required String discussionId,
    int page = 1,
    int limit = 50,
    String structure = 'nested', // 'flat' or 'nested'
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: false);
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'structure': structure,
      };

      final uri = Uri.parse('$_baseUrl/discussions/$discussionId/comments')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'comments': (data['data'] as List)
              .map((json) => DiscussionComment.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        _handleError(response);
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }

  /// Update a comment
  Future<DiscussionComment> updateComment({
    required String commentId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiscussionComment.fromJson(data['data']);
      } else {
        _handleError(response);
        throw Exception('Failed to update comment');
      }
    } catch (e) {
      print('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Toggle like on a comment
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/comments/$commentId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // {liked: bool, likeCount: int}
      } else {
        _handleError(response);
        throw Exception('Failed to toggle comment like');
      }
    } catch (e) {
      print('Error toggling comment like: $e');
      rethrow;
    }
  }

  // ============================================
  // SAVED POSTS
  // ============================================

  /// Toggle save on a discussion (bookmark)
  Future<Map<String, dynamic>> toggleSave({
    required String discussionId,
    String collection = 'default',
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'collection': collection});

      final response = await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/save'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // {saved: bool, saveCount: int}
      } else {
        _handleError(response);
        throw Exception('Failed to toggle save');
      }
    } catch (e) {
      print('Error toggling save: $e');
      rethrow;
    }
  }

  /// Get user's saved posts
  Future<Map<String, dynamic>> getSavedPosts({
    int page = 1,
    int limit = 20,
    String? collection,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (collection != null) 'collection': collection,
      };

      final uri = Uri.parse('$_baseUrl/discussions/saved')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'savedPosts': (data['data'] as List)
              .map((json) => DiscussionPost.fromJson(json['discussionId']))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        _handleError(response);
        throw Exception('Failed to load saved posts');
      }
    } catch (e) {
      print('Error getting saved posts: $e');
      rethrow;
    }
  }

  // ============================================
  // NOTIFICATION SUBSCRIPTIONS
  // ============================================

  /// Toggle notification subscription for a discussion
  Future<Map<String, dynamic>> toggleSubscription({
    required String discussionId,
    bool? notifyOnAllComments,
    bool? notifyOnReplies,
    bool? notifyOnLikes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        if (notifyOnAllComments != null) 'notifyOnAllComments': notifyOnAllComments,
        if (notifyOnReplies != null) 'notifyOnReplies': notifyOnReplies,
        if (notifyOnLikes != null) 'notifyOnLikes': notifyOnLikes,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/discussions/$discussionId/subscribe'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // {subscribed: bool, subscription: {...}}
      } else {
        _handleError(response);
        throw Exception('Failed to toggle subscription');
      }
    } catch (e) {
      print('Error toggling subscription: $e');
      rethrow;
    }
  }

  // ============================================
  // SEARCH & DISCOVERY
  // ============================================

  /// Search discussions
  Future<Map<String, dynamic>> searchDiscussions({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: false);
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/discussions/search')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'discussions': (data['data'] as List)
              .map((json) => DiscussionPost.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        _handleError(response);
        throw Exception('Failed to search discussions');
      }
    } catch (e) {
      print('Error searching discussions: $e');
      rethrow;
    }
  }

  /// Get trending discussions
  Future<List<DiscussionPost>> getTrendingDiscussions({
    int limit = 20,
    String timeframe = '7d', // '24h', '7d', '30d'
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: false);
      final queryParams = {
        'limit': limit.toString(),
        'timeframe': timeframe,
      };

      final uri = Uri.parse('$_baseUrl/discussions/trending')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => DiscussionPost.fromJson(json))
            .toList();
      } else {
        _handleError(response);
        throw Exception('Failed to load trending discussions');
      }
    } catch (e) {
      print('Error getting trending discussions: $e');
      rethrow;
    }
  }
}

