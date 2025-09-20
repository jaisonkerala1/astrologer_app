import '../../../../core/services/api_service.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';

class ReviewsRepository {
  final ApiService _apiService;

  ReviewsRepository({required ApiService apiService}) : _apiService = apiService;

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
          return reviewsJson.map((json) => ReviewModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load reviews');
        }
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading reviews: $e');
    }
  }

  Future<RatingStatsModel> getRatingStats() async {
    try {
      final response = await _apiService.get('/api/reviews/stats');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return RatingStatsModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load rating stats');
        }
      } else {
        throw Exception('Failed to load rating stats: ${response.statusCode}');
      }
    } catch (e) {
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
}
