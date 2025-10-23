import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated solar system widget for onboarding screen
/// Features a glowing sun with orbiting planets
class SolarSystemWidget extends StatefulWidget {
  final double size;

  const SolarSystemWidget({
    super.key,
    this.size = 140,
  });

  @override
  State<SolarSystemWidget> createState() => _SolarSystemWidgetState();
}

class _SolarSystemWidgetState extends State<SolarSystemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: SolarSystemPainter(
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class SolarSystemPainter extends CustomPainter {
  final double animationValue;

  SolarSystemPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw background stars
    _drawStars(canvas, size);

    // Draw sun with glow effect
    _drawSun(canvas, centerX, centerY);

    // Draw orbit trajectory circles
    _drawOrbitCircle(canvas, centerX, centerY, 25); // Mercury orbit
    _drawOrbitCircle(canvas, centerX, centerY, 40); // Earth orbit
    _drawOrbitCircle(canvas, centerX, centerY, 55); // Mars orbit

    // Draw orbiting planets
    _drawPlanet(canvas, centerX, centerY, 
      radius: 25, 
      planetSize: 4, 
      color: const Color(0xFF9E9E9E), // Mercury (gray)
      speed: 1.2,
    );

    _drawPlanet(canvas, centerX, centerY, 
      radius: 40, 
      planetSize: 6, 
      color: const Color(0xFF42A5F5), // Earth (blue)
      speed: 0.8,
      hasRing: true,
    );

    _drawPlanet(canvas, centerX, centerY, 
      radius: 55, 
      planetSize: 5, 
      color: const Color(0xFFE57373), // Mars (red-orange)
      speed: 0.5,
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    // Fixed star positions for consistency
    final stars = [
      {'x': 0.15, 'y': 0.2, 'size': 1.0, 'opacity': 0.6},
      {'x': 0.85, 'y': 0.15, 'size': 1.2, 'opacity': 0.8},
      {'x': 0.2, 'y': 0.8, 'size': 0.8, 'opacity': 0.5},
      {'x': 0.9, 'y': 0.7, 'size': 1.0, 'opacity': 0.7},
      {'x': 0.1, 'y': 0.4, 'size': 0.9, 'opacity': 0.6},
      {'x': 0.8, 'y': 0.4, 'size': 1.1, 'opacity': 0.9},
      {'x': 0.3, 'y': 0.15, 'size': 0.8, 'opacity': 0.5},
      {'x': 0.7, 'y': 0.85, 'size': 1.0, 'opacity': 0.7},
      {'x': 0.4, 'y': 0.6, 'size': 0.7, 'opacity': 0.4},
      {'x': 0.6, 'y': 0.3, 'size': 1.2, 'opacity': 0.8},
      {'x': 0.15, 'y': 0.65, 'size': 0.9, 'opacity': 0.6},
      {'x': 0.85, 'y': 0.5, 'size': 0.8, 'opacity': 0.5},
      {'x': 0.25, 'y': 0.35, 'size': 1.0, 'opacity': 0.7},
      {'x': 0.75, 'y': 0.2, 'size': 0.9, 'opacity': 0.6},
      {'x': 0.5, 'y': 0.1, 'size': 1.1, 'opacity': 0.8},
    ];

    for (var star in stars) {
      final x = size.width * (star['x'] as double);
      final y = size.height * (star['y'] as double);
      final starSize = star['size'] as double;
      final opacity = star['opacity'] as double;

      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }

  void _drawSun(Canvas canvas, double centerX, double centerY) {
    final sunRadius = 15.0;

    // Outer glow layers (3 layers for soft glow effect)
    final glowPaint1 = Paint()
      ..color = const Color(0xFFFFF59D).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(centerX, centerY), sunRadius + 12, glowPaint1);

    final glowPaint2 = Paint()
      ..color = const Color(0xFFFFA726).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(centerX, centerY), sunRadius + 6, glowPaint2);

    // Sun core with gradient effect
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF59D), // Light yellow center
          const Color(0xFFFFA726), // Orange outer
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: sunRadius,
      ));

    canvas.drawCircle(Offset(centerX, centerY), sunRadius, sunPaint);

    // Highlight for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(centerX - 4, centerY - 4),
      sunRadius * 0.4,
      highlightPaint,
    );
  }

  void _drawOrbitCircle(Canvas canvas, double centerX, double centerY, double radius) {
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(centerX, centerY), radius, orbitPaint);
  }

  void _drawPlanet(
    Canvas canvas,
    double centerX,
    double centerY, {
    required double radius,
    required double planetSize,
    required Color color,
    required double speed,
    bool hasRing = false,
  }) {
    // Calculate planet position based on animation
    final angle = animationValue * 2 * math.pi * speed;
    final planetX = centerX + radius * math.cos(angle);
    final planetY = centerY + radius * math.sin(angle);

    // Draw planet shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(planetX + 1, planetY + 1),
      planetSize,
      shadowPaint,
    );

    // Draw planet with gradient
    final planetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color,
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(planetX, planetY),
        radius: planetSize,
      ));

    canvas.drawCircle(Offset(planetX, planetY), planetSize, planetPaint);

    // Add ring for Earth
    if (hasRing) {
      final ringPaint = Paint()
        ..color = const Color(0xFF66BB6A).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(planetX, planetY), planetSize + 2, ringPaint);
    }

    // Add highlight for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(
      Offset(planetX - planetSize * 0.3, planetY - planetSize * 0.3),
      planetSize * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(SolarSystemPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

