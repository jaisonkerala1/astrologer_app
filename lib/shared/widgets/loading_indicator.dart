import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium loading indicator with sophisticated animations
/// Designed for professional loading states
class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;
  final bool showMessage;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;

  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
    this.message,
    this.showMessage = false,
    this.messageStyle,
    this.padding,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LoadingPainter(
                  progress: _animation.value,
                  color: widget.color ?? AppTheme.primaryColor,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          if (widget.showMessage && widget.message != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: widget.messageStyle ?? TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for sophisticated loading animation
class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingPainter({
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

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Create gradient effect
    final gradient = SweepGradient(
      colors: [
        color.withOpacity(0.3),
        color,
        color.withOpacity(0.8),
        color,
        color.withOpacity(0.3),
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    final startAngle = -90.0 * (3.14159 / 180.0);
    final sweepAngle = 360.0 * progress * (3.14159 / 180.0);
    
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Add pulsing effect
    final pulsePaint = Paint()
      ..color = color.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.3, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _LoadingPainter && oldDelegate.progress != progress;
  }
}

/// Sophisticated loading overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;
  final double? opacity;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.backgroundColor,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? Colors.black).withOpacity(
              opacity ?? 0.3,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LoadingIndicator(
                  size: 32,
                  message: message,
                  showMessage: message != null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Staggered loading animation for lists
class StaggeredLoadingList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration staggerDelay;
  final Duration itemDuration;

  const StaggeredLoadingList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
  });

  @override
  State<StaggeredLoadingList> createState() => _StaggeredLoadingListState();
}

class _StaggeredLoadingListState extends State<StaggeredLoadingList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.itemCount,
      (index) => AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * widget.staggerDelay.inMilliseconds),
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(StaggeredLoadingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _disposeControllers();
      _initializeAnimations();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.itemCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _animations[index].value)),
              child: Opacity(
                opacity: _animations[index].value,
                child: widget.itemBuilder(context, index),
              ),
            );
          },
        );
      }),
    );
  }
}


