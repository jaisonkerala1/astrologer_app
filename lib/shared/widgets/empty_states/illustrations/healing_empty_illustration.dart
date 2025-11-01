import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/services/theme_service.dart';

/// Beautiful animated lotus flower illustration for Healing empty state
/// Swiggy-style: Delightful, warm, calming
/// 
/// Features:
/// - Animated lotus petals opening
/// - Pulsing healing energy waves
/// - Floating sparkles
/// - Theme-aware colors
class HealingEmptyIllustration extends StatefulWidget {
  final double size;
  final ThemeService themeService;
  
  const HealingEmptyIllustration({
    super.key,
    this.size = 200,
    required this.themeService,
  });

  @override
  State<HealingEmptyIllustration> createState() => _HealingEmptyIllustrationState();
}

class _HealingEmptyIllustrationState extends State<HealingEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _sparkleController;
  late AnimationController _petalController;
  
  @override
  void initState() {
    super.initState();
    
    // Energy wave animation (2.5 seconds, repeating)
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    // Sparkle animation (3 seconds, repeating)
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    // Petal breathing animation (4 seconds, repeating)
    _petalController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    _sparkleController.dispose();
    _petalController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _sparkleController, _petalController]),
        builder: (context, child) {
          return CustomPaint(
            painter: HealingLotusPainter(
              waveAnimation: _waveController.value,
              sparkleAnimation: _sparkleController.value,
              petalAnimation: _petalController.value,
              themeService: widget.themeService,
            ),
          );
        },
      ),
    );
  }
}

class HealingLotusPainter extends CustomPainter {
  final double waveAnimation;
  final double sparkleAnimation;
  final double petalAnimation;
  final ThemeService themeService;
  
  HealingLotusPainter({
    required this.waveAnimation,
    required this.sparkleAnimation,
    required this.petalAnimation,
    required this.themeService,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundCircles(canvas, center, size);
    _drawEnergyWaves(canvas, center, size);
    _drawLotusFlower(canvas, center, size);
    _drawSparkles(canvas, center, size);
  }
  
  /// Draw soft background circles (healing aura)
  void _drawBackgroundCircles(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    final successColor = themeService.successColor;
    
    // Outer glow
    final outerPaint = Paint()
      ..color = primaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.48, outerPaint);
    
    // Middle glow
    final middlePaint = Paint()
      ..color = successColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.35, middlePaint);
    
    // Inner glow (breathing with petal animation)
    final breathScale = 0.22 + (0.03 * math.sin(petalAnimation * math.pi));
    final innerPaint = Paint()
      ..color = primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * breathScale, innerPaint);
  }
  
  /// Draw animated energy waves emanating from lotus
  void _drawEnergyWaves(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    final scale = size.width / 200;
    
    // Wave 1 - innermost
    final wave1Progress = waveAnimation;
    final wave1Radius = 30 * scale + (40 * scale * wave1Progress);
    final wave1Opacity = (1.0 - wave1Progress) * 0.4;
    
    final wave1Paint = Paint()
      ..color = primaryColor.withOpacity(wave1Opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;
    
    canvas.drawCircle(center, wave1Radius, wave1Paint);
    
    // Wave 2 - middle (delayed)
    final wave2Progress = (waveAnimation - 0.3).clamp(0.0, 1.0);
    if (wave2Progress > 0) {
      final wave2Radius = 30 * scale + (55 * scale * wave2Progress);
      final wave2Opacity = (1.0 - wave2Progress) * 0.3;
      
      final wave2Paint = Paint()
        ..color = themeService.successColor.withOpacity(wave2Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;
      
      canvas.drawCircle(center, wave2Radius, wave2Paint);
    }
    
    // Wave 3 - outermost (most delayed)
    final wave3Progress = (waveAnimation - 0.5).clamp(0.0, 1.0);
    if (wave3Progress > 0) {
      final wave3Radius = 30 * scale + (70 * scale * wave3Progress);
      final wave3Opacity = (1.0 - wave3Progress) * 0.25;
      
      final wave3Paint = Paint()
        ..color = primaryColor.withOpacity(wave3Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale;
      
      canvas.drawCircle(center, wave3Radius, wave3Paint);
    }
  }
  
  /// Draw the beautiful lotus flower
  void _drawLotusFlower(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    final secondaryColor = themeService.secondaryColor;
    
    // Breathing animation (slight scale pulsing)
    final breathScale = 1.0 + (0.05 * math.sin(petalAnimation * math.pi));
    
    // Center of lotus
    final lotusCenter = center;
    
    // Draw petals in layers (outer to inner)
    _drawPetalLayer(canvas, lotusCenter, 8, 45 * scale * breathScale, 0, 
                    primaryColor.withOpacity(0.3), scale);
    _drawPetalLayer(canvas, lotusCenter, 8, 35 * scale * breathScale, math.pi / 8, 
                    primaryColor.withOpacity(0.5), scale);
    _drawPetalLayer(canvas, lotusCenter, 6, 25 * scale * breathScale, 0, 
                    primaryColor.withOpacity(0.7), scale);
    
    // Center circle (lotus core)
    final corePaint = Paint()
      ..color = secondaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lotusCenter, 12 * scale * breathScale, corePaint);
    
    // Inner core glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lotusCenter, 6 * scale * breathScale, glowPaint);
    
    // Center dots (seeds)
    final seedPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) + (petalAnimation * math.pi / 4);
      final x = lotusCenter.dx + math.cos(angle) * 6 * scale;
      final y = lotusCenter.dy + math.sin(angle) * 6 * scale;
      canvas.drawCircle(Offset(x, y), 1.5 * scale, seedPaint);
    }
  }
  
  /// Draw a layer of petals around center
  void _drawPetalLayer(Canvas canvas, Offset center, int petalCount, 
                      double radius, double rotationOffset, Color color, double scale) {
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount) + rotationOffset;
      _drawPetal(canvas, center, angle, radius, color, scale);
    }
  }
  
  /// Draw a single lotus petal
  void _drawPetal(Canvas canvas, Offset center, double angle, 
                 double radius, Color color, double scale) {
    final petalPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Petal tip position
    final tipX = center.dx + math.cos(angle) * radius;
    final tipY = center.dy + math.sin(angle) * radius;
    
    // Petal width
    final width = radius * 0.4;
    
    // Control points for curved petal
    final leftAngle = angle - math.pi / 2;
    final rightAngle = angle + math.pi / 2;
    
    final leftX = center.dx + math.cos(leftAngle) * (width / 2);
    final leftY = center.dy + math.sin(leftAngle) * (width / 2);
    
    final rightX = center.dx + math.cos(rightAngle) * (width / 2);
    final rightY = center.dy + math.sin(rightAngle) * (width / 2);
    
    final path = Path();
    path.moveTo(leftX, leftY);
    
    // Curved petal shape
    path.quadraticBezierTo(
      tipX,
      tipY,
      rightX,
      rightY,
    );
    
    // Back to center
    path.quadraticBezierTo(
      center.dx + math.cos(angle) * (radius * 0.2),
      center.dy + math.sin(angle) * (radius * 0.2),
      leftX,
      leftY,
    );
    
    canvas.drawPath(path, petalPaint);
    
    // Add subtle gradient effect (inner glow)
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final innerPath = Path();
    final innerRadius = radius * 0.6;
    final innerTipX = center.dx + math.cos(angle) * innerRadius;
    final innerTipY = center.dy + math.sin(angle) * innerRadius;
    final innerWidth = width * 0.5;
    
    final innerLeftX = center.dx + math.cos(leftAngle) * (innerWidth / 2);
    final innerLeftY = center.dy + math.sin(leftAngle) * (innerWidth / 2);
    final innerRightX = center.dx + math.cos(rightAngle) * (innerWidth / 2);
    final innerRightY = center.dy + math.sin(rightAngle) * (innerWidth / 2);
    
    innerPath.moveTo(innerLeftX, innerLeftY);
    innerPath.quadraticBezierTo(innerTipX, innerTipY, innerRightX, innerRightY);
    innerPath.lineTo(center.dx, center.dy);
    innerPath.close();
    
    canvas.drawPath(innerPath, innerPaint);
  }
  
  /// Draw floating sparkles around lotus
  void _drawSparkles(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    final secondaryColor = themeService.secondaryColor;
    
    // Sparkle opacity animation (twinkling)
    final sparkle1 = 0.4 + (0.6 * math.sin(sparkleAnimation * 2 * math.pi));
    final sparkle2 = 0.4 + (0.6 * math.sin(sparkleAnimation * 2 * math.pi + math.pi / 3));
    final sparkle3 = 0.4 + (0.6 * math.sin(sparkleAnimation * 2 * math.pi + 2 * math.pi / 3));
    final sparkle4 = 0.4 + (0.6 * math.sin(sparkleAnimation * 2 * math.pi + math.pi));
    
    // Draw sparkles at various positions
    _drawStarSparkle(canvas, Offset(center.dx - 60 * scale, center.dy - 50 * scale), 
                     6 * scale, primaryColor.withOpacity(sparkle1));
    
    _drawStarSparkle(canvas, Offset(center.dx + 65 * scale, center.dy - 40 * scale), 
                     5 * scale, secondaryColor.withOpacity(sparkle2));
    
    _drawStarSparkle(canvas, Offset(center.dx + 55 * scale, center.dy + 60 * scale), 
                     7 * scale, primaryColor.withOpacity(sparkle3));
    
    _drawStarSparkle(canvas, Offset(center.dx - 65 * scale, center.dy + 45 * scale), 
                     5.5 * scale, secondaryColor.withOpacity(sparkle4));
    
    // Small circle sparkles
    final circlePaint = Paint()
      ..style = PaintingStyle.fill;
    
    circlePaint.color = primaryColor.withOpacity(sparkle2 * 0.6);
    canvas.drawCircle(Offset(center.dx + 70 * scale, center.dy), 3 * scale, circlePaint);
    
    circlePaint.color = secondaryColor.withOpacity(sparkle3 * 0.6);
    canvas.drawCircle(Offset(center.dx - 70 * scale, center.dy + 10 * scale), 2.5 * scale, circlePaint);
    
    circlePaint.color = primaryColor.withOpacity(sparkle1 * 0.6);
    canvas.drawCircle(Offset(center.dx, center.dy - 75 * scale), 3.5 * scale, circlePaint);
  }
  
  /// Draw a star sparkle (4-pointed)
  void _drawStarSparkle(Canvas canvas, Offset position, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
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
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(position, size * 0.5, glowPaint);
  }
  
  @override
  bool shouldRepaint(HealingLotusPainter oldDelegate) {
    return waveAnimation != oldDelegate.waveAnimation ||
           sparkleAnimation != oldDelegate.sparkleAnimation ||
           petalAnimation != oldDelegate.petalAnimation;
  }
}

