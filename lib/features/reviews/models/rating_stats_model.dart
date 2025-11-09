class RatingStatsModel {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown; // {5: 120, 4: 45, 3: 10, 2: 5, 1: 2}
  final int unrespondedCount;

  RatingStatsModel({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.unrespondedCount,
  });

  factory RatingStatsModel.fromJson(Map<String, dynamic> json) {
    // Convert string keys to integer keys for ratingBreakdown
    Map<int, int> ratingBreakdown = {};
    if (json['ratingBreakdown'] != null) {
      final Map<String, dynamic> breakdown = json['ratingBreakdown'];
      breakdown.forEach((key, value) {
        ratingBreakdown[int.parse(key)] = value as int;
      });
    }
    
    return RatingStatsModel(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingBreakdown: ratingBreakdown,
      unrespondedCount: json['unrespondedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert Map<int, int> to Map<String, dynamic> for JSON encoding
    final Map<String, dynamic> ratingBreakdownJson = {};
    ratingBreakdown.forEach((key, value) {
      ratingBreakdownJson[key.toString()] = value;
    });
    
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingBreakdown': ratingBreakdownJson,
      'unrespondedCount': unrespondedCount,
    };
  }

  RatingStatsModel copyWith({
    double? averageRating,
    int? totalReviews,
    Map<int, int>? ratingBreakdown,
    int? unrespondedCount,
  }) {
    return RatingStatsModel(
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      unrespondedCount: unrespondedCount ?? this.unrespondedCount,
    );
  }
}
