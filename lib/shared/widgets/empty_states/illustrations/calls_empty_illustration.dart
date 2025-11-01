import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/services/theme_service.dart';

/// Beautiful animated phone illustration for Calls empty state
/// Swiggy-style: Clean, modern, inviting
/// 
/// Features:
/// - Animated phone with ringing waves
/// - Pulsing sound waves
/// - Theme-aware colors
class CallsEmptyIllustration extends StatefulWidget {
  final double size;
  final ThemeService themeService;
  
  const CallsEmptyIllustration({
    super.key,
    this.size = 200,
    required this.themeService,
  });

  @override
  State<CallsEmptyIllustration> createState() => _CallsEmptyIllustrationState();
}

class _CallsEmptyIllustrationState extends State<CallsEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _floatController;
  
  @override
  void initState() {
    super.initState();
    
    // Ringing waves animation (2 seconds)
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    // Phone floating animation (3 seconds)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _ringController.dispose();
    _floatController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ringController, _floatController]),
        builder: (context, child) {
          return CustomPaint(
            painter: CallsPhonePainter(
              ringAnimation: _ringController.value,
              floatAnimation: _floatController.value,
              themeService: widget.themeService,
            ),
          );
        },
      ),
    );
  }
}

class CallsPhonePainter extends CustomPainter {
  final double ringAnimation;
  final double floatAnimation;
  final ThemeService themeService;
  
  CallsPhonePainter({
    required this.ringAnimation,
    required this.floatAnimation,
    required this.themeService,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundGlow(canvas, center, size);
    _drawRingingWaves(canvas, center, size);
    _drawPhone(canvas, center, size);
    _drawSoundWaves(canvas, center, size);
  }
  
  /// Draw soft background glow
  void _drawBackgroundGlow(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    
    // Outer glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    
    canvas.drawCircle(center, size.width * 0.5, outerPaint);
    
    // Inner pulsing glow
    final pulseScale = 0.28 + (0.05 * math.sin(ringAnimation * 2 * math.pi));
    final innerPaint = Paint()
      ..color = primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * pulseScale, innerPaint);
  }
  
  /// Draw animated ringing waves
  void _drawRingingWaves(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final primaryColor = themeService.primaryColor;
    
    // Wave 1
    final wave1Progress = ringAnimation;
    final wave1Radius = 50 * scale + (50 * scale * wave1Progress);
    final wave1Opacity = (1.0 - wave1Progress) * 0.5;
    
    final wave1Paint = Paint()
      ..color = primaryColor.withOpacity(wave1Opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    
    canvas.drawCircle(center, wave1Radius, wave1Paint);
    
    // Wave 2 (delayed)
    final wave2Progress = (ringAnimation - 0.3).clamp(0.0, 1.0);
    if (wave2Progress > 0) {
      final wave2Radius = 50 * scale + (65 * scale * wave2Progress);
      final wave2Opacity = (1.0 - wave2Progress) * 0.4;
      
      final wave2Paint = Paint()
        ..color = primaryColor.withOpacity(wave2Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      
      canvas.drawCircle(center, wave2Radius, wave2Paint);
    }
    
    // Wave 3 (more delayed)
    final wave3Progress = (ringAnimation - 0.5).clamp(0.0, 1.0);
    if (wave3Progress > 0) {
      final wave3Radius = 50 * scale + (75 * scale * wave3Progress);
      final wave3Opacity = (1.0 - wave3Progress) * 0.3;
      
      final wave3Paint = Paint()
        ..color = primaryColor.withOpacity(wave3Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;
      
      canvas.drawCircle(center, wave3Radius, wave3Paint);
    }
  }
  
  /// Draw the phone
  void _drawPhone(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Floating animation
    final floatOffset = 8 * scale * math.sin(floatAnimation * math.pi);
    final phoneCenter = Offset(center.dx, center.dy + floatOffset);
    
    final primaryColor = themeService.primaryColor;
    final secondaryColor = themeService.secondaryColor;
    
    // Phone body
    final phoneWidth = 60 * scale;
    final phoneHeight = 100 * scale;
    final phoneRadius = 12 * scale;
    
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: phoneCenter,
        width: phoneWidth,
        height: phoneHeight,
      ),
      Radius.circular(phoneRadius),
    );
    
    // Phone gradient
    final phonePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          primaryColor.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(phoneRect.outerRect);
    
    canvas.drawRRect(phoneRect, phonePaint);
    
    // Phone border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(phoneRect, borderPaint);
    
    // Screen
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: phoneCenter,
        width: phoneWidth - 10 * scale,
        height: phoneHeight - 25 * scale,
      ),
      Radius.circular(8 * scale),
    );
    
    final screenPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(screenRect, screenPaint);
    
    // Call icon on screen
    _drawCallIcon(canvas, phoneCenter, scale, secondaryColor);
    
    // Home button/speaker
    final speakerPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // Top speaker
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(phoneCenter.dx, phoneCenter.dy - phoneHeight / 2 + 8 * scale),
          width: 20 * scale,
          height: 3 * scale,
        ),
        Radius.circular(1.5 * scale),
      ),
      speakerPaint,
    );
    
    // Bottom button
    canvas.drawCircle(
      Offset(phoneCenter.dx, phoneCenter.dy + phoneHeight / 2 - 8 * scale),
      3 * scale,
      speakerPaint,
    );
    
    // Phone shadow
    final shadowPath = Path()..addRRect(phoneRect.shift(Offset(0, 3 * scale)));
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawPath(shadowPath, shadowPaint);
  }
  
  /// Draw call icon
  void _drawCallIcon(Canvas canvas, Offset center, double scale, Color color) {
    final iconPaint = Paint()
      ..color = color
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final iconSize = 25 * scale;
    
    // Phone handset path
    final path = Path();
    
    // Bottom left curve (handset bottom)
    path.moveTo(center.dx - iconSize / 3, center.dy + iconSize / 3);
    path.quadraticBezierTo(
      center.dx - iconSize / 2,
      center.dy + iconSize / 4,
      center.dx - iconSize / 3,
      center.dy,
    );
    
    // Top curve
    path.quadraticBezierTo(
      center.dx - iconSize / 4,
      center.dy - iconSize / 4,
      center.dx,
      center.dy - iconSize / 3,
    );
    
    // Top right curve
    path.quadraticBezierTo(
      center.dx + iconSize / 4,
      center.dy - iconSize / 4,
      center.dx + iconSize / 3,
      center.dy,
    );
    
    // Bottom right curve (handset top)
    path.quadraticBezierTo(
      center.dx + iconSize / 2,
      center.dy + iconSize / 4,
      center.dx + iconSize / 3,
      center.dy + iconSize / 3,
    );
    
    canvas.drawPath(path, iconPaint);
    
    // Fill the handset slightly
    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);
  }
  
  /// Draw sound waves
  void _drawSoundWaves(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    final secondaryColor = themeService.secondaryColor;
    
    // Floating offset (same as phone)
    final floatOffset = 8 * scale * math.sin(floatAnimation * math.pi);
    
    // Left side waves
    for (int i = 0; i < 3; i++) {
      final phase = (ringAnimation + i * 0.2) % 1.0;
      final opacity = 0.6 - (i * 0.15);
      final distance = 35 * scale + (i * 8 * scale);
      
      final wavePaint = Paint()
        ..color = secondaryColor.withOpacity(opacity * (1.0 - phase))
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final waveHeight = 12 * scale * (1.0 + phase);
      
      final wavePath = Path();
      wavePath.moveTo(
        center.dx - distance,
        center.dy + floatOffset - waveHeight,
      );
      wavePath.quadraticBezierTo(
        center.dx - distance - 5 * scale,
        center.dy + floatOffset,
        center.dx - distance,
        center.dy + floatOffset + waveHeight,
      );
      
      canvas.drawPath(wavePath, wavePaint);
    }
    
    // Right side waves
    for (int i = 0; i < 3; i++) {
      final phase = (ringAnimation + i * 0.2 + 0.1) % 1.0;
      final opacity = 0.6 - (i * 0.15);
      final distance = 35 * scale + (i * 8 * scale);
      
      final wavePaint = Paint()
        ..color = secondaryColor.withOpacity(opacity * (1.0 - phase))
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final waveHeight = 12 * scale * (1.0 + phase);
      
      final wavePath = Path();
      wavePath.moveTo(
        center.dx + distance,
        center.dy + floatOffset - waveHeight,
      );
      wavePath.quadraticBezierTo(
        center.dx + distance + 5 * scale,
        center.dy + floatOffset,
        center.dx + distance,
        center.dy + floatOffset + waveHeight,
      );
      
      canvas.drawPath(wavePath, wavePaint);
    }
  }
  
  @override
  bool shouldRepaint(CallsPhonePainter oldDelegate) {
    return ringAnimation != oldDelegate.ringAnimation ||
           floatAnimation != oldDelegate.floatAnimation;
  }
}

