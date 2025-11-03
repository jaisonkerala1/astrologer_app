import 'dart:convert';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';

class ReviewsRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  // In-memory cache for instant access
  List<ReviewModel> _cachedReviews = [];
  RatingStatsModel? _cachedStats;

  ReviewsRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // ============================================================================
  // INSTANT DATA (Instagram/WhatsApp-style instant load)
  // ============================================================================

  Map<String, dynamic> getInstantData() {
    // 1. Check in-memory cache first (fastest)
    if (_cachedReviews.isNotEmpty || _cachedStats != null) {
      print('⚡ [ReviewsRepo] Returning ${_cachedReviews.length} reviews from memory cache');
      return {
        'reviews': List<ReviewModel>.from(_cachedReviews),
        'stats': _cachedStats,
      };
    }

    // 2. Try to load from persistent storage (still fast, survives restart)
    try {
      final cachedReviewsData = _storageService.getStringSync('reviews_cache');
      final cachedStatsData = _storageService.getStringSync('reviews_stats_cache');

      if (cachedReviewsData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedReviewsData);
        _cachedReviews = jsonList.map((json) => ReviewModel.fromJson(json)).toList();
        print('⚡ [ReviewsRepo] Loaded ${_cachedReviews.length} reviews from persistent cache');
      }

      if (cachedStatsData != null) {
        final json = jsonDecode(cachedStatsData);
        _cachedStats = RatingStatsModel.fromJson(json);
        print('⚡ [ReviewsRepo] Loaded stats from persistent cache');
      }

      if (_cachedReviews.isNotEmpty || _cachedStats != null) {
        print('⚡ [ReviewsRepo] Data loaded from persistent cache (survived restart!)');
        return {
          'reviews': List<ReviewModel>.from(_cachedReviews),
          'stats': _cachedStats,
        };
      }
    } catch (e) {
      print('⚠️ [ReviewsRepo] Error loading from persistent cache: $e');
    }

    print('ℹ️ [ReviewsRepo] No cached reviews available');
    return {
      'reviews': <ReviewModel>[],
      'stats': null,
    };
  }

  // ============================================================================
  // LOAD REVIEWS (with persistent caching)
  // ============================================================================

  Future<List<ReviewModel>> getReviews({
    int? filterRating,
    String? sortBy,
    bool? needsReply,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (filterRating != null) queryParams['rating'] = filterRating;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (needsReply != null) queryParams['needsReply'] = needsReply;

      final response = await _apiService.get(
        '/api/reviews',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> reviewsJson = data['data'];
          final reviews = reviewsJson.map((json) => ReviewModel.fromJson(json)).toList();
          
          // Cache in memory AND persist to disk
          _cachedReviews = reviews;
          await _cacheReviews(reviews);
          print('💾 [ReviewsRepo] Saved ${reviews.length} reviews to memory + persistent cache');
          
          return reviews;
        } else {
          throw Exception(data['message'] ?? 'Failed to load reviews');
        }
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ [ReviewsRepo] API error: $e');
      // Return cached data if available
      if (_cachedReviews.isNotEmpty) {
        print('✅ [ReviewsRepo] Using ${_cachedReviews.length} cached reviews');
        return List.from(_cachedReviews);
      }
      throw Exception('Error loading reviews: $e');
    }
  }

  Future<RatingStatsModel> getRatingStats() async {
    try {
      final response = await _apiService.get('/api/reviews/stats');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final stats = RatingStatsModel.fromJson(data['data']);
          
          // Cache in memory AND persist to disk
          _cachedStats = stats;
          await _cacheStats(stats);
          print('💾 [ReviewsRepo] Saved stats to memory + persistent cache');
          
          return stats;
        } else {
          throw Exception(data['message'] ?? 'Failed to load rating stats');
        }
      } else {
        throw Exception('Failed to load rating stats: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ [ReviewsRepo] API error: $e');
      // Return cached data if available
      if (_cachedStats != null) {
        print('✅ [ReviewsRepo] Using cached stats');
        return _cachedStats!;
      }
      throw Exception('Error loading rating stats: $e');
    }
  }

  Future<void> replyToReview(String reviewId, String replyText) async {
    try {
      final response = await _apiService.post(
        '/api/reviews/$reviewId/reply',
        data: {'replyText': replyText},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to submit reply');
        }
      } else {
        throw Exception('Failed to submit reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting reply: $e');
    }
  }

  // ============================================================================
  // CACHING HELPERS
  // ============================================================================

  Future<void> _cacheReviews(List<ReviewModel> reviews) async {
    try {
      final jsonList = reviews.map((r) => r.toJson()).toList();
      await _storageService.setString('reviews_cache', jsonEncode(jsonList));
      print('💾 [ReviewsRepo] Cached ${reviews.length} reviews to persistent storage');
    } catch (e) {
      print('⚠️ [ReviewsRepo] Error caching reviews: $e');
    }
  }

  Future<void> _cacheStats(RatingStatsModel stats) async {
    try {
      await _storageService.setString('reviews_stats_cache', jsonEncode(stats.toJson()));
      print('💾 [ReviewsRepo] Cached stats to persistent storage');
    } catch (e) {
      print('⚠️ [ReviewsRepo] Error caching stats: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _storageService.remove('reviews_cache');
      await _storageService.remove('reviews_stats_cache');
      _cachedReviews.clear();
      _cachedStats = null;
      print('🗑️ [ReviewsRepo] Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
