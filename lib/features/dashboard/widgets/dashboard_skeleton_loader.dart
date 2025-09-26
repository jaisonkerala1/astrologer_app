import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

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
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
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
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with status toggle and notifications
                Row(
                  children: [
                    // Status toggle skeleton
                    SkeletonLoader(
                      width: 120,
                      height: 36,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const Spacer(),
                    // Notification button skeleton
                    SkeletonLoader(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Welcome text skeleton
                SkeletonLoader(
                  width: 180,
                  height: 24,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 220,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                
                // Stats row skeleton
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 80,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 60,
                            height: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 80,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 60,
                            height: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
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
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
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
    );
  }

  Widget _buildMinimalAvailabilityToggleSkeleton() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SkeletonLoader(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 12),
              SkeletonLoader(
                width: 120,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              SkeletonLoader(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsCardSkeleton(ThemeService themeService) {
    return SkeletonCard(
      children: [
        // Header with earnings icon and refresh button
        Row(
          children: [
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 12),
            SkeletonLoader(
              width: 100,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            const Spacer(),
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Earnings amounts row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 100,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 100,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommunicationCardsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: SkeletonStatCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SkeletonStatCard(),
        ),
      ],
    );
  }

  Widget _buildStatsCardsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: SkeletonStatCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SkeletonStatCard(),
        ),
      ],
    );
  }

  Widget _buildCalendarCardSkeleton(ThemeService themeService) {
    return SkeletonCard(
      children: [
        // Header with calendar icon
        Row(
          children: [
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 12),
            SkeletonLoader(
              width: 100,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            const Spacer(),
            SkeletonLoader(
              width: 80,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Today's bookings and upcoming bookings
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 40,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 40,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscussionCardSkeleton(ThemeService themeService) {
    return SkeletonCard(
      children: [
        // Header
        Row(
          children: [
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
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
