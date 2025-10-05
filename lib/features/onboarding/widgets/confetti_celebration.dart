import 'dart:math';
import 'package:flutter/material.dart';

/// Beautiful confetti celebration animation
/// Shows when tutorial is completed
class ConfettiCelebration extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const ConfettiCelebration({
    super.key,
    this.onComplete,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Generate confetti particles
    for (int i = 0; i < 80; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble() * 2 - 1, // -1 to 1
        y: -0.2 - _random.nextDouble() * 0.3,
        rotation: _random.nextDouble() * 360,
        color: _getRandomColor(),
        size: 6 + _random.nextDouble() * 6,
        velocityY: 0.3 + _random.nextDouble() * 0.5,
        velocityX: (_random.nextDouble() - 0.5) * 0.3,
      ));
    }
    
    _controller.forward();
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFF00B894),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Confetti particles
        ...List.generate(_particles.length, (index) {
          final particle = _particles[index];
          
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              final x = size.width * 0.5 + (particle.x * size.width * 0.4);
              final y = size.height * 0.3 + (progress * particle.velocityY * size.height) +
                  (particle.velocityX * progress * size.width * 0.2);
              final rotation = particle.rotation + (progress * 360 * 2);
              final opacity = 1.0 - (progress * 0.5);
              
              return Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: rotation * pi / 180,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Success message
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkmark icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success text
                Text(
                  'Perfect!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'You\'re all set! 🎉',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Model for confetti particle
class ConfettiParticle {
  final double x;
  final double y;
  final double rotation;
  final Color color;
  final double size;
  final double velocityY;
  final double velocityX;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.rotation,
    required this.color,
    required this.size,
    required this.velocityY,
    required this.velocityX,
  });
}

