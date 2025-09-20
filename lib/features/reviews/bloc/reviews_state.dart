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
  
  ReviewsLoaded({
    required this.reviews,
    required this.stats,
    this.currentFilter,
    this.currentSort = 'newest',
    this.showNeedsReplyOnly = false,
  });
  
  @override
  List<Object?> get props => [reviews, stats, currentFilter, currentSort, showNeedsReplyOnly];
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
