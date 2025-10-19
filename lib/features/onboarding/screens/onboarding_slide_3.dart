import 'package:flutter/material.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/community_growth_mockup.dart';

/// Third onboarding slide - Community Growth feature
/// Same design structure as Slide 2 (Gemini-style)
/// Content only - navigation handled by parent
class OnboardingSlide3 extends StatelessWidget {
  final double bottomPadding;

  const OnboardingSlide3({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: bottomPadding + 16,
          ),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64), // Spacing to maintain mockup position
                    
                    // Device mockup
                    Center(
                      child: DeviceMockupWidget(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                        borderColor: const Color(0xFF404040),
                        child: const CommunityGrowthMockup(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content section
                    const Text(
                      'Grow the Astrologer Community',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'Connect with fellow astrologers through discussions, share knowledge via live streaming, and build a thriving community. Collaborate, learn, and grow together on this platform.',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Learn more link
                    GestureDetector(
                      onTap: () {
                        // Could open a web link or show more info
                      },
                      child: const Text(
                        'Learn more',
                        style: TextStyle(
                          color: Color(0xFF89B4F8),
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF89B4F8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Instruction card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community features:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep(1, 'Start discussions on astrological topics'),
                          _buildInstructionStep(2, 'Go live to share your knowledge'),
                          _buildInstructionStep(3, 'Engage with other astrologers'),
                          _buildInstructionStep(4, 'Build your following and reputation'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer disclaimer
                    const Text(
                      '* Respectful discussions. Quality content. Build meaningful connections.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

