import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/onboarding_navigation.dart';
import 'onboarding_slide_1.dart';
import 'onboarding_slide_2.dart';
import 'onboarding_slide_3.dart';
import 'onboarding_slide_4.dart';

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
    print('🗑️ [ONBOARDING] OnboardingScreen disposing');
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 3) {
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
    // Mark onboarding as seen
    await _storageService.setHasSeenOnboarding(true);
    print('OnboardingScreen: Onboarding completed, navigating to login');

    if (!mounted) return;

    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
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
              
              // Slide 2: AstroGuru healing platform (content only)
              OnboardingSlide2(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 3: Earnings dashboard (swapped with slide 4)
              OnboardingSlide4(
                bottomPadding: _navigationHeight,
              ),
              
              // Slide 4: Live consultations (swapped with slide 3)
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
                  totalPages: 4,
                  onBack: _goToPreviousPage,
                  onNext: _currentPage == 3 ? _completeOnboarding : _goToNextPage,
                  nextButtonText: _currentPage == 3 ? 'Get Started' : 'Next',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

