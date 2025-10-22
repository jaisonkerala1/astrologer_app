import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
                    const SizedBox(height: 64), // Spacing to maintain mockup position
                    
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
                    Text(
                      AppLocalizations.of(context)!.onboardingAstroGuruTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      AppLocalizations.of(context)!.onboardingAstroGuruDescription,
                      style: const TextStyle(
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
                      child: Text(
                        AppLocalizations.of(context)!.learnMore,
                        style: const TextStyle(
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
                          Text(
                            AppLocalizations.of(context)!.howToHelpOthers,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep(context, 1, AppLocalizations.of(context)!.helpStep1),
                          _buildInstructionStep(context, 2, AppLocalizations.of(context)!.helpStep2),
                          _buildInstructionStep(context, 3, AppLocalizations.of(context)!.helpStep3),
                          _buildInstructionStep(context, 4, AppLocalizations.of(context)!.helpStep4),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer disclaimer
                    Text(
                      AppLocalizations.of(context)!.astroGuruDisclaimer,
                      style: const TextStyle(
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

  Widget _buildInstructionStep(BuildContext context, int number, String text) {
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

