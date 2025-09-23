import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/simple_shimmer.dart';

/// Premium calendar skeleton widget with sophisticated animations
/// Designed to match the exact layout of the real calendar
class CalendarSkeletonWidget extends StatefulWidget {
  final bool showConsultations;
  final bool enabled;

  const CalendarSkeletonWidget({
    super.key,
    this.showConsultations = true,
    this.enabled = true,
  });

  @override
  State<CalendarSkeletonWidget> createState() => _CalendarSkeletonWidgetState();
}

class _CalendarSkeletonWidgetState extends State<CalendarSkeletonWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _fadeController.forward();
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(CalendarSkeletonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _fadeController.forward();
        _shimmerController.repeat();
      } else {
        _fadeController.stop();
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

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
          _buildSkeletonHeader(),
          _buildSkeletonCalendarGrid(),
          if (widget.showConsultations) ...[
            const Divider(height: 1),
            _buildSkeletonConsultations(),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonHeader() {
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
          // Month/Year skeleton
          Expanded(
            child: ShimmerText(
              text: 'December 2024',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              enabled: widget.enabled,
            ),
          ),
          
          // Navigation buttons skeleton
          Row(
            children: [
              _buildSkeletonNavButton(),
              const SizedBox(width: 8),
              _buildSkeletonNavButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonNavButton() {
    return ShimmerContainer(
      width: 36,
      height: 36,
      borderRadius: 8,
      enabled: widget.enabled,
    );
  }

  Widget _buildSkeletonCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day headers skeleton
          _buildSkeletonDayHeaders(),
          const SizedBox(height: 8),
          // Calendar days skeleton
          _buildSkeletonCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildSkeletonDayHeaders() {
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
                enabled: widget.enabled,
              ),
              const SizedBox(height: 2),
              ShimmerText(
                text: 'रवि',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                enabled: widget.enabled,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSkeletonCalendarDays() {
    return Column(
      children: List.generate(6, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (dayIndex) {
              return Expanded(
                child: _buildSkeletonDayCell(weekIndex, dayIndex),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSkeletonDayCell(int weekIndex, int dayIndex) {
    // Create realistic day numbers for skeleton
    final dayNumber = weekIndex * 7 + dayIndex + 1;
    final isVisible = dayNumber >= 1 && dayNumber <= 31;
    
    if (!isVisible) {
      return Container(height: 40);
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.all(2),
      child: SimpleShimmer(
        enabled: widget.enabled,
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
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
                color: Colors.transparent, // Invisible text, just for layout
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonConsultations() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title skeleton
          ShimmerText(
            text: 'Today\'s Consultations',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            enabled: widget.enabled,
          ),
          const SizedBox(height: 12),
          
          // Consultation cards skeleton
          ...List.generate(3, (index) => _buildSkeletonConsultationCard(index)),
        ],
      ),
    );
  }

  Widget _buildSkeletonConsultationCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ShimmerCircle(
            size: 20,
            enabled: widget.enabled,
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
                  enabled: widget.enabled,
                ),
                const SizedBox(height: 8),
                ShimmerContainer(
                  width: 80 + (index * 15).toDouble(),
                  height: 12,
                  borderRadius: 4,
                  enabled: widget.enabled,
                ),
                const SizedBox(height: 4),
                ShimmerContainer(
                  width: 60 + (index * 10).toDouble(),
                  height: 10,
                  borderRadius: 4,
                  enabled: widget.enabled,
                ),
              ],
            ),
          ),
          ShimmerContainer(
            width: 60,
            height: 24,
            borderRadius: 12,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for empty consultation state
class ConsultationEmptySkeleton extends StatelessWidget {
  final bool enabled;

  const ConsultationEmptySkeleton({
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ShimmerCircle(
            size: 48,
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          ShimmerText(
            text: 'No consultations for today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            enabled: enabled,
          ),
          const SizedBox(height: 4),
          ShimmerText(
            text: 'You have no consultations scheduled for today',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            enabled: enabled,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
