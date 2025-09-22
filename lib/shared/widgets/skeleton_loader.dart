import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.duration,
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Pre-built skeleton components for common UI elements
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final List<Widget>? children;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 120,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: children != null
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children!,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                SkeletonLoader(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 80,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
    );
  }
}

class SkeletonProfilePicture extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;

  const SkeletonProfilePicture({
    super.key,
    this.radius = 30,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
      baseColor: backgroundColor ?? Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }
}

class SkeletonButton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonButton({
    super.key,
    this.width,
    this.height = 48,
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

class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final double? height;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonProfilePicture(radius: 20),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonText(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                SkeletonText(width: 120, height: 14),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            SkeletonLoader(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }
}

// Dashboard specific skeleton components
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          _buildHeaderSkeleton(),
          
          // Content with padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earnings card skeleton
                SkeletonCard(
                  width: double.infinity,
                  height: 110,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonText(width: 100, height: 16),
                        SkeletonLoader(
                          width: 60,
                          height: 20,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SkeletonText(width: 80, height: 20),
                    const SizedBox(height: 6),
                    SkeletonText(width: 120, height: 14),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stats cards skeleton
                Row(
                  children: [
                    Expanded(
                      child: SkeletonCard(
                        height: 90,
                        children: [
                          SkeletonLoader(
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          SkeletonText(width: double.infinity, height: 14),
                          const SizedBox(height: 4),
                          SkeletonText(width: 60, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SkeletonCard(
                        height: 90,
                        children: [
                          SkeletonLoader(
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          SkeletonText(width: double.infinity, height: 14),
                          const SizedBox(height: 4),
                          SkeletonText(width: 60, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: SkeletonCard(
                        height: 90,
                        children: [
                          SkeletonLoader(
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          SkeletonText(width: double.infinity, height: 14),
                          const SizedBox(height: 4),
                          SkeletonText(width: 60, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SkeletonCard(
                        height: 90,
                        children: [
                          SkeletonLoader(
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          SkeletonText(width: double.infinity, height: 14),
                          const SizedBox(height: 4),
                          SkeletonText(width: 60, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Calendar card skeleton
                SkeletonCard(
                  width: double.infinity,
                  height: 130,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonText(width: 100, height: 16),
                        SkeletonLoader(
                          width: 24,
                          height: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SkeletonLoader(
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonText(width: double.infinity, height: 14),
                              const SizedBox(height: 6),
                              SkeletonText(width: 120, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Discussion card skeleton
                SkeletonCard(
                  width: double.infinity,
                  height: 110,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonText(width: 100, height: 16),
                              const SizedBox(height: 6),
                              SkeletonText(width: 200, height: 12),
                              const SizedBox(height: 12),
                              SkeletonLoader(
                                width: 36,
                                height: 36,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        SkeletonLoader(
                          width: 70,
                          height: 70,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Test button skeleton
                SkeletonButton(
                  width: double.infinity,
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          children: [
            // User info row
            Row(
              children: [
                SkeletonProfilePicture(radius: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      SkeletonText(
                        width: 150,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                // Header action buttons
                Row(
                  children: [
                    SkeletonLoader(
                      width: 80,
                      height: 32,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(width: 12),
                    SkeletonLoader(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Status card skeleton
            SkeletonLoader(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(20),
              baseColor: Colors.white.withOpacity(0.15),
              highlightColor: Colors.white.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }
}
