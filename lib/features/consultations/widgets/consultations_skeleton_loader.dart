import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Skeleton loader for the consultations screen
class ConsultationsSkeletonLoader extends StatelessWidget {
  const ConsultationsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeService.surfaceColor,
            elevation: 0,
            title: SkeletonLoader(
              width: 120,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            actions: [
              SkeletonLoader(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar skeleton
                SkeletonLoader(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                ),
                const SizedBox(height: 20),
                
                // Filter chips skeleton
                Row(
                  children: [
                    SkeletonLoader(
                      width: 80,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(width: 12),
                    SkeletonLoader(
                      width: 100,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(width: 12),
                    SkeletonLoader(
                      width: 90,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Stats cards skeleton
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCardSkeleton(themeService),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCardSkeleton(themeService),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Consultation cards skeleton
                ...List.generate(5, (index) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildConsultationCardSkeleton(themeService),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 60,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 40,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCardSkeleton(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
                    const SizedBox(height: 4),
                    SkeletonLoader(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              SkeletonLoader(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 200,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                width: 100,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              SkeletonLoader(
                width: 80,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
