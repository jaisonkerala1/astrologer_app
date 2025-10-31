import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Instagram-style skeleton loader for service request list
/// Matches the actual service request card structure pixel-perfectly
class ServiceRequestListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ServiceRequestListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: themeService.cardColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (matches the colored header in actual card)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode() 
                          ? Colors.grey[800]!.withOpacity(0.3)
                          : Colors.grey[200]!.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        const SkeletonCircle(size: 40),
                        const SizedBox(width: 12),
                        // Name and phone
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
                        // Status chip
                        SkeletonLoader(
                          width: 70,
                          height: 24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service name and price row
                        Row(
                          children: [
                            SkeletonLoader(
                              width: 16,
                              height: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SkeletonLoader(
                                width: double.infinity,
                                height: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SkeletonLoader(
                              width: 60,
                              height: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Category chip
                        SkeletonLoader(
                          width: 80,
                          height: 20,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(height: 12),
                        
                        // Date & time row
                        Row(
                          children: [
                            SkeletonLoader(
                              width: 14,
                              height: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 6),
                            SkeletonLoader(
                              width: 120,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Time row
                        Row(
                          children: [
                            SkeletonLoader(
                              width: 14,
                              height: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 6),
                            SkeletonLoader(
                              width: 100,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Divider
                        Divider(color: themeService.borderColor, height: 1),
                        const SizedBox(height: 12),
                        
                        // Action buttons row
                        Row(
                          children: [
                            Expanded(
                              child: SkeletonLoader(
                                height: 36,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SkeletonLoader(
                                height: 36,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

