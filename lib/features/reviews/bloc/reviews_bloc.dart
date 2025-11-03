import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';
import '../repository/reviews_repository.dart';
import 'reviews_event.dart';
import 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewsRepository _reviewsRepository;

  ReviewsBloc({required ReviewsRepository reviewsRepository})
      : _reviewsRepository = reviewsRepository,
        super(ReviewsInitial()) {
    
    on<LoadReviews>(_onLoadReviews);
    on<LoadRatingStats>(_onLoadRatingStats);
    on<ReplyToReview>(_onReplyToReview);
    on<FilterReviewsChanged>(_onFilterReviewsChanged);
    on<RefreshReviews>(_onRefreshReviews);
  }

  Future<void> _onLoadReviews(LoadReviews event, Emitter<ReviewsState> emit) async {
    // Smart Loading: If data already exists, skip full reload
    if (state is ReviewsLoaded && !event.forceRefresh) {
      print('✅ [ReviewsBloc] Reviews already loaded, skipping API call');
      return;
    }

    try {
      print('🔄 [ReviewsBloc] Loading reviews (two-phase pattern)...');

      // PHASE 1: Instant loading from cache (synchronous)
      try {
        final instantData = _reviewsRepository.getInstantData();
        final cachedReviews = instantData['reviews'] as List<ReviewModel>;
        final cachedStats = instantData['stats'] as RatingStatsModel?;

        if (cachedReviews.isNotEmpty && cachedStats != null) {
          print('⚡ [ReviewsBloc] Phase 1: Emitting ${cachedReviews.length} reviews from cache (isRefreshing: true)');
          emit(ReviewsLoaded(
            reviews: cachedReviews,
            stats: cachedStats,
            currentFilter: event.filterRating,
            currentSort: event.sortBy ?? 'newest',
            showNeedsReplyOnly: event.needsReply ?? false,
            isRefreshing: true,
          ));
        } else {
          print('⚠️ [ReviewsBloc] No instant data available, showing loading state');
          emit(ReviewsLoading());
        }
      } catch (e) {
        print('⚠️ [ReviewsBloc] Error in Phase 1: $e, showing loading state');
        emit(ReviewsLoading());
      }

      // PHASE 2: Background refresh from API
      print('🌐 [ReviewsBloc] Phase 2: Fetching fresh data from API...');
      final reviews = await _reviewsRepository.getReviews(
        filterRating: event.filterRating,
        sortBy: event.sortBy,
        needsReply: event.needsReply,
      );
      
      final stats = await _reviewsRepository.getRatingStats();
      print('✅ [ReviewsBloc] Phase 2: Loaded ${reviews.length} fresh reviews from API');
      
      emit(ReviewsLoaded(
        reviews: reviews,
        stats: stats,
        currentFilter: event.filterRating,
        currentSort: event.sortBy ?? 'newest',
        showNeedsReplyOnly: event.needsReply ?? false,
        isRefreshing: false,
      ));
      print('✅ [ReviewsBloc] Two-phase loading complete!');
    } catch (e) {
      print('❌ [ReviewsBloc] Error loading reviews: $e');
      
      // If we already showed cached data, just hide refresh indicator
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        print('⚠️ [ReviewsBloc] API refresh failed, keeping cached data');
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        // Only show error if no data was shown
        emit(ReviewsError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadRatingStats(LoadRatingStats event, Emitter<ReviewsState> emit) async {
    try {
      final stats = await _reviewsRepository.getRatingStats();
      
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        emit(ReviewsLoaded(
          reviews: currentState.reviews,
          stats: stats,
          currentFilter: currentState.currentFilter,
          currentSort: currentState.currentSort,
          showNeedsReplyOnly: currentState.showNeedsReplyOnly,
        ));
      } else {
        emit(ReviewsLoaded(
          reviews: [],
          stats: stats,
        ));
      }
    } catch (e) {
      emit(ReviewsError(message: e.toString()));
    }
  }

  Future<void> _onReplyToReview(ReplyToReview event, Emitter<ReviewsState> emit) async {
    try {
      await _reviewsRepository.replyToReview(event.reviewId, event.replyText);
      
      emit(ReplySubmitted(
        reviewId: event.reviewId,
        replyText: event.replyText,
      ));
      
      // Reload reviews to get updated data
      add(LoadReviews());
    } catch (e) {
      emit(ReplyError(message: e.toString()));
    }
  }

  Future<void> _onFilterReviewsChanged(FilterReviewsChanged event, Emitter<ReviewsState> emit) async {
    add(LoadReviews(
      filterRating: event.rating,
      sortBy: event.sortBy,
      needsReply: event.needsReply,
    ));
  }

  Future<void> _onRefreshReviews(RefreshReviews event, Emitter<ReviewsState> emit) async {
    add(LoadReviews(forceRefresh: true));
  }
}
