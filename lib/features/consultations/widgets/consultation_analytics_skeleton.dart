import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Beautiful skeleton loader for consultation analytics widget
class ConsultationAnalyticsSkeleton extends StatelessWidget {
  final String period;

  const ConsultationAnalyticsSkeleton({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              _buildHeaderSkeleton(themeService),
              const SizedBox(height: 24),
              
              // Main Stats Row skeleton
              _buildMainStatsRowSkeleton(themeService),
              const SizedBox(height: 16),
              
              // Status Breakdown Row skeleton
              _buildStatusBreakdownRowSkeleton(themeService),
              const SizedBox(height: 24),
              
              // Period Summary Card skeleton
              _buildPeriodSummaryCardSkeleton(themeService),
              const SizedBox(height: 24),
              
              // Consultations List Section skeleton
              _buildConsultationsSectionSkeleton(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSkeleton(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        SkeletonLoader(
          width: _getTitleWidth(),
          height: 24,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 4),
        // Subtitle skeleton
        SkeletonLoader(
          width: _getSubtitleWidth(),
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMainStatsRowSkeleton(ThemeService themeService) {
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

  Widget _buildStatusBreakdownRowSkeleton(ThemeService themeService) {
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

  Widget _buildPeriodSummaryCardSkeleton(ThemeService themeService) {
    return SkeletonCard(
      children: [
        // Header with icon
        Row(
          children: [
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 12),
            SkeletonLoader(
              width: 80,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Summary rows
        ...List.generate(3, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSummaryRowSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SkeletonLoader(
          width: 120,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        SkeletonLoader(
          width: 60,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildConsultationsSectionSkeleton(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            SkeletonLoader(
              width: 20,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 120,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 24,
              height: 20,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Consultations List skeleton
        _buildConsultationsListSkeleton(),
      ],
    );
  }

  Widget _buildConsultationsListSkeleton() {
    return Column(
      children: List.generate(
        _getConsultationCount(),
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonConsultationCard(),
        ),
      ),
    );
  }

  double _getTitleWidth() {
    switch (period) {
      case 'week':
        return 100;
      case 'month':
        return 110;
      case 'all':
        return 80;
      default:
        return 120;
    }
  }

  double _getSubtitleWidth() {
    switch (period) {
      case 'week':
        return 250;
      case 'month':
        return 280;
      case 'all':
        return 200;
      default:
        return 220;
    }
  }

  int _getConsultationCount() {
    // Return different numbers of skeleton cards based on period
    switch (period) {
      case 'week':
        return 3; // Fewer consultations in a week
      case 'month':
        return 5; // More consultations in a month
      case 'all':
        return 4; // Moderate number for all time
      default:
        return 3;
    }
  }
}

/// Specialized skeleton loader for weekly analytics
class WeeklyAnalyticsSkeleton extends StatelessWidget {
  const WeeklyAnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConsultationAnalyticsSkeleton(period: 'week');
  }
}

/// Specialized skeleton loader for monthly analytics
class MonthlyAnalyticsSkeleton extends StatelessWidget {
  const MonthlyAnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConsultationAnalyticsSkeleton(period: 'month');
  }
}

/// Specialized skeleton loader for all-time analytics
class AllTimeAnalyticsSkeleton extends StatelessWidget {
  const AllTimeAnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConsultationAnalyticsSkeleton(period: 'all');
  }
}

/// Skeleton loader for the entire analytics screen with tabs
class ConsultationAnalyticsScreenSkeleton extends StatelessWidget {
  final int activeTabIndex;

  const ConsultationAnalyticsScreenSkeleton({
    super.key,
    this.activeTabIndex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Consultation Analytics'),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'All Time'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              const WeeklyAnalyticsSkeleton(),
              const MonthlyAnalyticsSkeleton(),
              const AllTimeAnalyticsSkeleton(),
            ],
          ),
        );
      },
    );
  }
}

