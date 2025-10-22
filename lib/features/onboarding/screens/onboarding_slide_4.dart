import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/earnings_dashboard_mockup.dart';

/// Fourth onboarding slide - Earnings Dashboard (Final screen)
/// Same design structure as Slide 2 (Gemini-style)
/// Content only - navigation handled by parent
class OnboardingSlide4 extends StatelessWidget {
  final double bottomPadding;

  const OnboardingSlide4({
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
                        child: const EarningsDashboardMockup(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content section
                    Text(
                      AppLocalizations.of(context)!.onboardingEarningsTitle,
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
                      AppLocalizations.of(context)!.onboardingEarningsDescription,
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
                            AppLocalizations.of(context)!.whatYouCanTrack,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep(context, 1, AppLocalizations.of(context)!.trackStep1),
                          _buildInstructionStep(context, 2, AppLocalizations.of(context)!.trackStep2),
                          _buildInstructionStep(context, 3, AppLocalizations.of(context)!.trackStep3),
                          _buildInstructionStep(context, 4, AppLocalizations.of(context)!.trackStep4),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer disclaimer
                    Text(
                      AppLocalizations.of(context)!.earningsDisclaimer,
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

