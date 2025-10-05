import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Lightweight skeleton loader for consultation list items only
class ConsultationListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ConsultationListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: themeService.borderRadius,
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
                      const SkeletonCircle(size: 40),
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
          },
        );
      },
    );
  }
}

