import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../../../shared/widgets/illustrations/verification_success_illustration.dart';

/// Final slide after document submission - celebration with animated illustration
class VerificationFinalSlide extends StatelessWidget {
  const VerificationFinalSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Responsive sizing
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8D5F2), // Soft purple/lavender at top
                const Color(0xFFF5F0FA), // Very light purple
                const Color(0xFFFFFFFF), // White at bottom
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: isSmallScreen ? 40 : 60,
                bottom: 120, // Space for navigation
              ),
              child: Column(
                children: [
                  // Beautiful animated illustration
                  VerificationSuccessIllustration(
                    size: isSmallScreen ? 240 : 280,
                  ),

                  SizedBox(height: isSmallScreen ? 40 : 48),

                  // Success Title
                  Text(
                    'Documents Submitted!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 26 : 28,
                      fontWeight: FontWeight.bold,
                      color: themeService.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Success Message
                  Text(
                    'Your verification documents have been submitted successfully.',
                    style: TextStyle(
                      fontSize: 15,
                      color: themeService.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Info card with subtle design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Color(0xFF7C3AED),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review in Progress',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: themeService.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'We\'ll review within 24-48 hours',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeService.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

