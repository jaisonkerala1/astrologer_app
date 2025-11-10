import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Bottom navigation widget for verification flow
/// Includes back button, page indicators, and next/skip/submit buttons
class VerificationNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final String nextButtonText;
  final bool nextEnabled;
  final bool isLoading;

  const VerificationNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onBack,
    this.onNext,
    this.onSkip,
    this.nextButtonText = 'Next',
    this.nextEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Responsive sizing
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;
        final horizontalPadding = screenWidth > 600 ? 48.0 : 24.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeService.backgroundColor.withOpacity(0.0),
                themeService.backgroundColor.withOpacity(0.95),
                themeService.backgroundColor,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isSmallScreen ? 16 : 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (or spacer)
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: Icon(
                        Icons.arrow_back,
                        color: themeService.textPrimary,
                      ),
                      iconSize: 28,
                      padding: const EdgeInsets.all(12),
                      splashRadius: 24,
                    )
                  else
                    const SizedBox(width: 52), // Spacer for alignment

                  // Page indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: index == currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == currentPage
                              ? themeService.primaryColor
                              : themeService.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),

                  // Right side buttons (Skip and/or Next)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Skip button (if available)
                      if (onSkip != null) ...[
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: themeService.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Next/Submit button
                      ElevatedButton(
                        onPressed: nextEnabled && onNext != null && !isLoading
                            ? onNext
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              themeService.textSecondary.withOpacity(0.3),
                          disabledForegroundColor:
                              themeService.textSecondary.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(
                            horizontal: onSkip != null ? 24 : 32,
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: nextEnabled ? 2 : 0,
                          minimumSize: Size(onSkip != null ? 100 : 120, 48),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                nextButtonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

