import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/value_shimmer.dart';

/// Compact Rating Card with touch effects
class AnalyticsRatingCard extends StatefulWidget {
  final double averageRating;
  final int totalReviews;
  final VoidCallback? onTap;
  final bool isLoading;

  const AnalyticsRatingCard({
    super.key,
    required this.averageRating,
    this.totalReviews = 0,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<AnalyticsRatingCard> createState() => _AnalyticsRatingCardState();
}

class _AnalyticsRatingCardState extends State<AnalyticsRatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Colors
  static const Color _starColor = Color(0xFFF59E0B); // Amber

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? _starColor.withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? _starColor.withOpacity(0.2)
                        : (isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.12)),
                    blurRadius: _isPressed ? 20 : 16,
                    offset: const Offset(0, 6),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: _starColor.withOpacity(0.15),
                  highlightColor: _starColor.withOpacity(0.08),
                  hoverColor: _starColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title with subtle icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rating',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.textColor,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isPressed
                                    ? _starColor.withOpacity(0.2)
                                    : _starColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: _starColor,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),

                        // Rating with star
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            widget.isLoading
                                ? const ValueShimmer(width: 50, height: 36, borderRadius: 6)
                                : Text(
                                    widget.averageRating.toStringAsFixed(1),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.textColor,
                                      letterSpacing: -1,
                                      height: 1,
                                    ),
                                  ),
                            const SizedBox(width: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.star_rounded,
                                color: _starColor,
                                size: _isPressed ? 26 : 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Average',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
