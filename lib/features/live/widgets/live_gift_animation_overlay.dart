import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen gift animation overlay
/// Shows flying emojis, particles, and effects when gifts are sent
class LiveGiftAnimationOverlay extends StatefulWidget {
  final GiftAnimation gift;
  final VoidCallback onComplete;

  const LiveGiftAnimationOverlay({
    super.key,
    required this.gift,
    required this.onComplete,
  });

  @override
  State<LiveGiftAnimationOverlay> createState() =>
      _LiveGiftAnimationOverlayState();
}

class _LiveGiftAnimationOverlayState extends State<LiveGiftAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particlesController;
  late Animation<double> _flyAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: Duration(milliseconds: widget.gift.getDuration()),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Flying animation from bottom-right to center
    _flyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    // Scale animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.5)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.2),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.8),
        weight: 40,
      ),
    ]).animate(_mainController);

    // Fade in
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.2),
    ));

    // Fade out
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0),
    ));

    // Generate particles for premium gifts
    _particles = _generateParticles();

    _mainController.forward().then((_) {
      widget.onComplete();
    });

    _particlesController.repeat();
  }

  List<Particle> _generateParticles() {
    if (widget.gift.tier == GiftTier.low) return [];

    final random = Random();
    final count = widget.gift.tier == GiftTier.premium ? 30 : 15;
    
    return List.generate(count, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 8 + 4,
        speed: random.nextDouble() * 2 + 1,
        color: widget.gift.color.withOpacity(random.nextDouble() * 0.8 + 0.2),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay for premium gifts
        if (widget.gift.tier == GiftTier.premium)
          AnimatedBuilder(
            animation: _fadeInAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value * 0.6 * _fadeOutAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        widget.gift.color.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // Particles
        if (_particles.isNotEmpty)
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  particles: _particles,
                  animation: _particlesController,
                  fadeOut: _fadeOutAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Main gift animation
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            final screenSize = MediaQuery.of(context).size;
            final startX = screenSize.width - 60;
            final startY = screenSize.height - 200;
            final endX = screenSize.width / 2;
            final endY = screenSize.height / 2;
            
            final currentX = startX + (endX - startX) * _flyAnimation.value;
            final currentY = startY + (endY - startY) * _flyAnimation.value;

            return Positioned(
              left: currentX - 50,
              top: currentY - 50,
              child: Opacity(
                opacity: _fadeInAnimation.value * _fadeOutAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main emoji
                      Text(
                        widget.gift.emoji,
                        style: TextStyle(
                          fontSize: widget.gift.tier == GiftTier.premium ? 120 : 80,
                        ),
                      ),
                      
                      // Gift name and sender (for premium gifts)
                      if (widget.gift.tier != GiftTier.low &&
                          _flyAnimation.value > 0.3) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.gift.color.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gift.color.withOpacity(0.6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.gift.senderName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'sent ${widget.gift.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (widget.gift.combo > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '×${widget.gift.combo}',
                                        style: TextStyle(
                                          color: widget.gift.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Combo text for high combos
        if (widget.gift.combo >= 5)
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              if (_flyAnimation.value < 0.4) return const SizedBox.shrink();
              
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeOutAnimation.value,
                  child: Center(
                    child: Text(
                      _getComboText(widget.gift.combo),
                      style: TextStyle(
                        color: widget.gift.color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getComboText(int combo) {
    if (combo >= 10) return '🔥 LEGENDARY! ⚡';
    if (combo >= 5) return '🔥 ON FIRE!';
    if (combo >= 3) return '✨ AMAZING!';
    return '';
  }
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final double fadeOut;

  ParticlesPainter({
    required this.particles,
    required this.animation,
    required this.fadeOut,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.color.opacity * fadeOut)
        ..style = PaintingStyle.fill;

      final progress = (animation.value * particle.speed) % 1.0;
      final x = size.width * particle.x;
      final y = size.height * (particle.y + progress);

      if (y < size.height) {
        canvas.drawCircle(
          Offset(x, y),
          particle.size * (1 - progress),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

enum GiftTier { low, mid, premium }

class GiftAnimation {
  final String name;
  final String emoji;
  final int value;
  final Color color;
  final GiftTier tier;
  final String senderName;
  final int combo;

  GiftAnimation({
    required this.name,
    required this.emoji,
    required this.value,
    required this.color,
    required this.tier,
    required this.senderName,
    this.combo = 1,
  });

  int getDuration() {
    switch (tier) {
      case GiftTier.premium:
        return 4000; // 4 seconds for premium
      case GiftTier.mid:
        return 3000; // 3 seconds for mid
      case GiftTier.low:
        return 2000; // 2 seconds for low
    }
  }

  static GiftTier getTierFromValue(int value) {
    if (value >= 1000) return GiftTier.premium;
    if (value >= 100) return GiftTier.mid;
    return GiftTier.low;
  }
}

