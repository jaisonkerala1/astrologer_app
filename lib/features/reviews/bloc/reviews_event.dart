import 'package:equatable/equatable.dart';

abstract class ReviewsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadReviews extends ReviewsEvent {
  final int? filterRating;
  final String? sortBy; // 'newest', 'oldest', 'rating_high', 'rating_low'
  final bool? needsReply;
  final bool forceRefresh;
  
  LoadReviews({
    this.filterRating,
    this.sortBy,
    this.needsReply,
    this.forceRefresh = false,
  });
  
  @override
  List<Object?> get props => [filterRating, sortBy, needsReply, forceRefresh];
}

class LoadRatingStats extends ReviewsEvent {}

class ReplyToReview extends ReviewsEvent {
  final String reviewId;
  final String replyText;
  
  ReplyToReview({required this.reviewId, required this.replyText});
  
  @override
  List<Object?> get props => [reviewId, replyText];
}

class FilterReviewsChanged extends ReviewsEvent {
  final int? rating;
  final bool? needsReply;
  final String? sortBy;
  
  FilterReviewsChanged({this.rating, this.needsReply, this.sortBy});
  
  @override
  List<Object?> get props => [rating, needsReply, sortBy];
}

class RefreshReviews extends ReviewsEvent {}
