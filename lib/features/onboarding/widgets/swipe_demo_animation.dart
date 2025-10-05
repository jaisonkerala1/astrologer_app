import 'package:flutter/material.dart';

/// Animated swipe gesture demonstration
/// Shows a hand icon swiping left/right
class SwipeDemoAnimation extends StatefulWidget {
  final String direction; // 'horizontal' or 'right'
  
  const SwipeDemoAnimation({
    super.key,
    this.direction = 'horizontal',
  });

  @override
  State<SwipeDemoAnimation> createState() => _SwipeDemoAnimationState();
}

class _SwipeDemoAnimationState extends State<SwipeDemoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.direction == 'right') {
      // Swipe left to right (for hidden feature demo)
      _slideAnimation = TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(-0.5, 0),
            end: const Offset(0.5, 0),
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: ConstantTween<Offset>(const Offset(0.5, 0)),
          weight: 30,
        ),
      ]).animate(_controller);
    } else {
      // Swipe left and right (for tab navigation demo)
      _slideAnimation = TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.4, 0),
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(-0.4, 0),
            end: const Offset(0.4, 0),
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(0.4, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25,
        ),
      ]).animate(_controller);
    }
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom navigation simulation (faded)
          if (widget.direction == 'horizontal')
            Opacity(
              opacity: 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabIcon(Icons.dashboard_outlined),
                  const SizedBox(width: 16),
                  _buildTabIcon(Icons.phone_outlined),
                  const SizedBox(width: 16),
                  _buildTabIcon(Icons.healing_outlined),
                  const SizedBox(width: 16),
                  _buildTabIcon(Icons.calendar_today_outlined),
                ],
              ),
            ),
          
          // Dashboard icon with swipe indicator (for right swipe)
          if (widget.direction == 'right')
            Opacity(
              opacity: 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  _buildTabIcon(Icons.dashboard_outlined),
                ],
              ),
            ),
          
          // Animated hand icon
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _slideAnimation.value.dx * 80,
                  _slideAnimation.value.dy * 80,
                ),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.back_hand,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

