import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/simple_shimmer.dart';

/// Simple calendar skeleton widget
class SimpleCalendarSkeleton extends StatelessWidget {
  final bool showConsultations;
  final bool enabled;

  const SimpleCalendarSkeleton({
    super.key,
    this.showConsultations = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCalendarGrid(),
          if (showConsultations) ...[
            const Divider(height: 1),
            _buildConsultations(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShimmerText(
              text: 'December 2024',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              enabled: enabled,
            ),
          ),
          Row(
            children: [
              ShimmerContainer(
                width: 36,
                height: 36,
                borderRadius: 8,
                enabled: enabled,
              ),
              const SizedBox(width: 8),
              ShimmerContainer(
                width: 36,
                height: 36,
                borderRadius: 8,
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDayHeaders(),
          const SizedBox(height: 8),
          _buildCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Column(
            children: [
              ShimmerText(
                text: 'S',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                enabled: enabled,
              ),
              const SizedBox(height: 2),
              ShimmerText(
                text: 'रवि',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                enabled: enabled,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCalendarDays() {
    return Column(
      children: List.generate(6, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (dayIndex) {
              return Expanded(
                child: _buildDayCell(weekIndex, dayIndex),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(int weekIndex, int dayIndex) {
    final dayNumber = weekIndex * 7 + dayIndex + 1;
    final isVisible = dayNumber >= 1 && dayNumber <= 31;
    
    if (!isVisible) {
      return Container(height: 40);
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.all(2),
      child: SimpleShimmer(
        enabled: enabled,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              dayNumber.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsultations() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerText(
            text: 'Today\'s Consultations',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) => _buildConsultationCard(index)),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ShimmerCircle(
            size: 20,
            enabled: enabled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: 120 + (index * 20).toDouble(),
                  height: 16,
                  borderRadius: 4,
                  enabled: enabled,
                ),
                const SizedBox(height: 8),
                ShimmerContainer(
                  width: 80 + (index * 15).toDouble(),
                  height: 12,
                  borderRadius: 4,
                  enabled: enabled,
                ),
                const SizedBox(height: 4),
                ShimmerContainer(
                  width: 60 + (index * 10).toDouble(),
                  height: 10,
                  borderRadius: 4,
                  enabled: enabled,
                ),
              ],
            ),
          ),
          ShimmerContainer(
            width: 60,
            height: 24,
            borderRadius: 12,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
