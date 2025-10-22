import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/theme_selection_mockup.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/models/app_theme.dart';

/// Theme selection onboarding slide
/// Allows users to choose between Light, Dark, and Vedic themes
class OnboardingThemeSlide extends StatefulWidget {
  final double bottomPadding;

  const OnboardingThemeSlide({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  State<OnboardingThemeSlide> createState() => _OnboardingThemeSlideState();
}

class _OnboardingThemeSlideState extends State<OnboardingThemeSlide> {
  AppThemeType _selectedTheme = AppThemeType.light; // Default

  @override
  void initState() {
    super.initState();
    // Get current theme from service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      setState(() {
        _selectedTheme = themeService.currentTheme.type;
      });
    });
  }

  void _onThemeSelected(AppThemeType themeType) async {
    setState(() {
      _selectedTheme = themeType;
    });
    
    // Immediately update the service - theme changes will be visible immediately
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.setTheme(themeType);
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
                  child: ThemeSelectionMockup(
                    selectedTheme: _selectedTheme,
                    onThemeSelected: _onThemeSelected,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Content section
              Text(
                AppLocalizations.of(context)!.chooseYourTheme,
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
                AppLocalizations.of(context)!.chooseThemeDescription,
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

