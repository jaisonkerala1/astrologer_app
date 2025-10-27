import 'package:flutter/material.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';

/// Beautiful skeleton loader for Profile Screen
/// Matches exact structure and theme of the actual profile screen
class ProfileScreenSkeleton extends StatefulWidget {
  final ThemeService themeService;
  
  const ProfileScreenSkeleton({
    super.key,
    required this.themeService,
  });

  @override
  State<ProfileScreenSkeleton> createState() => _ProfileScreenSkeletonState();
}

class _ProfileScreenSkeletonState extends State<ProfileScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.themeService.primaryColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Skeleton
            _buildProfileHeaderSkeleton(),
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Stats Skeleton
                  _buildStatsRowSkeleton(),
                  const SizedBox(height: 24),
                  
                  // Earnings Card Skeleton
                  _buildEarningsCardSkeleton(),
                  const SizedBox(height: 24),
                  
                  // Personal Information Section
                  _buildSectionSkeleton(
                    'Personal Information',
                    itemCount: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  // Professional Details Section
                  _buildSectionSkeleton(
                    'Professional Details',
                    itemCount: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSectionSkeleton(
                    'Settings',
                    itemCount: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  // Support Section
                  _buildSectionSkeleton(
                    'Support',
                    itemCount: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons Skeleton
                  _buildActionButtonsSkeleton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.themeService.cardColor,
        border: Border.all(color: widget.themeService.borderColor, width: 1),
      ),
      child: Column(
        children: [
          // Avatar Skeleton
          _buildShimmer(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name Skeleton
          _buildShimmer(
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Email Skeleton
          _buildShimmer(
            child: Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Status Badge Skeleton
          _buildShimmer(
            child: Container(
              width: 80,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRowSkeleton() {
    return Row(
      children: [
        Expanded(
          child: _buildShimmer(
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildShimmer(
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCardSkeleton() {
    return _buildShimmer(
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionSkeleton(String title, {required int itemCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        _buildShimmer(
          child: Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Section Items
        Container(
          decoration: BoxDecoration(
            color: widget.themeService.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.themeService.borderColor, width: 1),
          ),
          child: Column(
            children: List.generate(
              itemCount,
              (index) => Column(
                children: [
                  if (index > 0) Divider(height: 1, color: widget.themeService.borderColor),
                  _buildInfoTileSkeleton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTileSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Icon Skeleton
          _buildShimmer(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Text Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(
                  child: Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildShimmer(
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildShimmer(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShimmer(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildShimmer(
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildShimmer(
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.themeService.borderColor.withOpacity(0.1),
                widget.themeService.borderColor.withOpacity(0.3),
                widget.themeService.borderColor.withOpacity(0.1),
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

