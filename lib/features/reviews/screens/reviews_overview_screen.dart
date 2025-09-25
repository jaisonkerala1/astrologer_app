import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';
import '../models/review_model.dart';
import '../widgets/rating_overview_card.dart';
import '../widgets/review_item_card.dart';
import '../widgets/rating_filter_chips.dart';
import '../widgets/filter_options_bottom_sheet.dart';
import '../widgets/reply_dialog.dart';
import '../widgets/reviews_skeleton_loader.dart';

class ReviewsOverviewScreen extends StatefulWidget {
  const ReviewsOverviewScreen({super.key});

  @override
  State<ReviewsOverviewScreen> createState() => _ReviewsOverviewScreenState();
}

class _ReviewsOverviewScreenState extends State<ReviewsOverviewScreen> {
  int? selectedRatingFilter;
  bool showNeedsReplyOnly = false;
  String selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    context.read<ReviewsBloc>().add(LoadRatingStats());
    context.read<ReviewsBloc>().add(LoadReviews());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Reviews & Ratings'),
            backgroundColor: themeService.surfaceColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
              ),
            ],
          ),
      body: BlocBuilder<ReviewsBloc, ReviewsState>(
        builder: (context, state) {
          if (state is ReviewsLoading) {
            return const ReviewsOverviewSkeleton();
          }
          
          if (state is ReviewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReviewsBloc>().add(LoadReviews());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is ReviewsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReviewsBloc>().add(LoadReviews());
              },
              child: CustomScrollView(
                slivers: [
                  // Rating Overview Header
                  SliverToBoxAdapter(
                    child: RatingOverviewCard(stats: state.stats),
                  ),
                  
                  // Filter Chips
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: RatingFilterChips(
                        selectedRating: selectedRatingFilter,
                        showNeedsReplyOnly: showNeedsReplyOnly,
                        onRatingSelected: (rating) {
                          setState(() => selectedRatingFilter = rating);
                          context.read<ReviewsBloc>().add(
                            FilterReviewsChanged(rating: rating)
                          );
                        },
                        onNeedsReplyToggle: (needsReply) {
                          setState(() => showNeedsReplyOnly = needsReply);
                          context.read<ReviewsBloc>().add(
                            FilterReviewsChanged(needsReply: needsReply)
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Reviews List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final review = state.reviews[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewItemCard(
                              review: review,
                              onReplyTap: () => _showReplyDialog(review),
                            ),
                          );
                        },
                        childCount: state.reviews.length,
                      ),
                    ),
                  ),
                  
                  // Empty state
                  if (state.reviews.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.reviews_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reviews from your clients will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          
          return const SizedBox();
        },
      ),
        );
      },
    );
  }

  void _showFilterOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterOptionsBottomSheet(
        selectedRating: selectedRatingFilter,
        showNeedsReplyOnly: showNeedsReplyOnly,
        selectedSort: selectedSort,
        onApply: (rating, needsReply, sortBy) {
          setState(() {
            selectedRatingFilter = rating;
            showNeedsReplyOnly = needsReply;
            selectedSort = sortBy;
          });
          context.read<ReviewsBloc>().add(
            FilterReviewsChanged(
              rating: rating,
              needsReply: needsReply,
              sortBy: sortBy,
            )
          );
        },
      ),
    );
  }

  void _showReplyDialog(ReviewModel review) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        review: review,
        onSubmit: (replyText) {
          context.read<ReviewsBloc>().add(
            ReplyToReview(reviewId: review.id, replyText: replyText)
          );
        },
      ),
    );
  }
}

