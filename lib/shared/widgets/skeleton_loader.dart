import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/services/theme_service.dart';

/// A beautiful, minimal theme-compatible skeleton loader widget
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;
  final Curve? curve;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.duration,
    this.curve,
    this.child,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve ?? Curves.easeInOut,
    ));

    // Add a slight delay before starting animation for better visual effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final baseColor = widget.baseColor ?? 
            (themeService.isVedicMode()
                ? const Color(0xFFFED7AA).withOpacity(0.3) // Light saffron for Vedic
                : themeService.isDarkMode() 
                    ? Colors.grey[800]! 
                    : Colors.grey[300]!);
        final highlightColor = widget.highlightColor ?? 
            (themeService.isVedicMode()
                ? const Color(0xFFFED7AA).withOpacity(0.6) // Saffron highlight for Vedic
                : themeService.isDarkMode() 
                    ? Colors.grey[700]! 
                    : Colors.grey[100]!);

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final shimmerWidth = 0.4;
            final shimmerPosition = _animation.value;
            
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
                color: baseColor,
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Base color
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: baseColor,
                    ),
                    // Shimmer effect
                    if (shimmerPosition >= 0.0 && shimmerPosition <= 1.0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                highlightColor.withOpacity(0.6),
                                Colors.transparent,
                              ],
                              stops: [
                                (shimmerPosition - shimmerWidth / 2).clamp(0.0, 1.0),
                                shimmerPosition.clamp(0.0, 1.0),
                                (shimmerPosition + shimmerWidth / 2).clamp(0.0, 1.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Custom child content
                    if (widget.child != null)
                      Positioned.fill(
                        child: widget.child!,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Skeleton loader for text with customizable lines
class SkeletonText extends StatelessWidget {
  final int lines;
  final double? height;
  final double spacing;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    this.lines = 1,
    this.height,
    this.spacing = 8.0,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
          child: SkeletonLoader(
            width: width ?? (index == lines - 1 ? width ?? 200 * (0.7 + (index * 0.1)) : null),
            height: height ?? 16,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for circular elements (like avatars)
class SkeletonCircle extends StatelessWidget {
  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

/// Skeleton loader for cards
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final List<Widget> children;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
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
            children: children,
          ),
        );
      },
    );
  }
}

/// Skeleton loader for stat cards
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      children: [
        // Icon placeholder
        Row(
          children: [
            SkeletonLoader(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        // Value placeholder
        SkeletonLoader(
          width: 60,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        // Label placeholder
        SkeletonLoader(
          width: 80,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Skeleton loader for consultation cards
class SkeletonConsultationCard extends StatelessWidget {
  const SkeletonConsultationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
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
              const SizedBox(height: 16),
              // Details
              SkeletonText(
                lines: 2,
                height: 14,
                spacing: 8,
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 32,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(width: 8),
                  SkeletonLoader(
                    width: 80,
                    height: 32,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton loader for list items
class SkeletonListItem extends StatelessWidget {
  final bool showAvatar;
  final int textLines;

  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.textLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (showAvatar) ...[
            SkeletonCircle(size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SkeletonText(
              lines: textLines,
              height: 14,
              spacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for buttons
class SkeletonButton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonButton({
    super.key,
    this.width,
    this.height = 40,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// Skeleton loader for image placeholders
class SkeletonImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonImage({
    super.key,
    this.width,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// Skeleton loader for table rows
class SkeletonTableRow extends StatelessWidget {
  final int columns;
  final double? height;

  const SkeletonTableRow({
    super.key,
    this.columns = 3,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        columns,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < columns - 1 ? 8 : 0),
            child: SkeletonLoader(
              height: height,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for chart/graph placeholders
class SkeletonChart extends StatelessWidget {
  final double? width;
  final double? height;

  const SkeletonChart({
    super.key,
    this.width,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart title
                SkeletonLoader(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                // Chart area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          5,
                          (index) => SkeletonLoader(
                            width: 20,
                            height: (index + 1) * 20.0,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // X-axis labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) => SkeletonLoader(
                            width: 30,
                            height: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}