import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/services/theme_service.dart';

/// Beautiful animated chat bubbles for Communication empty state
/// Swiggy-style: Friendly, inviting, social
/// 
/// Features:
/// - Animated chat bubbles floating
/// - Connecting lines between bubbles
/// - Typing indicator animation
/// - Theme-aware colors
class CommunicationEmptyIllustration extends StatefulWidget {
  final double size;
  final ThemeService themeService;
  
  const CommunicationEmptyIllustration({
    super.key,
    this.size = 200,
    required this.themeService,
  });

  @override
  State<CommunicationEmptyIllustration> createState() => _CommunicationEmptyIllustrationState();
}

class _CommunicationEmptyIllustrationState extends State<CommunicationEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _typingController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    
    // Floating animation (3 seconds)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Typing indicator animation (1.5 seconds)
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Pulse animation for connection (2 seconds)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _floatController.dispose();
    _typingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _typingController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            painter: CommunicationBubblesPainter(
              floatAnimation: _floatController.value,
              typingAnimation: _typingController.value,
              pulseAnimation: _pulseController.value,
              themeService: widget.themeService,
            ),
          );
        },
      ),
    );
  }
}

class CommunicationBubblesPainter extends CustomPainter {
  final double floatAnimation;
  final double typingAnimation;
  final double pulseAnimation;
  final ThemeService themeService;
  
  CommunicationBubblesPainter({
    required this.floatAnimation,
    required this.typingAnimation,
    required this.pulseAnimation,
    required this.themeService,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw in layers (back to front)
    _drawBackgroundGlow(canvas, center, size);
    _drawConnectionLines(canvas, center, size);
    _drawChatBubbles(canvas, center, size);
    _drawFloatingIcons(canvas, center, size);
  }
  
  /// Draw soft background glow
  void _drawBackgroundGlow(Canvas canvas, Offset center, Size size) {
    final primaryColor = themeService.primaryColor;
    final accentColor = themeService.accentColor;
    
    // Outer glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(0.06),
          primaryColor.withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    
    canvas.drawCircle(center, size.width * 0.5, outerPaint);
    
    // Inner glow (pulsing)
    final pulseScale = 0.22 + (0.04 * math.sin(pulseAnimation * 2 * math.pi));
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.12),
          accentColor.withOpacity(0.08),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * pulseScale));
    
    canvas.drawCircle(center, size.width * pulseScale, innerPaint);
  }
  
  /// Draw animated connection lines between bubbles
  void _drawConnectionLines(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Define bubble positions (same as in _drawChatBubbles)
    final float1 = 8 * math.sin(floatAnimation * math.pi);
    final float2 = 8 * math.sin((floatAnimation + 0.33) * math.pi);
    final float3 = 8 * math.sin((floatAnimation + 0.66) * math.pi);
    
    final bubble1Center = Offset(center.dx - 45 * scale, center.dy - 30 * scale + float1);
    final bubble2Center = Offset(center.dx + 50 * scale, center.dy - 20 * scale + float2);
    final bubble3Center = Offset(center.dx, center.dy + 45 * scale + float3);
    
    // Pulsing connection lines
    final pulse = 0.5 + (0.5 * math.sin(pulseAnimation * 2 * math.pi));
    
    final linePaint = Paint()
      ..color = themeService.primaryColor.withOpacity(0.15 * pulse)
      ..strokeWidth = 2.5 * scale
      ..style = PaintingStyle.stroke;
    
    // Draw dashed lines
    _drawDashedLine(canvas, bubble1Center, bubble2Center, linePaint, scale);
    _drawDashedLine(canvas, bubble2Center, bubble3Center, linePaint, scale);
    _drawDashedLine(canvas, bubble3Center, bubble1Center, linePaint, scale);
    
    // Draw connection nodes (small circles at bubble centers)
    final nodePaint = Paint()
      ..color = themeService.accentColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(bubble1Center, 3 * scale, nodePaint);
    canvas.drawCircle(bubble2Center, 3 * scale, nodePaint);
    canvas.drawCircle(bubble3Center, 3 * scale, nodePaint);
    
    // Pulsing rings around nodes
    final ringPaint = Paint()
      ..color = themeService.accentColor.withOpacity(0.3 * pulse)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(bubble1Center, 6 * scale * (1 + pulse * 0.3), ringPaint);
    canvas.drawCircle(bubble2Center, 6 * scale * (1 + pulse * 0.3), ringPaint);
    canvas.drawCircle(bubble3Center, 6 * scale * (1 + pulse * 0.3), ringPaint);
  }
  
  /// Draw dashed line between two points
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double scale) {
    final dashLength = 5 * scale;
    final dashGap = 4 * scale;
    
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    final unitDx = dx / distance;
    final unitDy = dy / distance;
    
    double currentDistance = 0;
    bool isDash = true;
    
    while (currentDistance < distance) {
      final nextDistance = currentDistance + (isDash ? dashLength : dashGap);
      
      if (isDash) {
        final x1 = start.dx + unitDx * currentDistance;
        final y1 = start.dy + unitDy * currentDistance;
        final x2 = start.dx + unitDx * math.min(nextDistance, distance);
        final y2 = start.dy + unitDy * math.min(nextDistance, distance);
        
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
      
      currentDistance = nextDistance;
      isDash = !isDash;
    }
  }
  
  /// Draw chat bubbles with floating animation
  void _drawChatBubbles(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Floating offsets (smooth sine wave)
    final float1 = 8 * scale * math.sin(floatAnimation * math.pi);
    final float2 = 8 * scale * math.sin((floatAnimation + 0.33) * math.pi);
    final float3 = 8 * scale * math.sin((floatAnimation + 0.66) * math.pi);
    
    // Bubble 1 (Left top - sent message)
    _drawChatBubble(
      canvas,
      Offset(center.dx - 45 * scale, center.dy - 30 * scale + float1),
      50 * scale,
      30 * scale,
      themeService.primaryColor,
      true,
      scale,
      showTyping: false,
    );
    
    // Bubble 2 (Right top - received message)
    _drawChatBubble(
      canvas,
      Offset(center.dx + 50 * scale, center.dy - 20 * scale + float2),
      55 * scale,
      32 * scale,
      themeService.accentColor,
      false,
      scale,
      showTyping: false,
    );
    
    // Bubble 3 (Bottom center - typing message)
    _drawChatBubble(
      canvas,
      Offset(center.dx, center.dy + 45 * scale + float3),
      45 * scale,
      28 * scale,
      themeService.secondaryColor,
      true,
      scale,
      showTyping: true,
    );
  }
  
  /// Draw a single chat bubble
  void _drawChatBubble(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    Color color,
    bool isRight,
    double scale, {
    bool showTyping = false,
  }) {
    // Bubble body
    final bubblePath = Path();
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: width,
        height: height,
      ),
      Radius.circular(14 * scale),
    );
    
    bubblePath.addRRect(bubbleRect);
    
    // Add tail
    final tailSize = 6 * scale;
    final tailX = isRight 
        ? position.dx + width / 2 - 10 * scale
        : position.dx - width / 2 + 10 * scale;
    final tailY = position.dy + height / 2;
    
    bubblePath.moveTo(tailX, tailY);
    bubblePath.lineTo(
      tailX + (isRight ? 1 : -1) * tailSize,
      tailY + tailSize,
    );
    bubblePath.lineTo(
      tailX + (isRight ? -1 : 1) * tailSize,
      tailY,
    );
    bubblePath.close();
    
    // Draw bubble with gradient
    final bubblePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bubbleRect.outerRect);
    
    canvas.drawPath(bubblePath, bubblePaint);
    
    // Add subtle shadow
    final shadowPath = bubblePath.shift(Offset(0, 2 * scale));
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw content (lines or typing indicator)
    if (showTyping) {
      _drawTypingIndicator(canvas, position, scale);
    } else {
      _drawMessageLines(canvas, position, scale);
    }
  }
  
  /// Draw message lines inside bubble
  void _drawMessageLines(Canvas canvas, Offset position, double scale) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    
    // Line 1 (longer)
    canvas.drawLine(
      Offset(position.dx - 15 * scale, position.dy - 5 * scale),
      Offset(position.dx + 15 * scale, position.dy - 5 * scale),
      linePaint,
    );
    
    // Line 2 (shorter)
    canvas.drawLine(
      Offset(position.dx - 10 * scale, position.dy + 5 * scale),
      Offset(position.dx + 10 * scale, position.dy + 5 * scale),
      linePaint,
    );
  }
  
  /// Draw animated typing indicator (3 dots)
  void _drawTypingIndicator(Canvas canvas, Offset position, double scale) {
    final dotSpacing = 8 * scale;
    final dotRadius = 2.5 * scale;
    
    // Each dot bounces with delay
    for (int i = 0; i < 3; i++) {
      final phase = (typingAnimation + (i * 0.2)) % 1.0;
      final bounce = -6 * scale * math.sin(phase * math.pi);
      
      final dotX = position.dx + (i - 1) * dotSpacing;
      final dotY = position.dy + bounce;
      
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
    }
  }
  
  /// Draw floating communication icons
  void _drawFloatingIcons(Canvas canvas, Offset center, Size size) {
    final scale = size.width / 200;
    
    // Icon positions and animations
    final icons = [
      {'x': -70.0, 'y': -60.0, 'phase': 0.0, 'icon': 'phone'},
      {'x': 75.0, 'y': -65.0, 'phase': 0.4, 'icon': 'video'},
      {'x': -75.0, 'y': 60.0, 'phase': 0.6, 'icon': 'heart'},
      {'x': 70.0, 'y': 55.0, 'phase': 0.8, 'icon': 'message'},
    ];
    
    for (final iconData in icons) {
      final phase = (floatAnimation + (iconData['phase'] as double)) % 1.0;
      final float = 5 * scale * math.sin(phase * 2 * math.pi);
      final opacity = 0.5 + (0.3 * math.sin(phase * 2 * math.pi));
      
      final iconX = center.dx + (iconData['x'] as double) * scale;
      final iconY = center.dy + (iconData['y'] as double) * scale + float;
      
      _drawIcon(
        canvas,
        Offset(iconX, iconY),
        iconData['icon'] as String,
        scale,
        themeService.primaryColor.withOpacity(opacity),
      );
    }
  }
  
  /// Draw simple icon representations
  void _drawIcon(Canvas canvas, Offset position, String iconType, double scale, Color color) {
    final iconPaint = Paint()
      ..color = color
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final iconSize = 8 * scale;
    
    switch (iconType) {
      case 'phone':
        // Phone icon (curved line)
        final phonePath = Path();
        phonePath.moveTo(position.dx - iconSize / 2, position.dy - iconSize / 2);
        phonePath.quadraticBezierTo(
          position.dx - iconSize / 4,
          position.dy,
          position.dx + iconSize / 2,
          position.dy + iconSize / 2,
        );
        canvas.drawPath(phonePath, iconPaint);
        break;
        
      case 'video':
        // Video icon (play triangle)
        final videoPath = Path();
        videoPath.moveTo(position.dx - iconSize / 2, position.dy - iconSize / 2);
        videoPath.lineTo(position.dx + iconSize / 2, position.dy);
        videoPath.lineTo(position.dx - iconSize / 2, position.dy + iconSize / 2);
        videoPath.close();
        canvas.drawPath(videoPath, iconPaint);
        break;
        
      case 'heart':
        // Heart icon (two circles + triangle)
        final heartPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(position.dx - iconSize / 4, position.dy - iconSize / 4),
          iconSize / 3,
          heartPaint,
        );
        canvas.drawCircle(
          Offset(position.dx + iconSize / 4, position.dy - iconSize / 4),
          iconSize / 3,
          heartPaint,
        );
        final heartPath = Path();
        heartPath.moveTo(position.dx, position.dy + iconSize / 2);
        heartPath.lineTo(position.dx - iconSize / 2, position.dy - iconSize / 6);
        heartPath.lineTo(position.dx + iconSize / 2, position.dy - iconSize / 6);
        heartPath.close();
        canvas.drawPath(heartPath, heartPaint);
        break;
        
      case 'message':
        // Message icon (speech bubble)
        canvas.drawCircle(position, iconSize / 2, iconPaint);
        break;
    }
  }
  
  @override
  bool shouldRepaint(CommunicationBubblesPainter oldDelegate) {
    return floatAnimation != oldDelegate.floatAnimation ||
           typingAnimation != oldDelegate.typingAnimation ||
           pulseAnimation != oldDelegate.pulseAnimation;
  }
}

