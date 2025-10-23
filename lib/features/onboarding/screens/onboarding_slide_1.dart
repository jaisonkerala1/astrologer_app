import 'package:flutter/material.dart';
import '../widgets/abstract_illustration.dart';

/// First onboarding slide - Welcome screen with abstract illustration
/// Design: Android-style welcome with playful decorative elements
class OnboardingSlide1 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onClose;

  const OnboardingSlide1({
    super.key,
    required this.onNext,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const SizedBox(height: 60),
                
                // Astrology branding header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF34A853),
                      size: 32,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AstroGuru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Main heading
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Welcome to\nAstroGuru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Abstract illustration with device mockup
                const AbstractIllustration(),
                
                const Spacer(),
                
                // Primary CTA button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF89B4F8),
                        foregroundColor: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF89B4F8).withOpacity(0.3),
                      ),
                      child: const Text(
                        'Show me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
            
            // Close button (top right)
            if (onClose != null)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 28,
                  padding: const EdgeInsets.all(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
