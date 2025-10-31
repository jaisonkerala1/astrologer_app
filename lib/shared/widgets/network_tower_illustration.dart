import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painted network tower illustration for offline indicator
/// Draws a beautiful 3D cell tower with animated signal waves
class NetworkTowerIllustration extends StatefulWidget {
  final double size;
  
  const NetworkTowerIllustration({
    super.key,
    this.size = 200,
  });

  @override
  State<NetworkTowerIllustration> createState() => _NetworkTowerIllustrationState();
}

class _NetworkTowerIllustrationState extends State<NetworkTowerIllustration>
    with TickerProviderStateMixin {
  late AnimationController _signalController;
  late AnimationController _sparkleController;
  
  @override
  void initState() {
    super.initState();
    
    // Signal wave animation (2 seconds, repeating)
    _signalController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    // Sparkle twinkle animation (3 seconds, repeating)
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _signalController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_signalController, _sparkleController]),
        builder: (context, child) {
          return CustomPaint(
            painter: NetworkTowerPainter(
              signalAnimation: _signalController.value,
              sparkleAnimation: _sparkleController.value,
            ),
          );
        },
      ),
    );
  }
}

class NetworkTowerPainter extends CustomPainter {
  final double signalAnimation;
  final double sparkleAnimation;
  
  NetworkTowerPainter({
    required this.signalAnimation,
    required this.sparkleAnimation,
  });
  
  // Color palette
  static const outerCircleColor = Color(0xFFFFF4E6);  // Light peach
  static const middleCircleColor = Color(0xFFFFEDD5); // Lighter orange
  static const innerCircleColor = Color(0xFFFFF0D9);  // Very light orange
  static const towerFrontColor = Color(0xFF2D3748);   // Dark navy
  static const towerSideColor = Color(0xFF4A5568);    // Gray (3D depth)
  static const signalColor = Color(0xFFFF9F5E);       // Orange
  static const sparkleColor = Color(0xFFFFD89C);      // Light yellow-orange
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundCircles(canvas, center, size);
    _drawDecorativeElements(canvas, size);
    _drawTowerStructure(canvas, center, size);
    _drawAnimatedSignalWaves(canvas, center, size);
  }
  
  /// Draw 3 concentric background circles
  void _drawBackgroundCircles(Canvas canvas, Offset center, Size size) {
    final outerPaint = Paint()
      ..color = outerCircleColor
      ..style = PaintingStyle.fill;
    
    final middlePaint = Paint()
      ..color = middleCircleColor
      ..style = PaintingStyle.fill;
    
    final innerPaint = Paint()
      ..color = innerCircleColor
      ..style = PaintingStyle.fill;
    
    // Outer circle (100% of size)
    canvas.drawCircle(center, size.width * 0.5, outerPaint);
    
    // Middle circle (75% of size)
    canvas.drawCircle(center, size.width * 0.375, middlePaint);
    
    // Inner circle (50% of size)
    canvas.drawCircle(center, size.width * 0.25, innerPaint);
  }
  
  /// Draw the 3D skeleton tower structure with wireframe
  void _drawTowerStructure(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200; // Base scale for 200px
    
    // Tower dimensions
    final towerHeight = 120.0 * scale;
    final bottomWidth = 50.0 * scale;
    final towerBottom = center.dy + 40 * scale;
    final towerTop = towerBottom - towerHeight;
    
    // Top point (SINGLE SHARED POINT for both front and back - true point!)
    final topPoint = Offset(center.dx, towerTop);
    
    // 3D depth offset for perspective (only for bottom, not top)
    final depthOffset = 10.0 * scale;
    
    // Paint for main edges (dark navy, thick)
    final mainEdgePaint = Paint()
      ..color = towerFrontColor
      ..strokeWidth = 4.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Paint for back edges (lighter gray, thinner for depth)
    final backEdgePaint = Paint()
      ..color = towerSideColor
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Paint for cross-bracing (lighter, thinner)
    final bracingPaint = Paint()
      ..color = towerSideColor.withOpacity(0.7)
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Define corner points
    // Front bottom corners
    final frontBottomLeft = Offset(center.dx - bottomWidth / 2, towerBottom);
    final frontBottomRight = Offset(center.dx + bottomWidth / 2, towerBottom);
    
    // Back bottom corners (with depth offset - but top is SAME POINT)
    final backBottomLeft = Offset(center.dx - bottomWidth / 2 + depthOffset, towerBottom - depthOffset);
    final backBottomRight = Offset(center.dx + bottomWidth / 2 + depthOffset, towerBottom - depthOffset);
    
    // STEP 1: Draw back edges (lighter, for depth) - ALL from SAME top point
    canvas.drawLine(topPoint, backBottomLeft, backEdgePaint); // Back left edge
    canvas.drawLine(topPoint, backBottomRight, backEdgePaint); // Back right edge
    canvas.drawLine(backBottomLeft, backBottomRight, backEdgePaint); // Back bottom
    
    // STEP 2: Draw connecting edges (front to back at bottom only)
    canvas.drawLine(frontBottomLeft, backBottomLeft, bracingPaint);
    canvas.drawLine(frontBottomRight, backBottomRight, bracingPaint);
    
    // STEP 3: Draw front edges (darker, thicker, on top) - from SAME top point
    canvas.drawLine(topPoint, frontBottomLeft, mainEdgePaint); // Front left edge
    canvas.drawLine(topPoint, frontBottomRight, mainEdgePaint); // Front right edge
    canvas.drawLine(frontBottomLeft, frontBottomRight, mainEdgePaint); // Front bottom
    
    // STEP 4: Draw horizontal crossbars (3 levels)
    final crossbarPositions = [0.3, 0.55, 0.8]; // Adjusted positions
    
    for (final position in crossbarPositions) {
      final y = towerTop + (towerHeight * position);
      final widthAtY = bottomWidth * position; // Width grows from 0 at top to full at bottom
      
      // Front horizontal bar
      canvas.drawLine(
        Offset(center.dx - widthAtY / 2, y),
        Offset(center.dx + widthAtY / 2, y),
        bracingPaint,
      );
      
      // Back horizontal bar (with depth offset)
      final backY = y - (depthOffset * (1 - position));
      canvas.drawLine(
        Offset(center.dx - widthAtY / 2 + depthOffset, backY),
        Offset(center.dx + widthAtY / 2 + depthOffset, backY),
        Paint()
          ..color = towerSideColor.withOpacity(0.5)
          ..strokeWidth = 2.0 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
    
    // STEP 5: Draw diagonal cross-bracing (X pattern between crossbars)
    final diagonalPaint = Paint()
      ..color = towerSideColor.withOpacity(0.6)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;
    
    // Add X-bracing between each horizontal level
    for (int i = 0; i < crossbarPositions.length; i++) {
      final startPosition = i == 0 ? 0.0 : crossbarPositions[i - 1];
      final endPosition = crossbarPositions[i];
      
      final y1 = towerTop + (towerHeight * startPosition);
      final y2 = towerTop + (towerHeight * endPosition);
      final width1 = bottomWidth * startPosition; // From point (0) to wider
      final width2 = bottomWidth * endPosition;
      
      // Left X-brace - from point at top to left side below
      if (startPosition == 0.0) {
        // From top point
        canvas.drawLine(
          topPoint,
          Offset(center.dx - width2 / 2, y2),
          diagonalPaint,
        );
      } else {
        canvas.drawLine(
          Offset(center.dx - width1 / 2, y1),
          Offset(center.dx, y2),
          diagonalPaint,
        );
        canvas.drawLine(
          Offset(center.dx, y1),
          Offset(center.dx - width2 / 2, y2),
          diagonalPaint,
        );
      }
      
      // Right X-brace - from point at top to right side below
      if (startPosition == 0.0) {
        // From top point
        canvas.drawLine(
          topPoint,
          Offset(center.dx + width2 / 2, y2),
          diagonalPaint,
        );
      } else {
        canvas.drawLine(
          Offset(center.dx, y1),
          Offset(center.dx + width2 / 2, y2),
          diagonalPaint,
        );
        canvas.drawLine(
          Offset(center.dx + width1 / 2, y1),
          Offset(center.dx, y2),
          diagonalPaint,
        );
      }
    }
    
    // STEP 6: Draw base support beams (rounded feet)
    final basePaint = Paint()
      ..color = towerFrontColor
      ..strokeWidth = 5.0 * scale
      ..strokeCap = StrokeCap.round;
    
    // Add small circles at the base for feet
    canvas.drawCircle(frontBottomLeft, 3.5 * scale, Paint()..color = towerFrontColor..style = PaintingStyle.fill);
    canvas.drawCircle(frontBottomRight, 3.5 * scale, Paint()..color = towerFrontColor..style = PaintingStyle.fill);
    
    // STEP 7: Draw small dot at the top point (where signal originates)
    canvas.drawCircle(topPoint, 4.0 * scale, Paint()..color = towerFrontColor..style = PaintingStyle.fill);
  }
  
  /// Draw animated signal waves at tower top
  void _drawAnimatedSignalWaves(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final towerHeight = 120.0 * scale;
    final towerBottom = center.dy + 40 * scale;
    final towerTop = towerBottom - towerHeight;
    
    // Signal source point (exactly at the pointy top of tower)
    final signalCenter = Offset(center.dx, towerTop);
    
    // WAVE 1: Inner solid circle (always visible)
    final innerCirclePaint = Paint()
      ..color = signalColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(signalCenter, 8 * scale, innerCirclePaint);
    
    // WAVE 2: First expanding ring
    final wave1Progress = signalAnimation;
    final wave1Radius = 8 * scale + (25 * scale * wave1Progress);
    final wave1Opacity = 1.0 - wave1Progress;
    
    final wave1Paint = Paint()
      ..color = signalColor.withOpacity(wave1Opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    
    canvas.drawCircle(signalCenter, wave1Radius, wave1Paint);
    
    // WAVE 3: Second expanding ring (delayed)
    final wave2Progress = (signalAnimation - 0.3).clamp(0.0, 1.0);
    if (wave2Progress > 0) {
      final wave2Radius = 8 * scale + (35 * scale * wave2Progress);
      final wave2Opacity = 1.0 - wave2Progress;
      
      final wave2Paint = Paint()
        ..color = signalColor.withOpacity(wave2Opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      
      canvas.drawCircle(signalCenter, wave2Radius, wave2Paint);
    }
    
    // WAVE 4: Third expanding ring (more delayed)
    final wave3Progress = (signalAnimation - 0.5).clamp(0.0, 1.0);
    if (wave3Progress > 0) {
      final wave3Radius = 8 * scale + (45 * scale * wave3Progress);
      final wave3Opacity = 1.0 - wave3Progress;
      
      final wave3Paint = Paint()
        ..color = signalColor.withOpacity(wave3Opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;
      
      canvas.drawCircle(signalCenter, wave3Radius, wave3Paint);
    }
  }
  
  /// Draw decorative sparkles and small circles
  void _drawDecorativeElements(Canvas canvas, Size size) {
    final scale = size.width / 200;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Sparkle opacity animation (twinkling effect)
    final sparkleOpacity1 = 0.3 + (0.5 * math.sin(sparkleAnimation * 2 * math.pi));
    final sparkleOpacity2 = 0.3 + (0.5 * math.sin(sparkleAnimation * 2 * math.pi + math.pi / 2));
    final sparkleOpacity3 = 0.3 + (0.5 * math.sin(sparkleAnimation * 2 * math.pi + math.pi));
    
    // Plus sign sparkles at different positions
    _drawPlusSparkle(canvas, Offset(center.dx + 65 * scale, center.dy - 70 * scale), 
                     8 * scale, sparkleColor.withOpacity(sparkleOpacity1));
    
    _drawPlusSparkle(canvas, Offset(center.dx - 55 * scale, center.dy - 30 * scale), 
                     6 * scale, sparkleColor.withOpacity(sparkleOpacity2));
    
    _drawPlusSparkle(canvas, Offset(center.dx + 70 * scale, center.dy + 40 * scale), 
                     7 * scale, sparkleColor.withOpacity(sparkleOpacity3));
    
    // Small asterisk sparkle
    _drawAsteriskSparkle(canvas, Offset(center.dx + 80 * scale, center.dy + 5 * scale), 
                         5 * scale, sparkleColor.withOpacity(sparkleOpacity1));
    
    // Small circle decorations
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    
    circlePaint.color = sparkleColor.withOpacity(sparkleOpacity2);
    canvas.drawCircle(Offset(center.dx - 65 * scale, center.dy - 55 * scale), 4 * scale, circlePaint);
    
    circlePaint.color = sparkleColor.withOpacity(sparkleOpacity3);
    canvas.drawCircle(Offset(center.dx - 75 * scale, center.dy + 50 * scale), 3 * scale, circlePaint);
    
    circlePaint.color = sparkleColor.withOpacity(sparkleOpacity1);
    canvas.drawCircle(Offset(center.dx + 75 * scale, center.dy - 45 * scale), 3.5 * scale, circlePaint);
  }
  
  /// Draw a plus (+) sparkle
  void _drawPlusSparkle(Canvas canvas, Offset position, double size, Color color) {
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
  }
  
  /// Draw an asterisk (*) sparkle (4 lines)
  void _drawAsteriskSparkle(Canvas canvas, Offset position, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    // Vertical
    canvas.drawLine(
      Offset(position.dx, position.dy - size),
      Offset(position.dx, position.dy + size),
      paint,
    );
    
    // Horizontal
    canvas.drawLine(
      Offset(position.dx - size, position.dy),
      Offset(position.dx + size, position.dy),
      paint,
    );
    
    // Diagonal 1
    canvas.drawLine(
      Offset(position.dx - size * 0.7, position.dy - size * 0.7),
      Offset(position.dx + size * 0.7, position.dy + size * 0.7),
      paint,
    );
    
    // Diagonal 2
    canvas.drawLine(
      Offset(position.dx + size * 0.7, position.dy - size * 0.7),
      Offset(position.dx - size * 0.7, position.dy + size * 0.7),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(NetworkTowerPainter oldDelegate) {
    return signalAnimation != oldDelegate.signalAnimation ||
           sparkleAnimation != oldDelegate.sparkleAnimation;
  }
}

