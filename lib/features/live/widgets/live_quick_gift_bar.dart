import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Quick gift bar that appears on long-press of gift button
/// Shows top 5 most popular gifts for instant sending
class LiveQuickGiftBar extends StatefulWidget {
  final List<QuickGift> gifts;
  final Function(QuickGift) onGiftTap;
  final VoidCallback onDismiss;

  const LiveQuickGiftBar({
    super.key,
    required this.gifts,
    required this.onGiftTap,
    required this.onDismiss,
  });

  @override
  State<LiveQuickGiftBar> createState() => _LiveQuickGiftBarState();
}

class _LiveQuickGiftBarState extends State<LiveQuickGiftBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleGiftTap(QuickGift gift) {
    HapticFeedback.selectionClick();
    widget.onGiftTap(gift);
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () {
            _animationController.reverse().then((_) {
              widget.onDismiss();
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to send instantly',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gifts row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.gifts.map((gift) {
                          return _buildQuickGift(gift);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickGift(QuickGift gift) {
    return GestureDetector(
      onTap: () => _handleGiftTap(gift),
      child: Container(
        width: 64,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gift.color.withOpacity(0.3),
              gift.color.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gift.color.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gift.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: gift.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₹${gift.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickGift {
  final String name;
  final String emoji;
  final int value;
  final Color color;

  QuickGift({
    required this.name,
    required this.emoji,
    required this.value,
    required this.color,
  });
}

