import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services/tutorial_service.dart';
import '../widgets/tutorial_step_card.dart';
import '../widgets/swipe_demo_animation.dart';
import '../widgets/confetti_celebration.dart';

/// Ultra-minimal, beautiful 15-second tutorial overlay
/// Design inspired by Instagram, TikTok, and modern apps
class QuickTutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  
  const QuickTutorialOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<QuickTutorialOverlay> createState() => _QuickTutorialOverlayState();
}

class _QuickTutorialOverlayState extends State<QuickTutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _stepController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentStep = 0;
  bool _hasSwipedRight = false;
  bool _showingCelebration = false;
  
  // Tutorial steps
  final int _totalSteps = 2; // Only 2 steps!
  
  @override
  void initState() {
    super.initState();
    
    // Fade in/out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Step transition animation
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepController,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Start animations
    _fadeController.forward();
    _stepController.forward();
    
    // Auto-advance Step 1 after 5 seconds
    _scheduleAutoAdvance();
  }
  
  void _scheduleAutoAdvance() {
    if (_currentStep == 0) {
      // Auto-advance from step 1 after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _currentStep == 0) {
          _nextStep();
          // Schedule completion for step 2 after showing for 5 seconds
          _scheduleStep2Completion();
        }
      });
    }
  }
  
  void _scheduleStep2Completion() {
    // Step 2: Show the hidden feature hint for 5 seconds, then complete
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentStep == 1 && !_showingCelebration) {
        setState(() {
          _hasSwipedRight = true; // Mark as if they completed it
        });
        // Wait a moment to show the checkmark
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _completeTutorial();
          }
        });
      }
    });
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      
      // Animate transition
      _stepController.reset();
      _stepController.forward();
      
      HapticFeedback.selectionClick();
    } else {
      _completeTutorial();
    }
  }
  
  void _onSwipeRight() {
    if (_currentStep == 1 && !_hasSwipedRight) {
      setState(() {
        _hasSwipedRight = true;
      });
      
      HapticFeedback.mediumImpact();
      
      // Complete tutorial immediately when they discover the hidden feature
      _completeTutorial();
    }
  }
  
  // Listen to page changes to detect swipe right
  void checkForSwipeRight(int pageIndex) {
    if (pageIndex == 0 && _currentStep == 1 && !_hasSwipedRight) {
      _onSwipeRight();
    }
  }
  
  void _completeTutorial() {
    setState(() {
      _showingCelebration = true;
    });
    
    HapticFeedback.heavyImpact();
    
    // Mark as completed
    context.read<TutorialService>().completeTutorial();
    
    // Close after celebration
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          widget.onComplete();
        });
      }
    });
  }
  
  void _skipTutorial() {
    HapticFeedback.lightImpact();
    context.read<TutorialService>().skipTutorial(_currentStep);
    
    _fadeController.reverse().then((_) {
      widget.onComplete();
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Glassmorphic background overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                
                // Main content
                if (!_showingCelebration)
                  _buildTutorialContent(themeService)
                else
                  ConfettiCelebration(
                    onComplete: () {
                      // Already scheduled to close
                    },
                  ),
                
                // Skip button (always visible unless celebrating)
                if (!_showingCelebration)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: _buildSkipButton(themeService),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTutorialContent(ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildStep(themeService),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStep(ThemeService themeService) {
    switch (_currentStep) {
      case 0:
        return TutorialStepCard(
          key: const ValueKey(0),
          emoji: '👈',
          title: 'Swipe Between Tabs',
          description: 'Navigate faster with gestures',
          child: const SwipeDemoAnimation(),
          progressDots: _buildProgressDots(themeService),
        );
      case 1:
        return TutorialStepCard(
          key: const ValueKey(1),
          emoji: '✨',
          title: 'Hidden Feature',
          description: 'Swipe right from Dashboard to Go Live',
          subtitle: _hasSwipedRight ? 'Got it! 🎉' : null,
          showArrow: false,
          child: _hasSwipedRight
              ? Icon(
                  Icons.check_circle,
                  size: 80,
                  color: themeService.successColor,
                )
              : const SwipeDemoAnimation(direction: 'right'),
          progressDots: _buildProgressDots(themeService),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildProgressDots(ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isPassed = index < _currentStep;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isPassed || isActive
                ? themeService.primaryColor
                : themeService.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
  
  Widget _buildSkipButton(ThemeService themeService) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _skipTutorial,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

