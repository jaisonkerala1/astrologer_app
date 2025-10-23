import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated spiral galaxy widget with slow rotation
class SpiralGalaxyWidget extends StatefulWidget {
  final double size;
  final Color color;

  const SpiralGalaxyWidget({
    super.key,
    this.size = 70,
    this.color = const Color(0xFF89F8B4),
  });

  @override
  State<SpiralGalaxyWidget> createState() => _SpiralGalaxyWidgetState();
}

class _SpiralGalaxyWidgetState extends State<SpiralGalaxyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30), // Slow rotation
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: SpiralGalaxyPainter(
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class SpiralGalaxyPainter extends CustomPainter {
  final Color color;

  SpiralGalaxyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2.5;

    // Draw bright core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          color,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: r * 0.25,
      ));
    canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);

    // Draw 2 spiral arms
    final armPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // First spiral arm
    _drawSpiralArm(canvas, cx, cy, r, 0, armPaint);
    
    // Second spiral arm (offset by 180 degrees)
    _drawSpiralArm(canvas, cx, cy, r, math.pi, armPaint);

    // Add some star particles along the arms
    final starPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final t = i / 12;
      final angle = t * math.pi * 1.5;
      final distance = r * 0.3 + (r * 0.5 * t);
      
      // Stars on first arm
      final x1 = cx + math.cos(angle) * distance;
      final y1 = cy + math.sin(angle) * distance;
      canvas.drawCircle(Offset(x1, y1), 1.5, starPaint);
      
      // Stars on second arm
      final x2 = cx + math.cos(angle + math.pi) * distance;
      final y2 = cy + math.sin(angle + math.pi) * distance;
      canvas.drawCircle(Offset(x2, y2), 1.5, starPaint);
    }

    // Add outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), r * 0.9, glowPaint);
  }

  void _drawSpiralArm(Canvas canvas, double cx, double cy, double r, double startAngle, Paint paint) {
    final path = Path();
    
    // Create logarithmic spiral
    const numPoints = 50;
    for (int i = 0; i < numPoints; i++) {
      final t = i / numPoints;
      final angle = startAngle + (t * math.pi * 1.5);
      final distance = r * 0.3 + (r * 0.5 * t);
      
      final x = cx + math.cos(angle) * distance;
      final y = cy + math.sin(angle) * distance;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Draw the arm with varying opacity
    canvas.drawPath(path, paint);
    
    // Add glow to the arm
    final glowPaint = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(SpiralGalaxyPainter oldDelegate) => false;
}

