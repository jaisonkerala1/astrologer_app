import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/services/theme_service.dart';

/// Beautiful animated video camera illustration for Video Calls empty state
/// Swiggy-style: Modern, engaging, professional
/// 
/// Features:
/// - Animated video camera
/// - Recording indicator light
/// - Floating particles
/// - Theme-aware colors
class VideoCallEmptyIllustration extends StatefulWidget {
  final double size;
  final ThemeService themeService;
  
  const VideoCallEmptyIllustration({
    super.key,
    this.size = 200,
    required this.themeService,
  });

  @override
  State<VideoCallEmptyIllustration> createState() => _VideoCallEmptyIllustrationState();
}

class _VideoCallEmptyIllustrationState extends State<VideoCallEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _recordController;
  late AnimationController _floatController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    
    // Recording blink animation (1.5 seconds)
    _recordController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Float animation (3 seconds)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Particle animation (4 seconds)
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _recordController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_recordController, _floatController, _particleController]),
        builder: (context, child) {
          return CustomPaint(
            painter: VideoCallPainter(
              recordAnimation: _recordController.value,
              floatAnimation: _floatController.value,
              particleAnimation: _particleController.value,
              themeService: widget.themeService,
            ),
          );
        },
      ),
    );
  }
}

class VideoCallPainter extends CustomPainter {
  final double recordAnimation;
  final double floatAnimation;
  final double particleAnimation;
  final ThemeService themeService;
  
  VideoCallPainter({
    required this.recordAnimation,
    required this.floatAnimation,
    required this.particleAnimation,
    required this.themeService,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundGlow(canvas, center, size);
    _drawFloatingParticles(canvas, center, size);
    _drawVideoScreen(canvas, center, size);
    _drawCamera(canvas, center, size);
    _drawRecordingIndicator(canvas, center, size);
  }
  
  /// Draw soft background glow
  void _drawBackgroundGlow(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    final accentColor = themeService.accentColor;
    
    // Outer glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(0.08),
          primaryColor.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    
    canvas.drawCircle(center, size.width * 0.5, outerPaint);
    
    // Inner pulsing glow
    final pulseScale = 0.25 + (0.04 * math.sin(recordAnimation * 2 * math.pi));
    final innerPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * pulseScale, innerPaint);
  }
  
  /// Draw floating particles
  void _drawFloatingParticles(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi / 8) + (particleAnimation * 2 * math.pi);
      final distance = 70 * scale + (10 * scale * math.sin(particleAnimation * 2 * math.pi + i));
      final particleSize = 3 * scale + (1.5 * scale * math.sin(particleAnimation * 4 * math.pi + i));
      
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      final opacity = 0.3 + (0.4 * math.sin(particleAnimation * 2 * math.pi + i));
      
      final particlePaint = Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }
  
  /// Draw video screen
  void _drawVideoScreen(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Floating offset
    final floatOffset = 5 * scale * math.sin(floatAnimation * math.pi);
    final screenCenter = Offset(center.dx, center.dy + floatOffset);
    
    final primaryColor = themeService.primaryColor;
    
    // Screen frame
    final screenWidth = 85 * scale;
    final screenHeight = 55 * scale;
    final screenRadius = 8 * scale;
    
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: screenCenter,
        width: screenWidth,
        height: screenHeight,
      ),
      Radius.circular(screenRadius),
    );
    
    // Screen gradient background
    final screenPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withOpacity(0.2),
          primaryColor.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(screenRect.outerRect);
    
    canvas.drawRRect(screenRect, screenPaint);
    
    // Screen border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(0.4)
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(screenRect, borderPaint);
    
    // Screen content (grid pattern)
    _drawScreenGrid(canvas, screenCenter, scale);
    
    // Play icon on screen
    _drawPlayIcon(canvas, screenCenter, scale);
    
    // Shadow
    final shadowPath = Path()..addRRect(screenRect.shift(Offset(0, 3 * scale)));
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawPath(shadowPath, shadowPaint);
  }
  
  /// Draw screen grid pattern
  void _drawScreenGrid(Canvas canvas, Offset center, double scale) {
    final gridPaint = Paint()
      ..color = themeService.primaryColor.withOpacity(0.15)
      ..strokeWidth = 1 * scale;
    
    // Vertical lines
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(center.dx + i * 20 * scale, center.dy - 20 * scale),
        Offset(center.dx + i * 20 * scale, center.dy + 20 * scale),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(center.dx - 35 * scale, center.dy + i * 15 * scale),
        Offset(center.dx + 35 * scale, center.dy + i * 15 * scale),
        gridPaint,
      );
    }
  }
  
  /// Draw play icon
  void _drawPlayIcon(Canvas canvas, Offset center, double scale) {
    final secondaryColor = themeService.secondaryColor;
    
    // Play circle background
    final circlePaint = Paint()
      ..color = secondaryColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 18 * scale, circlePaint);
    
    // Play triangle
    final playPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final playPath = Path();
    playPath.moveTo(center.dx - 5 * scale, center.dy - 8 * scale);
    playPath.lineTo(center.dx + 8 * scale, center.dy);
    playPath.lineTo(center.dx - 5 * scale, center.dy + 8 * scale);
    playPath.close();
    
    canvas.drawPath(playPath, playPaint);
  }
  
  /// Draw video camera
  void _drawCamera(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Floating offset
    final floatOffset = 5 * scale * math.sin(floatAnimation * math.pi);
    final cameraCenter = Offset(center.dx + 45 * scale, center.dy - 30 * scale + floatOffset);
    
    final primaryColor = themeService.primaryColor;
    
    // Camera body
    final cameraWidth = 30 * scale;
    final cameraHeight = 22 * scale;
    
    final cameraRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: cameraCenter,
        width: cameraWidth,
        height: cameraHeight,
      ),
      Radius.circular(4 * scale),
    );
    
    final cameraPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          primaryColor.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(cameraRect.outerRect);
    
    canvas.drawRRect(cameraRect, cameraPaint);
    
    // Camera lens (triangle)
    final lensPaint = Paint()
      ..color = primaryColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    final lensPath = Path();
    final lensStart = Offset(cameraCenter.dx + cameraWidth / 2, cameraCenter.dy);
    lensPath.moveTo(lensStart.dx, lensStart.dy - 8 * scale);
    lensPath.lineTo(lensStart.dx + 12 * scale, lensStart.dy);
    lensPath.lineTo(lensStart.dx, lensStart.dy + 8 * scale);
    lensPath.close();
    
    canvas.drawPath(lensPath, lensPaint);
    
    // Lens border
    final lensBorderPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(lensPath, lensBorderPaint);
    
    // Camera details (buttons)
    final detailPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(cameraCenter.dx - 8 * scale, cameraCenter.dy - 6 * scale),
      2 * scale,
      detailPaint,
    );
  }
  
  /// Draw recording indicator
  void _drawRecordingIndicator(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Floating offset
    final floatOffset = 5 * scale * math.sin(floatAnimation * math.pi);
    final indicatorCenter = Offset(center.dx + 30 * scale, center.dy - 45 * scale + floatOffset);
    
    // Blinking effect
    final blink = 0.5 + (0.5 * math.sin(recordAnimation * 2 * math.pi));
    
    // Red dot
    final dotPaint = Paint()
      ..color = Colors.red.withOpacity(blink)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorCenter, 4 * scale, dotPaint);
    
    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(blink * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawCircle(indicatorCenter, 6 * scale, glowPaint);
  }
  
  @override
  bool shouldRepaint(VideoCallPainter oldDelegate) {
    return recordAnimation != oldDelegate.recordAnimation ||
           floatAnimation != oldDelegate.floatAnimation ||
           particleAnimation != oldDelegate.particleAnimation;
  }
}

