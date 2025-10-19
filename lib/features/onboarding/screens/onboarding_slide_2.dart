import 'package:flutter/material.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/astroguru_chat_mockup.dart';

/// Second onboarding slide - AstroGuru healing platform introduction
/// Shows a device mockup with chat interface and detailed feature description
/// Content only - navigation handled by parent
class OnboardingSlide2 extends StatelessWidget {
  final double bottomPadding;

  const OnboardingSlide2({
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
                    // Branding section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4285F4),
                                Color(0xFF34A853),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.spa,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AstroGuru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Device mockup
                    Center(
                      child: DeviceMockupWidget(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                        borderColor: const Color(0xFF404040),
                        child: const AstroGuruChatMockup(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content section
                    const Text(
                      'Heal and Help Others Through AstroGuru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Connect with people seeking guidance and help them heal through astrological wisdom. Share your knowledge, provide consultations, and make a positive impact on others\' lives through this platform.',
                          ),
                        ],
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
                            'How to help others:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep(1, 'Set your availability and expertise areas'),
                          _buildInstructionStep(2, 'Receive consultation requests from seekers'),
                          _buildInstructionStep(3, 'Provide guidance through calls or messages'),
                          _buildInstructionStep(4, 'Help heal and transform lives with your wisdom'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer disclaimer
                    const Text(
                      '* Professional guidance. Maintain confidentiality. Respect all seekers.',
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

