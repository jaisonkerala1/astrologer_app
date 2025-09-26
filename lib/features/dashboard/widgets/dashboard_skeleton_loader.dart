import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/app_theme.dart';

/// Skeleton loader for the dashboard screen
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section (matches _buildHeader)
              _buildHeaderSkeleton(),
              
              // Live Astrologers Stories Widget skeleton
              _buildLiveAstrologersStoriesSkeleton(),
              
              // Minimal Availability Toggle skeleton
              _buildMinimalAvailabilityToggleSkeleton(),
              
              // Content with padding (matches dashboard padding)
              Padding(
                padding: const EdgeInsets.all(16), // AppConstants.defaultPadding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Card skeleton
                    _buildEarningsCardSkeleton(themeService),
                    const SizedBox(height: 16),
                    
                    // Communication Cards row (Calls Today, Messages Today)
                    _buildCommunicationCardsSkeleton(),
                    const SizedBox(height: 16),
                    
                    // Stats Cards row (Avg Rating, Avg Duration)
                    _buildStatsCardsSkeleton(),
                    const SizedBox(height: 16),
                    
                    // Calendar Card skeleton
                    _buildCalendarCardSkeleton(themeService),
                    const SizedBox(height: 24),
                    
                    // Discussion Card skeleton
                    _buildDiscussionCardSkeleton(themeService),
                    const SizedBox(height: 16),
                    
                    // Test Button skeleton
                    _buildTestButtonSkeleton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSkeleton() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Dynamic gradient based on theme
        LinearGradient headerGradient;
        
        if (themeService.isVedicMode()) {
          // Vedic theme: Saffron gradient
          headerGradient = const LinearGradient(
            colors: [
              Color(0xFFD97706), // Saffron
              Color(0xFFB45309), // Dark saffron
              Color(0xFF92400E), // Brown
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          );
        } else if (themeService.isDarkMode()) {
          // Dark theme: Elegant dark gradient
          headerGradient = LinearGradient(
            colors: [
              themeService.primaryColor.withOpacity(0.9),
              themeService.primaryColor.withOpacity(0.7),
              themeService.backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          );
        } else {
          // Light theme: Original blue gradient
          headerGradient = const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: headerGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: themeService.isVedicMode() 
                    ? const Color(0xFFD97706).withOpacity(0.3) // Saffron shadow
                    : themeService.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            child: Column(
              children: [
                // User info row - matches actual header structure
                Row(
                  children: [
                    // Profile avatar skeleton
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: SkeletonCircle(size: 56),
                    ),
                    const SizedBox(width: 16),
                    // Welcome text and name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 120,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 150,
                            height: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    // Header action buttons
                    Row(
                      children: [
                        // Go Live button skeleton
                        SkeletonLoader(
                          width: 80,
                          height: 32,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(width: 12),
                        // Notifications button skeleton
                        SkeletonLoader(
                          width: 40,
                          height: 40,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveAstrologersStoriesSkeleton() {
    return Container(
      height: 120, // Matches actual LiveAstrologersStoriesWidget height
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Live Now" title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: SkeletonLoader(
              width: 80,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Horizontal scrolling live astrologers
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              itemCount: 8, // Matches actual number of astrologers
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      SkeletonCircle(size: 60),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: 50,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAvailabilityToggleSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status label skeleton
          Row(
            children: [
              SkeletonLoader(
                width: 8,
                height: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 8),
              SkeletonLoader(
                width: 60,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          // Toggle switch skeleton
          SkeletonLoader(
            width: 48,
            height: 26,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.earningsColor, AppTheme.successColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.earningsColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                width: 120,
                height: 18,
                borderRadius: BorderRadius.circular(4),
              ),
              Row(
                children: [
                  SkeletonLoader(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 8),
                  SkeletonLoader(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Today's earnings amount
          SkeletonLoader(
            width: 150,
            height: 32,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          // Total earnings container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonLoader(
                  width: 100,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationCardsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCardSkeleton(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCardSkeleton(),
        ),
      ],
    );
  }

  Widget _buildStatsCardsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCardSkeleton(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCardSkeleton(),
        ),
      ],
    );
  }

  Widget _buildStatsCardSkeleton() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            boxShadow: [themeService.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and trending icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SkeletonLoader(
                      width: 20,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Trending icon
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Value
              SkeletonLoader(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              // Title
              SkeletonLoader(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.1),
            themeService.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SkeletonLoader(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 140,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    SkeletonLoader(
                      width: 100,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              SkeletonLoader(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildCalendarStatItemSkeleton(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCalendarStatItemSkeleton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStatItemSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonLoader(
              width: 16,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 40,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: 30,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDiscussionCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/discussion_icon.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  themeService.textPrimary.withOpacity(0.3),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              SkeletonLoader(
                width: 120,
                height: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Discussion content
          SkeletonText(
            lines: 3,
            height: 14,
            spacing: 8,
          ),
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              SkeletonLoader(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 8),
              SkeletonLoader(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtonSkeleton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: SkeletonLoader(
        height: 48,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

}
