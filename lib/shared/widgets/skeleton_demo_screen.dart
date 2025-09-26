import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/services/theme_service.dart';
import 'skeleton_loader.dart';

/// Demo screen to showcase all skeleton loader components
class SkeletonDemoScreen extends StatefulWidget {
  const SkeletonDemoScreen({super.key});

  @override
  State<SkeletonDemoScreen> createState() => _SkeletonDemoScreenState();
}

class _SkeletonDemoScreenState extends State<SkeletonDemoScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading for demo purposes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Skeleton Loader Demo'),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isLoading ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _isLoading = !_isLoading;
                  });
                },
              ),
            ],
          ),
          body: _isLoading ? _buildSkeletonContent() : _buildRealContent(themeService),
        );
      },
    );
  }

  Widget _buildSkeletonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          _buildSectionTitle('Header Skeleton'),
          SkeletonLoader(
            width: 200,
            height: 24,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 4),
          SkeletonLoader(
            width: 280,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 24),
          
          // Text skeleton
          _buildSectionTitle('Text Skeleton'),
          SkeletonText(
            lines: 3,
            height: 16,
            spacing: 8,
          ),
          
          const SizedBox(height: 24),
          
          // Stat cards skeleton
          _buildSectionTitle('Stat Cards Skeleton'),
          Row(
            children: [
              Expanded(child: SkeletonStatCard()),
              const SizedBox(width: 16),
              Expanded(child: SkeletonStatCard()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Card skeleton
          _buildSectionTitle('Card Skeleton'),
          SkeletonCard(
            children: [
              Row(
                children: [
                  SkeletonCircle(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SkeletonText(lines: 2, height: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SkeletonText(lines: 2, height: 14),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // List items skeleton
          _buildSectionTitle('List Items Skeleton'),
          ...List.generate(3, (index) => const SkeletonListItem()),
          
          const SizedBox(height: 24),
          
          // Consultation card skeleton
          _buildSectionTitle('Consultation Card Skeleton'),
          const SkeletonConsultationCard(),
          
          const SizedBox(height: 24),
          
          // Mixed content skeleton
          _buildSectionTitle('Mixed Content Skeleton'),
          Column(
            children: [
              SkeletonLoader(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SkeletonLoader(
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SkeletonLoader(
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRealContent(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Skeleton Loader Components',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Beautiful, minimal theme-compatible loading animations',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Text content
          Text(
            'Skeleton loaders provide a better user experience by showing the structure of content while it loads. They are theme-aware and automatically adapt to light and dark modes.',
            style: TextStyle(
              fontSize: 16,
              color: themeService.textPrimary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stat cards
          Row(
            children: [
              Expanded(
                child: _buildRealStatCard(
                  'Total Views',
                  '1,234',
                  Icons.visibility,
                  themeService.primaryColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRealStatCard(
                  'Earnings',
                  '₹12,345',
                  Icons.currency_rupee,
                  themeService.successColor,
                  themeService,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Card
          Container(
            width: double.infinity,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: themeService.primaryColor,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: themeService.textPrimary,
                            ),
                          ),
                          Text(
                            'Astrology Consultant',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeService.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'This is a real content card showing how the skeleton loaders match the actual layout and styling of your app.',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeService themeService,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
