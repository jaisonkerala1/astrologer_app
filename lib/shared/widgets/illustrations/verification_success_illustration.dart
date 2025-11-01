import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Beautiful celebration illustration for verification document submission
/// Features: Animated checkmark, confetti particles, stars, and celebratory elements
class VerificationSuccessIllustration extends StatefulWidget {
  final double size;
  
  const VerificationSuccessIllustration({
    super.key,
    this.size = 250,
  });

  @override
  State<VerificationSuccessIllustration> createState() => _VerificationSuccessIllustrationState();
}

class _VerificationSuccessIllustrationState extends State<VerificationSuccessIllustration>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _starController;
  
  late Animation<double> _checkAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    
    // Checkmark draw animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
    
    // Confetti fall animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Star twinkle animation
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _confettiController.forward();
        _pulseController.repeat(reverse: true);
        _starController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated decorations (confetti, stars, rings)
          AnimatedBuilder(
            animation: Listenable.merge([
              _confettiAnimation,
              _starAnimation,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _VerificationSuccessPainter(
                  checkProgress: _checkAnimation.value,
                  confettiProgress: _confettiAnimation.value,
                  pulse: _pulseAnimation.value,
                  starTwinkle: _starAnimation.value,
                ),
              );
            },
          ),
          
          // PNG Image with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Image.asset(
                  'illustrationverificationstarted.png',
                  width: widget.size * 0.75,
                  height: widget.size * 0.75,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerificationSuccessPainter extends CustomPainter {
  final double checkProgress;
  final double confettiProgress;
  final double pulse;
  final double starTwinkle;

  _VerificationSuccessPainter({
    required this.checkProgress,
    required this.confettiProgress,
    required this.pulse,
    required this.starTwinkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw confetti particles
    _drawConfetti(canvas, size);
    
    // Draw decorative stars
    _drawStars(canvas, size);
    
    // Note: PNG image will be drawn in the widget, not here in CustomPaint
    // This painter now only handles the animated decorations around the image
    
    // Draw decorative rings behind the image
    _drawDecorativeRings(canvas, center, size.width * 0.4);
  }

  void _drawConfetti(Canvas canvas, Size size) {
    final confettiPaint = Paint()..style = PaintingStyle.fill;
    
    // Define confetti colors
    final colors = [
      const Color(0xFF1877F2), // Meta blue
      const Color(0xFF10B981), // Green
      const Color(0xFFFC5185), // Pink
      const Color(0xFFFFC107), // Yellow
      const Color(0xFF9C27B0), // Purple
    ];
    
    // Draw multiple confetti pieces
    final random = math.Random(42); // Fixed seed for consistent animation
    for (int i = 0; i < 25; i++) {
      final angle = (i / 25) * 2 * math.pi;
      final distance = 80 + (i % 3) * 20;
      final fallDistance = confettiProgress * 100;
      
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance + fallDistance;
      
      // Only draw if within bounds
      if (y < size.height && y > 0) {
        confettiPaint.color = colors[i % colors.length].withOpacity(
          (1 - confettiProgress) * 0.8,
        );
        
        // Rotate confetti as it falls
        final rotation = confettiProgress * math.pi * 4 + (i * 0.5);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);
        
        // Draw confetti shape (rectangle or circle)
        if (i % 2 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3, -6, 6, 12),
              const Radius.circular(2),
            ),
            confettiPaint,
          );
        } else {
          canvas.drawCircle(Offset.zero, 4, confettiPaint);
        }
        
        canvas.restore();
      }
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFC107).withOpacity(starTwinkle * 0.8);
    
    // Draw stars at various positions
    final starPositions = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.75),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
    ];
    
    for (int i = 0; i < starPositions.length; i++) {
      final size = 8 + (math.sin(starTwinkle * math.pi * 2 + i) * 3);
      _drawStar(canvas, starPositions[i], size, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final outerRadius = size;
      final innerRadius = size * 0.4;
      
      final outerX = center.dx + math.cos(angle) * outerRadius;
      final outerY = center.dy + math.sin(angle) * outerRadius;
      
      final innerAngle = angle + (2 * math.pi / 10);
      final innerX = center.dx + math.cos(innerAngle) * innerRadius;
      final innerY = center.dy + math.sin(innerAngle) * innerRadius;
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMainCircle(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1877F2).withOpacity(0.3),
          const Color(0xFF1877F2).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * pulse * 1.2));
    canvas.drawCircle(center, radius * pulse * 1.2, glowPaint);
    
    // Main circle with gradient
    final circlePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1877F2),
          const Color(0xFF0C63E4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, circlePaint);
    
    // Inner highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center - const Offset(10, 10), radius: radius * 0.6));
    canvas.drawCircle(center, radius, highlightPaint);
  }

  void _drawCheckmark(Canvas canvas, Offset center, double size) {
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Start of check
    final startX = center.dx - size * 0.5;
    final startY = center.dy;
    
    // Middle of check
    final midX = center.dx - size * 0.1;
    final midY = center.dy + size * 0.5;
    
    // End of check
    final endX = center.dx + size * 0.6;
    final endY = center.dy - size * 0.4;
    
    // Animate the checkmark drawing
    if (checkProgress > 0) {
      path.moveTo(startX, startY);
      
      if (checkProgress <= 0.5) {
        // First part of check (down stroke)
        final progress = checkProgress * 2;
        path.lineTo(
          startX + (midX - startX) * progress,
          startY + (midY - startY) * progress,
        );
      } else {
        // Complete first part
        path.lineTo(midX, midY);
        
        // Second part of check (up stroke)
        final progress = (checkProgress - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * progress,
          midY + (endY - midY) * progress,
        );
      }
      
      canvas.drawPath(path, checkPaint);
    }
  }

  void _drawDecorativeRings(Canvas canvas, Offset center, double radius) {
    final ringPaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF1877F2).withOpacity(0.3 * (1 - confettiProgress));
    
    final ringPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF1877F2).withOpacity(0.3 * (1 - confettiProgress));
    
    // Draw expanding rings
    final ring1Radius = radius + (30 * confettiProgress);
    final ring2Radius = radius + (50 * confettiProgress);
    
    canvas.drawCircle(center, ring1Radius, ringPaint1);
    canvas.drawCircle(center, ring2Radius, ringPaint2);
  }

  @override
  bool shouldRepaint(_VerificationSuccessPainter oldDelegate) {
    return oldDelegate.checkProgress != checkProgress ||
        oldDelegate.confettiProgress != confettiProgress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.starTwinkle != starTwinkle;
  }
}

