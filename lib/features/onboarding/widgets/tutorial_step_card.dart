import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Beautiful glassmorphic card for tutorial steps
/// Modern, minimal design with blur effect
class TutorialStepCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String? subtitle;
  final Widget child;
  final Widget? progressDots;
  final bool showArrow;
  
  const TutorialStepCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    this.subtitle,
    required this.child,
    this.progressDots,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
                minHeight: 300,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Demo child
                  SizedBox(
                    height: 100,
                    child: child,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Subtitle/Call to action
                  if (subtitle != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: showArrow
                            ? themeService.primaryColor.withOpacity(0.2)
                            : themeService.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: showArrow
                              ? themeService.primaryColor.withOpacity(0.3)
                              : themeService.successColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showArrow) ...[
                            const SizedBox(width: 8),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 10.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(value - 5, 0),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                              onEnd: () {
                                // Loop animation
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Progress dots
                  if (progressDots != null) progressDots!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

