import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/app_theme.dart';

/// Premium skeleton loader that perfectly matches the dashboard design
/// Fully theme-aware with support for Light, Dark, and Vedic modes
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
              // Header section - Theme-aware gradient
              _buildHeaderSkeleton(themeService),
              
              // Live Astrologers Stories Widget skeleton
              _buildLiveAstrologersStoriesSkeleton(),
              
              // Minimal Availability Toggle skeleton
              _buildMinimalAvailabilityToggleSkeleton(themeService),
              
              // Content with padding (matches dashboard padding)
              Padding(
                padding: const EdgeInsets.all(16), // AppConstants.defaultPadding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Card skeleton
                    _buildEarningsCardSkeleton(themeService),
                    const SizedBox(height: 16),
                    
                    // Communication Cards - Redesigned with theme support
                    _buildCommunicationCardsSkeleton(themeService),
                    const SizedBox(height: 16),
                    
                    // Calendar Card skeleton
                    _buildCalendarCardSkeleton(themeService),
                    const SizedBox(height: 16),
                    
                    // Stats Cards row (Avg Rating, Avg Duration)
                    _buildStatsCardsSkeleton(themeService),
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


  Widget _buildHeaderSkeleton(ThemeService themeService) {
    // Determine the correct gradient based on theme mode
    final LinearGradient headerGradient;
    
    if (themeService.isVedicMode()) {
      // Vedic theme: Saffron gradient (matching header)
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
      // Light theme: Blue gradient
      headerGradient = LinearGradient(
        colors: [
          themeService.primaryColor.withOpacity(0.9),
          themeService.primaryColor,
        ],
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
                ? const Color(0xFFD97706).withOpacity(0.3)
                : themeService.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
          child: Column(
            children: [
              // User info row - Matches actual header
              Row(
                children: [
                  // Profile avatar skeleton with border
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeService.isVedicMode() 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.3), 
                        width: 2
                      ),
                    ),
                    child: const SkeletonCircle(size: 56),
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
                      // Go Live button skeleton - Red gradient style
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 30,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Notifications button skeleton - Circular
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAstrologersStoriesSkeleton() {
    return Container(
      height: 140, // Matches actual LiveAstrologersStoriesWidget height
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

  Widget _buildMinimalAvailabilityToggleSkeleton(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status label skeleton
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: themeService.isDarkMode() ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
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
      padding: const EdgeInsets.all(20),  // Matches actual padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.earningsColor, AppTheme.successColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),  // Updated to match 20
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
          // Header row with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Today's earnings amount - Large number
          Container(
            width: 150,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
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
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
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

  Widget _buildCommunicationCardsSkeleton(ThemeService themeService) {
    return Column(
      children: [
        // Calls Today Card skeleton - Redesigned to match actual layout
        _buildCallsCardSkeleton(themeService),
        const SizedBox(height: 12),
        // Messages Today Card skeleton - Redesigned to match actual layout
        _buildMessagesCardSkeleton(themeService),
      ],
    );
  }

  // Redesigned Calls Card Skeleton - Matches actual dashboard design exactly
  Widget _buildCallsCardSkeleton(ThemeService themeService) {
    final isVedic = themeService.isVedicMode();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Vedic uses beige, others use surface color
        color: isVedic ? const Color(0xFFFFF3E0) : themeService.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Left side - Icon container (64x64 square with primary color)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isVedic 
                  ? const Color(0xFFF59E0B)  // Saffron yellow for Vedic
                  : themeService.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Middle - Number and label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 36,  // Large number height
                  decoration: BoxDecoration(
                    color: isVedic 
                        ? const Color(0xFFF59E0B).withOpacity(0.2)
                        : themeService.isDarkMode() 
                            ? Colors.grey[700]
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isVedic 
                        ? const Color(0xFFF59E0B).withOpacity(0.2)
                        : themeService.isDarkMode() 
                            ? Colors.grey[700]
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Right side - VS YESTERDAY and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: isVedic 
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : themeService.isDarkMode() 
                          ? Colors.grey[700]
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeService.successColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: themeService.successColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Redesigned Messages Card Skeleton - Matches actual dashboard design exactly
  Widget _buildMessagesCardSkeleton(ThemeService themeService) {
    final isVedic = themeService.isVedicMode();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Vedic uses beige, others use surface color
        color: isVedic ? const Color(0xFFFFF3E0) : themeService.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Left side - Icon container (64x64 square with primary color)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: themeService.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Middle - Number and label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 36,  // Large number height
                  decoration: BoxDecoration(
                    color: isVedic 
                        ? const Color(0xFFF59E0B).withOpacity(0.2)
                        : themeService.isDarkMode() 
                            ? Colors.grey[700]
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 110,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isVedic 
                        ? const Color(0xFFF59E0B).withOpacity(0.2)
                        : themeService.isDarkMode() 
                            ? Colors.grey[700]
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Right side - VS YESTERDAY and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: isVedic 
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : themeService.isDarkMode() 
                          ? Colors.grey[700]
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeService.successColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: themeService.successColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardsSkeleton(ThemeService themeService) {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCardSkeleton(themeService),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCardSkeleton(themeService),
        ),
      ],
    );
  }

  Widget _buildStatsCardSkeleton(ThemeService themeService) {
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
              // Icon container with color background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.isDarkMode() 
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode() 
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Trending icon
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: themeService.successColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Value
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: themeService.isDarkMode() 
                  ? Colors.grey[700]
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: themeService.isDarkMode() 
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeService.primaryColor,
            themeService.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description - 2 lines
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Arrow button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Icon container (80x80)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtonSkeleton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
