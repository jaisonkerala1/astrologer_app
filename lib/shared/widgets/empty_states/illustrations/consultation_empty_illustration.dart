import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/services/theme_service.dart';

/// Beautiful animated astrology chart for Consultation empty state
/// Swiggy-style: Mystical, engaging, professional
/// 
/// Features:
/// - Animated zodiac wheel rotating
/// - Twinkling stars
/// - Orbiting planets
/// - Theme-aware colors
class ConsultationEmptyIllustration extends StatefulWidget {
  final double size;
  final ThemeService themeService;
  
  const ConsultationEmptyIllustration({
    super.key,
    this.size = 200,
    required this.themeService,
  });

  @override
  State<ConsultationEmptyIllustration> createState() => _ConsultationEmptyIllustrationState();
}

class _ConsultationEmptyIllustrationState extends State<ConsultationEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _starController;
  late AnimationController _orbitController;
  
  @override
  void initState() {
    super.initState();
    
    // Slow rotation (20 seconds for full rotation)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Star twinkling (2.5 seconds)
    _starController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    // Planet orbit (8 seconds)
    _orbitController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _starController.dispose();
    _orbitController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _starController, _orbitController]),
        builder: (context, child) {
          return CustomPaint(
            painter: ConsultationChartPainter(
              rotationAnimation: _rotationController.value,
              starAnimation: _starController.value,
              orbitAnimation: _orbitController.value,
              themeService: widget.themeService,
            ),
          );
        },
      ),
    );
  }
}

class ConsultationChartPainter extends CustomPainter {
  final double rotationAnimation;
  final double starAnimation;
  final double orbitAnimation;
  final ThemeService themeService;
  
  ConsultationChartPainter({
    required this.rotationAnimation,
    required this.starAnimation,
    required this.orbitAnimation,
    required this.themeService,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundGlow(canvas, center, size);
    _drawConstellationLines(canvas, center, size);
    _drawZodiacWheel(canvas, center, size);
    _drawCenterSymbol(canvas, center, size);
    _drawOrbitingPlanets(canvas, center, size);
    _drawTwinklingStars(canvas, center, size);
  }
  
  /// Draw soft background glow
  void _drawBackgroundGlow(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    final accentColor = themeService.accentColor;
    
    // Outer glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.08),
          accentColor.withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    
    canvas.drawCircle(center, size.width * 0.5, outerPaint);
    
    // Inner glow (pulsing)
    final pulseScale = 0.25 + (0.03 * math.sin(starAnimation * 2 * math.pi));
    final innerPaint = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * pulseScale, innerPaint);
  }
  
  /// Draw constellation connection lines
  void _drawConstellationLines(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final linePaint = Paint()
      ..color = themeService.primaryColor.withOpacity(0.2)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    
    // Create mystical constellation pattern
    final points = [
      Offset(center.dx - 50 * scale, center.dy - 60 * scale),
      Offset(center.dx + 60 * scale, center.dy - 50 * scale),
      Offset(center.dx + 65 * scale, center.dy + 40 * scale),
      Offset(center.dx - 55 * scale, center.dy + 55 * scale),
      Offset(center.dx - 40 * scale, center.dy - 20 * scale),
    ];
    
    // Draw connecting lines (create triangles and patterns)
    canvas.drawLine(points[0], points[4], linePaint);
    canvas.drawLine(points[4], points[1], linePaint);
    canvas.drawLine(points[1], points[2], linePaint);
    canvas.drawLine(points[2], points[3], linePaint);
    canvas.drawLine(points[3], points[0], linePaint);
  }
  
  /// Draw rotating zodiac wheel
  void _drawZodiacWheel(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final radius = 60 * scale;
    
    // Outer circle
    final outerCirclePaint = Paint()
      ..color = themeService.primaryColor.withOpacity(0.3)
      ..strokeWidth = 2.5 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, outerCirclePaint);
    
    // Inner circle
    final innerRadius = 45 * scale;
    final innerCirclePaint = Paint()
      ..color = themeService.accentColor.withOpacity(0.25)
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, innerRadius, innerCirclePaint);
    
    // Draw 12 zodiac segments (rotating slowly)
    final segmentCount = 12;
    final rotationOffset = rotationAnimation * 2 * math.pi;
    
    for (int i = 0; i < segmentCount; i++) {
      final angle = (i * 2 * math.pi / segmentCount) + rotationOffset;
      
      // Radial lines
      final linePaint = Paint()
        ..color = themeService.primaryColor.withOpacity(0.2)
        ..strokeWidth = 1 * scale;
      
      final innerX = center.dx + math.cos(angle) * innerRadius;
      final innerY = center.dy + math.sin(angle) * innerRadius;
      final outerX = center.dx + math.cos(angle) * radius;
      final outerY = center.dy + math.sin(angle) * radius;
      
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        linePaint,
      );
      
      // Zodiac symbol dots
      final dotAngle = angle + (math.pi / segmentCount);
      final dotRadius = (innerRadius + radius) / 2;
      final dotX = center.dx + math.cos(dotAngle) * dotRadius;
      final dotY = center.dy + math.sin(dotAngle) * dotRadius;
      
      final dotPaint = Paint()
        ..color = themeService.secondaryColor.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(dotX, dotY), 2 * scale, dotPaint);
    }
    
    // Decorative arcs between segments
    final arcPaint = Paint()
      ..color = themeService.primaryColor.withOpacity(0.15)
      ..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < segmentCount; i++) {
      final startAngle = (i * 2 * math.pi / segmentCount) + rotationOffset + (math.pi / 24);
      final sweepAngle = (math.pi / segmentCount) * 0.5;
      
      final arcRect = Rect.fromCircle(
        center: center,
        radius: (innerRadius + radius) / 2,
      );
      
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    }
  }
  
  /// Draw center mystical symbol
  void _drawCenterSymbol(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    final secondaryColor = themeService.secondaryColor;
    
    // Outer ring
    final outerRingPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.6),
          primaryColor.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 25 * scale));
    
    canvas.drawCircle(center, 25 * scale, outerRingPaint);
    
    // Inner ring
    final innerRingPaint = Paint()
      ..color = themeService.surfaceColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 20 * scale, innerRingPaint);
    
    // Draw mystical symbol (simplified Om or star)
    // Draw a beautiful 8-pointed star
    final starPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    
    final starPath = Path();
    final starRadius = 15 * scale;
    final innerStarRadius = 7 * scale;
    final starPoints = 8;
    
    for (int i = 0; i < starPoints * 2; i++) {
      final angle = (i * math.pi / starPoints) - (math.pi / 2);
      final radius = i.isEven ? starRadius : innerStarRadius;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    
    canvas.drawPath(starPath, starPaint);
    
    // Center glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 4 * scale, glowPaint);
  }
  
  /// Draw orbiting planets
  void _drawOrbitingPlanets(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Planet 1 (clockwise orbit)
    final planet1Angle = orbitAnimation * 2 * math.pi;
    final planet1Radius = 75 * scale;
    final planet1X = center.dx + math.cos(planet1Angle) * planet1Radius;
    final planet1Y = center.dy + math.sin(planet1Angle) * planet1Radius;
    
    final planet1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeService.secondaryColor,
          themeService.secondaryColor.withOpacity(0.6),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(planet1X, planet1Y),
        radius: 6 * scale,
      ));
    
    canvas.drawCircle(Offset(planet1X, planet1Y), 6 * scale, planet1Paint);
    
    // Planet glow
    final glowPaint = Paint()
      ..color = themeService.secondaryColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(planet1X, planet1Y), 8 * scale, glowPaint);
    
    // Planet 2 (counter-clockwise orbit, smaller)
    final planet2Angle = -orbitAnimation * 2 * math.pi + math.pi;
    final planet2Radius = 85 * scale;
    final planet2X = center.dx + math.cos(planet2Angle) * planet2Radius;
    final planet2Y = center.dy + math.sin(planet2Angle) * planet2Radius;
    
    final planet2Paint = Paint()
      ..color = themeService.accentColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(planet2X, planet2Y), 4 * scale, planet2Paint);
    
    // Planet 2 glow
    final glow2Paint = Paint()
      ..color = themeService.accentColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(planet2X, planet2Y), 6 * scale, glow2Paint);
  }
  
  /// Draw twinkling stars scattered around
  void _drawTwinklingStars(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    final accentColor = themeService.accentColor;
    
    // Star positions (fixed)
    final starPositions = [
      Offset(center.dx - 50 * scale, center.dy - 60 * scale),
      Offset(center.dx + 60 * scale, center.dy - 50 * scale),
      Offset(center.dx + 65 * scale, center.dy + 40 * scale),
      Offset(center.dx - 55 * scale, center.dy + 55 * scale),
      Offset(center.dx - 40 * scale, center.dy - 20 * scale),
      Offset(center.dx + 30 * scale, center.dy + 70 * scale),
      Offset(center.dx - 70 * scale, center.dy + 10 * scale),
      Offset(center.dx + 75 * scale, center.dy - 15 * scale),
    ];
    
    // Draw each star with different twinkle timing
    for (int i = 0; i < starPositions.length; i++) {
      final phase = (i * 2 * math.pi / starPositions.length);
      final twinkle = 0.3 + (0.7 * math.sin(starAnimation * 2 * math.pi + phase));
      
      final color = i.isEven ? primaryColor : accentColor;
      
      _drawStar(canvas, starPositions[i], 5 * scale, 
                color.withOpacity(twinkle), scale);
    }
  }
  
  /// Draw a single 4-pointed star
  void _drawStar(Canvas canvas, Offset position, double size, Color color, double scale) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    
    // Vertical line
    canvas.drawLine(
      Offset(position.dx, position.dy - size),
      Offset(position.dx, position.dy + size),
      paint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(position.dx - size, position.dy),
      Offset(position.dx + size, position.dy),
      paint,
    );
    
    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, 2 * scale, dotPaint);
  }
  
  @override
  bool shouldRepaint(ConsultationChartPainter oldDelegate) {
    return rotationAnimation != oldDelegate.rotationAnimation ||
           starAnimation != oldDelegate.starAnimation ||
           orbitAnimation != oldDelegate.orbitAnimation;
  }
}

