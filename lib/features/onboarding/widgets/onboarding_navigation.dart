import 'package:flutter/material.dart';

/// Bottom navigation widget for onboarding screens
/// Includes back button, page indicators, and next/finish button
class OnboardingNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextButtonText;
  final bool showBackButton;

  const OnboardingNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onBack,
    required this.onNext,
    this.nextButtonText = 'Next',
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (showBackButton && onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              iconSize: 28,
              padding: const EdgeInsets.all(12),
            )
          else
            const SizedBox(width: 52), // Placeholder for alignment

          // Page indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              totalPages,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentPage
                      ? const Color(0xFF89B4F8) // Active color
                      : const Color(0xFF404040), // Inactive color
                ),
              ),
            ),
          ),

          // Next/Finish button
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF89B4F8),
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              minimumSize: const Size(100, 48),
            ),
            child: Text(
              nextButtonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



