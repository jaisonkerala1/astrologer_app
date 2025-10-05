import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Swipe hint indicator - shows a subtle pulsing arrow on the left edge
/// to indicate that users can swipe right to reveal Live Prep screen
class SwipeHintIndicator extends StatefulWidget {
  final bool show;
  final VoidCallback? onDismiss;
  
  const SwipeHintIndicator({
    super.key,
    this.show = true,
    this.onDismiss,
  });

  @override
  State<SwipeHintIndicator> createState() => _SwipeHintIndicatorState();
}

class _SwipeHintIndicatorState extends State<SwipeHintIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create repeating animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade in and out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Slide right slightly
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.show) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SwipeHintIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.repeat();
    } else if (!widget.show && oldWidget.show) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: 60,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Arrow icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: themeService.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                color: themeService.primaryColor,
                                size: 16,
                              ),
                              Icon(
                                Icons.arrow_back_ios,
                                color: themeService.primaryColor.withOpacity(0.5),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Text hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Swipe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

