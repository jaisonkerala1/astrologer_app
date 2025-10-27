import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';

/// Beautiful skeleton loader for Edit Profile Screen
/// Matches the exact layout structure with smooth shimmer animation
class EditProfileScreenSkeleton extends StatefulWidget {
  const EditProfileScreenSkeleton({super.key});

  @override
  State<EditProfileScreenSkeleton> createState() => _EditProfileScreenSkeletonState();
}

class _EditProfileScreenSkeletonState extends State<EditProfileScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildShimmer(
              width: 50,
              height: 32,
              borderRadius: 8,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            _buildProfilePhotoSkeleton(),
            const SizedBox(height: 32),

            // Personal Information Section
            _buildSectionTitleSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 32),

            // Professional Information Section
            _buildSectionTitleSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 32),

            // Bio Section
            _buildSectionTitleSkeleton(),
            const SizedBox(height: 16),
            _buildLargeTextFieldSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 16),
            _buildTextFieldSkeleton(),
            const SizedBox(height: 32),

            // Specializations Section
            _buildSectionTitleSkeleton(),
            const SizedBox(height: 16),
            _buildChipsSkeleton(),
            const SizedBox(height: 32),

            // Languages Section
            _buildSectionTitleSkeleton(),
            const SizedBox(height: 16),
            _buildChipsSkeleton(),
            const SizedBox(height: 32),

            // Save Button
            _buildButtonSkeleton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSkeleton() {
    return Center(
      child: Column(
        children: [
          _buildShimmer(
            width: 120,
            height: 120,
            borderRadius: 60, // Circular
            isCircle: true,
          ),
          const SizedBox(height: 16),
          _buildShimmer(
            width: 140,
            height: 14,
            borderRadius: 7,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleSkeleton() {
    return _buildShimmer(
      width: 180,
      height: 24,
      borderRadius: 6,
    );
  }

  Widget _buildTextFieldSkeleton() {
    return _buildShimmer(
      width: double.infinity,
      height: 56,
      borderRadius: 12,
    );
  }

  Widget _buildLargeTextFieldSkeleton() {
    return _buildShimmer(
      width: double.infinity,
      height: 120,
      borderRadius: 12,
    );
  }

  Widget _buildChipsSkeleton() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(6, (index) {
        final widths = [100.0, 120.0, 90.0, 110.0, 95.0, 105.0];
        return _buildShimmer(
          width: widths[index % widths.length],
          height: 40,
          borderRadius: 20,
        );
      }),
    );
  }

  Widget _buildButtonSkeleton() {
    return _buildShimmer(
      width: double.infinity,
      height: 56,
      borderRadius: 12,
    );
  }

  /// Simple shimmer effect using AnimatedBuilder
  Widget _buildShimmer({
    required double width,
    required double height,
    required double borderRadius,
    bool isCircle = false,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0),
              end: Alignment(1.0 - _controller.value * 2, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}

