import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Beautiful skeleton loader for the reviews overview screen
class ReviewsOverviewSkeleton extends StatelessWidget {
  const ReviewsOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return CustomScrollView(
          slivers: [
            // Rating Overview Header Skeleton
            SliverToBoxAdapter(
              child: _buildRatingOverviewCardSkeleton(themeService),
            ),
            
            // Filter Chips Skeleton
            SliverToBoxAdapter(
              child: _buildFilterChipsSkeleton(),
            ),
            
            // Reviews List Skeleton
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReviewItemCardSkeleton(themeService),
                  ),
                  childCount: 5, // Show 5 skeleton review cards
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingOverviewCardSkeleton(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Rating Display Skeleton
              Column(
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 48,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  // Stars skeleton
                  Row(
                    children: List.generate(5, (index) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: SkeletonLoader(
                          width: 20,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 100,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              
              const SizedBox(width: 32),
              
              // Rating Breakdown Skeleton
              Expanded(
                child: Column(
                  children: List.generate(5, (index) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SkeletonLoader(
                            width: 12,
                            height: 12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(width: 4),
                          SkeletonLoader(
                            width: 16,
                            height: 16,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SkeletonLoader(
                              height: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SkeletonLoader(
                            width: 20,
                            height: 12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Unresponded Reviews Alert Skeleton
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SkeletonLoader(
                    width: 200,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Reviews Chip Skeleton
            _buildFilterChipSkeleton(width: 60),
            const SizedBox(width: 8),
            
            // Needs Reply Chip Skeleton
            _buildFilterChipSkeleton(width: 100),
            const SizedBox(width: 8),
            
            // Rating Filter Chips Skeleton
            ...List.generate(5, (index) => 
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChipSkeleton(width: 80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipSkeleton({required double width}) {
    return SkeletonLoader(
      width: width,
      height: 32,
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _buildReviewItemCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Info Row Skeleton
          Row(
            children: [
              SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 120,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Stars skeleton
                        Row(
                          children: List.generate(5, (index) => 
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SkeletonLoader(
                                width: 14,
                                height: 14,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SkeletonLoader(
                          width: 60,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Text Skeleton
          SkeletonText(
            lines: 3,
            height: 14,
            spacing: 8,
          ),
          
          const SizedBox(height: 12),
          
          // Reply Button Skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 36,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for rating overview card only
class RatingOverviewCardSkeleton extends StatelessWidget {
  const RatingOverviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Large Rating Display Skeleton
                  Column(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 48,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 8),
                      // Stars skeleton
                      Row(
                        children: List.generate(5, (index) => 
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: SkeletonLoader(
                              width: 20,
                              height: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SkeletonLoader(
                        width: 100,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Rating Breakdown Skeleton
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SkeletonLoader(
                                width: 12,
                                height: 12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(width: 4),
                              SkeletonLoader(
                                width: 16,
                                height: 16,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SkeletonLoader(
                                  height: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SkeletonLoader(
                                width: 20,
                                height: 12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Unresponded Reviews Alert Skeleton
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    SkeletonLoader(
                      width: 20,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SkeletonLoader(
                        width: 200,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton loader for review item card only
class ReviewItemCardSkeleton extends StatelessWidget {
  const ReviewItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Info Row Skeleton
              Row(
                children: [
                  SkeletonCircle(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: 120,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Stars skeleton
                            Row(
                              children: List.generate(5, (index) => 
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: SkeletonLoader(
                                    width: 14,
                                    height: 14,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SkeletonLoader(
                              width: 60,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Review Text Skeleton
              SkeletonText(
                lines: 3,
                height: 14,
                spacing: 8,
              ),
              
              const SizedBox(height: 12),
              
              // Reply Button Skeleton
              SkeletonLoader(
                width: double.infinity,
                height: 36,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton loader for filter chips only
class FilterChipsSkeleton extends StatelessWidget {
  const FilterChipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Reviews Chip Skeleton
            _buildFilterChipSkeleton(width: 60),
            const SizedBox(width: 8),
            
            // Needs Reply Chip Skeleton
            _buildFilterChipSkeleton(width: 100),
            const SizedBox(width: 8),
            
            // Rating Filter Chips Skeleton
            ...List.generate(5, (index) => 
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChipSkeleton(width: 80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipSkeleton({required double width}) {
    return SkeletonLoader(
      width: width,
      height: 32,
      borderRadius: BorderRadius.circular(20),
    );
  }
}

/// Skeleton loader for reviews list only
class ReviewsListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ReviewsListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReviewItemCardSkeleton(),
          ),
          childCount: itemCount,
        ),
      ),
    );
  }
}
