import 'package:equatable/equatable.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';

abstract class ReviewsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<ReviewModel> reviews;
  final RatingStatsModel stats;
  final int? currentFilter;
  final String currentSort;
  final bool showNeedsReplyOnly;
  final bool isRefreshing; // Instagram/WhatsApp-style background refresh
  
  ReviewsLoaded({
    required this.reviews,
    required this.stats,
    this.currentFilter,
    this.currentSort = 'newest',
    this.showNeedsReplyOnly = false,
    this.isRefreshing = false,
  });
  
  @override
  List<Object?> get props => [reviews, stats, currentFilter, currentSort, showNeedsReplyOnly, isRefreshing];

  ReviewsLoaded copyWith({
    List<ReviewModel>? reviews,
    RatingStatsModel? stats,
    int? currentFilter,
    String? currentSort,
    bool? showNeedsReplyOnly,
    bool? isRefreshing,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      stats: stats ?? this.stats,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
      showNeedsReplyOnly: showNeedsReplyOnly ?? this.showNeedsReplyOnly,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class ReviewsError extends ReviewsState {
  final String message;
  
  ReviewsError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class ReplySubmitted extends ReviewsState {
  final String reviewId;
  final String replyText;
  
  ReplySubmitted({required this.reviewId, required this.replyText});
  
  @override
  List<Object?> get props => [reviewId, replyText];
}

class ReplyError extends ReviewsState {
  final String message;
  
  ReplyError({required this.message});
  
  @override
  List<Object?> get props => [message];
}
