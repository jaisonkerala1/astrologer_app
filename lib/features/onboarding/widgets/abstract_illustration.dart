import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'solar_system_widget.dart';
import 'spiral_galaxy_widget.dart';

/// Abstract playful illustration with organic shapes and device mockup
/// Based on Android's onboarding design with floating decorative elements
class AbstractIllustration extends StatelessWidget {
  const AbstractIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final illustrationHeight = math.min(screenHeight * 0.5, 400.0);

    return SizedBox(
      height: illustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative shapes - Astrology themed
          // Shape 1: Saturn (Yellow, large)
          Positioned(
            left: 20,
            top: 60,
            child: _buildFloatingShape(
              color: const Color(0xFFF8DC89), // Yellow
              size: 120,
              type: ShapeType.zodiacWheel,
            ),
          ),
          // Shape 2: Star (Pink)
          Positioned(
            left: 40,
            top: 10,
            child: _buildFloatingShape(
              color: const Color(0xFFF8A5A5), // Pink
              size: 80,
              type: ShapeType.crystal,
            ),
          ),
          // Shape 3: Constellation (Blue, small)
          Positioned(
            right: 30,
            top: 40,
            child: _buildFloatingShape(
              color: const Color(0xFF4DA6FF), // Blue
              size: 50,
              type: ShapeType.constellation,
            ),
          ),
          // Shape 4: Shooting Star (Blue)
          Positioned(
            right: 60,
            top: 120,
            child: _buildFloatingShape(
              color: const Color(0xFF4DA6FF), // Blue
              size: 60,
              type: ShapeType.shootingStar,
            ),
          ),
          // Shape 5: Crescent Moon (Light blue, large)
          Positioned(
            right: 20,
            bottom: 80,
            child: _buildFloatingShape(
              color: const Color(0xFF89B4F8), // Light blue
              size: 90,
              type: ShapeType.crescentMoon,
            ),
          ),
          // Shape 6: Spiral Galaxy (Green)
          const Positioned(
            left: 30,
            bottom: 40,
            child: SpiralGalaxyWidget(
              size: 70,
              color: Color(0xFF89F8B4), // Green
            ),
          ),
          
          // Center device mockup
          Center(
            child: Container(
              width: 180,
              height: 340,
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A),
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: const Center(
                child: SolarSystemWidget(
                  size: 140,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShape({
    required Color color,
    required double size,
    required ShapeType type,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ShapePainter(color: color, type: type),
    );
  }
}

enum ShapeType { zodiacWheel, crystal, constellation, shootingStar, crescentMoon }

class _ShapePainter extends CustomPainter {
  final Color color;
  final ShapeType type;

  _ShapePainter({required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case ShapeType.zodiacWheel:
        _drawZodiacWheel(canvas, size, paint);
        break;
      case ShapeType.crystal:
        _drawCrystal(canvas, size, paint);
        break;
      case ShapeType.constellation:
        _drawConstellation(canvas, size, paint);
        break;
      case ShapeType.shootingStar:
        _drawShootingStar(canvas, size, paint);
        break;
      case ShapeType.crescentMoon:
        _drawCrescentMoon(canvas, size, paint);
        break;
    }
  }

  // 1. Saturn - Planet with iconic rings
  void _drawZodiacWheel(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2.8;

    // Draw planet body with gradient effect
    final planetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color,
        ],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: r,
      ));

    canvas.drawCircle(Offset(cx, cy), r, planetPaint);

    // Draw horizontal bands (gas giant stripes)
    final bandPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(cx - r * 0.8, cy - r * 0.3),
      Offset(cx + r * 0.8, cy - r * 0.3),
      bandPaint,
    );
    canvas.drawLine(
      Offset(cx - r * 0.6, cy + r * 0.2),
      Offset(cx + r * 0.6, cy + r * 0.2),
      bandPaint,
    );

    // Draw iconic rings (elliptical)
    final ringPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final ringPath = Path();
    ringPath.addOval(Rect.fromCenter(
      center: Offset(cx, cy + r * 0.3),
      width: r * 3.2,
      height: r * 0.8,
    ));
    canvas.drawPath(ringPath, ringPaint);

    // Second ring (inner)
    final innerRingPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final innerRingPath = Path();
    innerRingPath.addOval(Rect.fromCenter(
      center: Offset(cx, cy + r * 0.3),
      width: r * 2.6,
      height: r * 0.6,
    ));
    canvas.drawPath(innerRingPath, innerRingPaint);

    // Add highlight for 3D effect on planet
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.4, highlightPaint);
  }

  // 2. Simple Star - Classic 5-pointed star
  void _drawCrystal(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = size.width / 2.5;
    final innerRadius = outerRadius * 0.4;

    final starPath = Path();
    
    // Draw 5-pointed star
    for (int i = 0; i < 5; i++) {
      // Outer point
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final outerX = cx + math.cos(outerAngle) * outerRadius;
      final outerY = cy + math.sin(outerAngle) * outerRadius;
      
      if (i == 0) {
        starPath.moveTo(outerX, outerY);
      } else {
        starPath.lineTo(outerX, outerY);
      }
      
      // Inner point
      final innerAngle = outerAngle + math.pi / 5;
      final innerX = cx + math.cos(innerAngle) * innerRadius;
      final innerY = cy + math.sin(innerAngle) * innerRadius;
      starPath.lineTo(innerX, innerY);
    }
    starPath.close();

    canvas.drawPath(starPath, paint);

    // Add glow effect for sparkle
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(starPath, glowPaint);

    // Add center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(Offset(cx, cy), outerRadius * 0.2, highlightPaint);
  }

  // 3. Constellation - Connected stars pattern
  void _drawConstellation(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 3;

    // Define star positions (Big Dipper-like pattern)
    final stars = [
      Offset(cx - r * 0.8, cy - r * 0.6),
      Offset(cx - r * 0.3, cy - r * 0.8),
      Offset(cx + r * 0.2, cy - r * 0.7),
      Offset(cx + r * 0.7, cy - r * 0.3),
      Offset(cx + r * 0.5, cy + r * 0.3),
    ];

    // Draw connecting lines
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }

    // Draw stars on top
    for (var star in stars) {
      canvas.drawCircle(star, 3, paint);
      // Add glow
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(star, 5, glowPaint);
    }
  }

  // 4. Shooting Star - Comet with tail
  void _drawShootingStar(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final starSize = size.width / 8;

    // Draw tail (gradient effect with multiple lines)
    final tailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      tailPaint
        ..strokeWidth = 3 - (i * 0.5)
        ..color = color.withOpacity(0.7 - (i * 0.15));
      
      final offsetX = i * 8.0;
      final offsetY = i * 8.0;
      canvas.drawLine(
        Offset(cx - offsetX, cy + offsetY),
        Offset(cx - offsetX - 15, cy + offsetY + 15),
        tailPaint,
      );
    }

    // Draw star head (5-pointed star)
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = cx + math.cos(angle) * starSize;
      final y = cy + math.sin(angle) * starSize;
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
      
      // Inner point
      final innerAngle = angle + math.pi / 5;
      final innerX = cx + math.cos(innerAngle) * starSize * 0.4;
      final innerY = cy + math.sin(innerAngle) * starSize * 0.4;
      starPath.lineTo(innerX, innerY);
    }
    starPath.close();

    canvas.drawPath(starPath, paint);

    // Add glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, cy), starSize, glowPaint);
  }

  // 5. Crescent Moon - Classic moon shape
  void _drawCrescentMoon(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2.5;

    // Use Path to create crescent shape
    final crescentPath = Path();
    
    // Add outer circle (full moon)
    crescentPath.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    
    // Subtract inner circle to create crescent
    final cutoutPath = Path();
    cutoutPath.addOval(Rect.fromCircle(
      center: Offset(cx + r * 0.4, cy - r * 0.1),
      radius: r * 0.85,
    ));
    
    // Create crescent by subtracting the cutout from the full moon
    final finalPath = Path.combine(
      PathOperation.difference,
      crescentPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, paint);

    // Add highlight for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.3, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



