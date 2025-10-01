import 'package:flutter/material.dart';

/// Performance optimization utilities for smooth 60fps animations
/// Designed to ensure professional performance across all devices
class PerformanceOptimizations {
  /// Optimize animation controller for smooth performance
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
  }) {
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      vsync: vsync,
    );
  }

  /// Create optimized curved animation
  static Animation<double> createOptimizedAnimation({
    required AnimationController controller,
    Curve curve = Curves.easeOutCubic,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Optimize shimmer animation for performance
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Curve shimmerCurve = Curves.easeInOut;
  static const double shimmerWidth = 0.3;

  /// Optimize transition animations for performance
  static const Duration fastTransition = Duration(milliseconds: 200);
  static const Duration mediumTransition = Duration(milliseconds: 300);
  static const Duration slowTransition = Duration(milliseconds: 500);

  /// Performance-optimized curves
  static const Curve fastCurve = Curves.easeOutCubic;
  static const Curve mediumCurve = Curves.easeOutCubic;
  static const Curve slowCurve = Curves.easeOutCubic;

  /// Memory management for animations
  static void disposeController(AnimationController? controller) {
    controller?.dispose();
  }

  /// Optimize widget rebuilds
  static Widget memoizedBuilder({
    required Widget Function(BuildContext context, Animation<double> animation) builder,
    required Animation<double> animation,
    Widget? child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, _) => builder(context, animation),
    );
  }
}

/// Performance-optimized shimmer effect
class OptimizedShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  const OptimizedShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  @override
  State<OptimizedShimmerEffect> createState() => _OptimizedShimmerEffectState();
}

class _OptimizedShimmerEffectState extends State<OptimizedShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceOptimizations.createOptimizedController(
      vsync: this,
      duration: PerformanceOptimizations.shimmerDuration,
    );
    
    _animation = PerformanceOptimizations.createOptimizedAnimation(
      controller: _controller,
      curve: PerformanceOptimizations.shimmerCurve,
      begin: -1.0,
      end: 2.0,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(OptimizedShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    PerformanceOptimizations.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return PerformanceOptimizations.memoizedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, animation) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                (animation.value - PerformanceOptimizations.shimmerWidth).clamp(0.0, 1.0),
                animation.value.clamp(0.0, 1.0),
                (animation.value + PerformanceOptimizations.shimmerWidth).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Performance-optimized loading indicator
class OptimizedLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;
  final bool showMessage;

  const OptimizedLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
    this.message,
    this.showMessage = false,
  });

  @override
  State<OptimizedLoadingIndicator> createState() => _OptimizedLoadingIndicatorState();
}

class _OptimizedLoadingIndicatorState extends State<OptimizedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceOptimizations.createOptimizedController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animation = PerformanceOptimizations.createOptimizedAnimation(
      controller: _controller,
      curve: Curves.easeInOut,
      begin: 0.0,
      end: 1.0,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    PerformanceOptimizations.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PerformanceOptimizations.memoizedBuilder(
          animation: _animation,
          builder: (context, animation) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _OptimizedLoadingPainter(
                progress: animation.value,
                color: widget.color ?? Colors.blue,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Optimized custom painter for loading animation
class _OptimizedLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _OptimizedLoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with optimized rendering
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -90.0 * (3.14159 / 180.0);
    final sweepAngle = 360.0 * progress * (3.14159 / 180.0);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _OptimizedLoadingPainter && 
           (oldDelegate.progress != progress || oldDelegate.color != color);
  }
}
