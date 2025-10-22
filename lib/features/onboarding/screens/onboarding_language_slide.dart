import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/language_selection_mockup.dart';
import '../../../core/services/language_service.dart';

/// Language selection onboarding slide
/// Allows users to choose between English and Hindi
class OnboardingLanguageSlide extends StatefulWidget {
  final double bottomPadding;

  const OnboardingLanguageSlide({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  State<OnboardingLanguageSlide> createState() => _OnboardingLanguageSlideState();
}

class _OnboardingLanguageSlideState extends State<OnboardingLanguageSlide> {
  String _selectedLanguage = 'en'; // Default

  @override
  void initState() {
    super.initState();
    // Get current language from service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      setState(() {
        _selectedLanguage = languageService.currentLanguageCode;
      });
    });
  }

  void _onLanguageSelected(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // Update language immediately - we'll handle the rebuild separately
    final languageService = Provider.of<LanguageService>(context, listen: false);
    await languageService.setLanguage(languageCode);
  }

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
            bottom: widget.bottomPadding + 16,
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
                  child: LanguageSelectionMockup(
                    selectedLanguage: _selectedLanguage,
                    onLanguageSelected: _onLanguageSelected,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Content section
              Text(
                AppLocalizations.of(context)!.chooseYourLanguage,
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
                AppLocalizations.of(context)!.chooseLanguageDescription,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

