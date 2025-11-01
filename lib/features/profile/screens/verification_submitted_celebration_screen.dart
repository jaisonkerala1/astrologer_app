import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/illustrations/verification_success_illustration.dart';

class VerificationSubmittedCelebrationScreen extends StatelessWidget {
  const VerificationSubmittedCelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Create gradient colors based on theme
        final gradientColors = _getGradientColors(themeService);
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Beautiful animated illustration
                    const VerificationSuccessIllustration(size: 280),
                    
                    const SizedBox(height: 48),
                    
                    // Success title
                    Text(
                      'Documents Submitted!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeService.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Success message
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
                    
                    const Spacer(),
                    
                    // Done button with purple
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate back to profile (pop 3 times: celebration -> upload -> requirements)
                          Navigator.of(context)
                            ..pop()
                            ..pop()
                            ..pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Secondary button - subtle
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                          ..pop()
                          ..pop()
                          ..pop();
                      },
                      child: Text(
                        'Back to Profile',
                        style: TextStyle(
                          fontSize: 15,
                          color: themeService.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(ThemeService themeService) {
    // Soft, elegant gradient inspired by the screenshot
    // Subtle purple-to-white gradient
    return [
      const Color(0xFFE8D5F2), // Soft purple/lavender at top
      const Color(0xFFF5F0FA), // Very light purple
      const Color(0xFFFFFFFF), // White at bottom
    ];
  }
}

