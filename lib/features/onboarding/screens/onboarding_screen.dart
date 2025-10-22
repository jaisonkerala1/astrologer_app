import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/language_service.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/models/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/onboarding_navigation.dart';
import 'onboarding_slide_1.dart';
import 'onboarding_language_slide.dart';
import 'onboarding_theme_slide.dart';
import 'onboarding_slide_2.dart';
import 'onboarding_slide_3.dart';
import 'onboarding_slide_4.dart';
import 'package:provider/provider.dart';

/// Main onboarding screen with PageView controller
/// Manages navigation between onboarding slides and completion flow
/// Uses fixed navigation at bottom for smoother transitions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() {
    print('🎬 [ONBOARDING] Creating OnboardingScreen state');
    return _OnboardingScreenState();
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final StorageService _storageService = StorageService();
  
  // Navigation height for content padding
  static const double _navigationHeight = 100.0;

  @override
  void initState() {
    super.initState();
    print('🎬 [ONBOARDING] OnboardingScreen initState called');
    print('✅ [ONBOARDING] OnboardingScreen is now VISIBLE and ACTIVE');
  }

  @override
  void dispose() {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║      🗑️ ONBOARDING SCREEN DISPOSING                   ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Current Page: $_currentPage');
    print('║ Total Pages: 6');
    print('║ Completed: ${_currentPage == 5}');
    print('║ Timestamp: ${DateTime.now()}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 5) { // Now we have 6 slides (0-5)
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║      ✅ COMPLETING ONBOARDING                         ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Current Page: $_currentPage');
    print('║ Timestamp: ${DateTime.now()}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    
    // Apply defaults if user didn't select
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    // Ensure language is set (default to English if not already set)
    if (languageService.currentLanguageCode.isEmpty) {
      print('⚙️ [ONBOARDING] Setting default language to English');
      await languageService.setLanguage('en');
    } else {
      print('✅ [ONBOARDING] Language already set: ${languageService.currentLanguageCode}');
    }
    
    // Ensure theme is set (will use Vedic default from service)
    if (!themeService.isInitialized) {
      print('⚙️ [ONBOARDING] Initializing theme service');
      await themeService.initialize();
    } else {
      print('✅ [ONBOARDING] Theme already initialized: ${themeService.currentTheme}');
    }
    
    // Mark onboarding as seen
    print('💾 [ONBOARDING] Marking onboarding as completed in storage');
    await _storageService.setHasSeenOnboarding(true);
    
    // Verify it was saved
    final hasSeenOnboarding = await _storageService.getHasSeenOnboarding();
    print('✅ [ONBOARDING] Verified hasSeenOnboarding: $hasSeenOnboarding');
    
    print('🧭 [ONBOARDING] Navigating to LOGIN screen');

    if (!mounted) {
      print('❌ [ONBOARDING] Widget not mounted, aborting navigation');
      return;
    }

    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    
    print('✅ [ONBOARDING] Navigation to login triggered');
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [ONBOARDING] Building OnboardingScreen widget (page $_currentPage)');
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Content that slides
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Slide 1: Welcome screen (has its own button, no fixed nav needed)
              OnboardingSlide1(
                onNext: _goToNextPage,
                onClose: _skipOnboarding,
              ),
              
              // Slide 2: Language selection (NEW)
              OnboardingLanguageSlide(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 3: Theme selection (NEW)
              OnboardingThemeSlide(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 4: AstroGuru healing platform (content only)
              OnboardingSlide2(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 5: Earnings dashboard
              OnboardingSlide4(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 6: Community/Live consultations
              OnboardingSlide3(
                bottomPadding: _navigationHeight,
              ),
            ],
          ),
          
          // Fixed navigation at bottom (only show for slides 2, 3, 4)
          if (_currentPage > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A1A).withOpacity(0.0),
                      const Color(0xFF1A1A1A).withOpacity(0.95),
                      const Color(0xFF1A1A1A),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: OnboardingNavigation(
                  currentPage: _currentPage,
                  totalPages: 6, // Updated to 6 slides
                  onBack: _goToPreviousPage,
                  onNext: _currentPage == 5 ? _completeOnboarding : _goToNextPage,
                  nextButtonText: _currentPage == 5 ? 'Get Started' : 'Next',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

