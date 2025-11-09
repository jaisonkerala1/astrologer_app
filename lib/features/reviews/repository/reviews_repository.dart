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
    print('🔍 [ReviewsRepo] getInstantData() called');
    
    // Track if we found cache data (even if empty)
    bool hasCachedData = false;
    
    // 1. Check in-memory cache first (fastest)
    if (_cachedReviews.isNotEmpty || _cachedStats != null) {
      print('⚡ [ReviewsRepo] Returning ${_cachedReviews.length} reviews from memory cache');
      return {
        'reviews': List<ReviewModel>.from(_cachedReviews),
        'stats': _cachedStats,
        'hasCachedData': true,
      };
    }

    print('🔍 [ReviewsRepo] In-memory cache empty, checking persistent storage...');

    // 2. Try to load from persistent storage (still fast, survives restart)
    try {
      final cachedReviewsData = _storageService.getStringSync('reviews_cache');
      final cachedStatsData = _storageService.getStringSync('reviews_stats_cache');

      print('🔍 [ReviewsRepo] Persistent cache check:');
      print('   - reviews_cache: ${cachedReviewsData != null ? "Found (${cachedReviewsData.length} chars)" : "NULL"}');
      print('   - reviews_stats_cache: ${cachedStatsData != null ? "Found" : "NULL"}');

      // If we found ANY cache data, mark it
      if (cachedReviewsData != null || cachedStatsData != null) {
        hasCachedData = true;
      }

      if (cachedReviewsData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedReviewsData);
        _cachedReviews = jsonList.map((json) => ReviewModel.fromJson(json)).toList();
        print('✅ [ReviewsRepo] Loaded ${_cachedReviews.length} reviews from persistent cache');
      } else {
        print('⚠️ [ReviewsRepo] No reviews in persistent cache');
      }

      if (cachedStatsData != null) {
        final json = jsonDecode(cachedStatsData);
        _cachedStats = RatingStatsModel.fromJson(json);
        print('✅ [ReviewsRepo] Loaded stats from persistent cache');
      } else {
        print('⚠️ [ReviewsRepo] No stats in persistent cache');
      }

      // Return data if we found any cache (even if reviews list is empty!)
      if (hasCachedData) {
        print('✅ [ReviewsRepo] Returning data from persistent cache (survived restart!)');
        print('   Reviews count: ${_cachedReviews.length}, Has stats: ${_cachedStats != null}');
        return {
          'reviews': List<ReviewModel>.from(_cachedReviews),
          'stats': _cachedStats,
          'hasCachedData': true,
        };
      }
    } catch (e) {
      print('❌ [ReviewsRepo] Error loading from persistent cache: $e');
      print('   Stack trace: ${StackTrace.current}');
    }

    print('⚠️ [ReviewsRepo] No cached reviews available - will show loading state');
    return {
      'reviews': <ReviewModel>[],
      'stats': null,
      'hasCachedData': false,
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
      print('💾 [ReviewsRepo] _cacheReviews() called with ${reviews.length} reviews');
      final jsonList = reviews.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      print('💾 [ReviewsRepo] Encoded to JSON string (${jsonString.length} chars)');
      
      final result = await _storageService.setString('reviews_cache', jsonString);
      print('💾 [ReviewsRepo] setString result: $result');
      
      // Verify it was saved
      final verify = await _storageService.getString('reviews_cache');
      if (verify != null) {
        print('✅ [ReviewsRepo] Verified: ${reviews.length} reviews cached to persistent storage');
      } else {
        print('❌ [ReviewsRepo] Verification failed: Cache not saved!');
      }
    } catch (e) {
      print('❌ [ReviewsRepo] Error caching reviews: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _cacheStats(RatingStatsModel stats) async {
    try {
      print('💾 [ReviewsRepo] _cacheStats() called');
      final jsonString = jsonEncode(stats.toJson());
      print('💾 [ReviewsRepo] Encoded stats to JSON');
      
      final result = await _storageService.setString('reviews_stats_cache', jsonString);
      print('💾 [ReviewsRepo] setString result: $result');
      
      // Verify it was saved
      final verify = await _storageService.getString('reviews_stats_cache');
      if (verify != null) {
        print('✅ [ReviewsRepo] Verified: Stats cached to persistent storage');
      } else {
        print('❌ [ReviewsRepo] Verification failed: Stats not saved!');
      }
    } catch (e) {
      print('❌ [ReviewsRepo] Error caching stats: $e');
      print('   Stack trace: ${StackTrace.current}');
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
