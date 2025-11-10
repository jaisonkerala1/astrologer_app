import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../auth/models/astrologer_model.dart';
import 'slides/verification_welcome_slide.dart';
import 'slides/verification_id_proof_slide.dart';
import 'slides/verification_certificate_slide.dart';
import 'slides/verification_storefront_slide.dart';
import '../widgets/verification_navigation.dart';
import 'verification_submitted_celebration_screen.dart';

/// Main verification upload flow screen with page-by-page onboarding experience
/// Manages navigation between slides and document uploads
class VerificationUploadFlowScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final bool isResubmission;

  const VerificationUploadFlowScreen({
    super.key,
    required this.astrologer,
    this.isResubmission = false,
  });

  @override
  State<VerificationUploadFlowScreen> createState() =>
      _VerificationUploadFlowScreenState();
}

class _VerificationUploadFlowScreenState
    extends State<VerificationUploadFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Document states
  File? _idProofImage;
  File? _certificateImage;
  File? _storefrontImage;

  bool _isSubmitting = false;

  // Total pages: Welcome + 3 upload pages
  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitDocuments();
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

  void _skipToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitDocuments() async {
    // Validate that ID proof is uploaded
    if (_idProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload ID Proof (required)'),
          backgroundColor: Colors.red,
        ),
      );
      // Go back to ID proof page
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      // Navigate to celebration screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationSubmittedCelebrationScreen(),
        ),
      );
    }
  }

  bool get _canProceedFromCurrentPage {
    switch (_currentPage) {
      case 0: // Welcome page - always can proceed
        return true;
      case 1: // ID Proof - must have image
        return _idProofImage != null;
      case 2: // Certificate - optional, always can proceed
      case 3: // Storefront - optional, always can proceed
        return true;
      default:
        return false;
    }
  }

  String get _nextButtonText {
    if (_currentPage == 0) return 'Start';
    if (_currentPage == _totalPages - 1) {
      return _storefrontImage != null ? 'Submit for Review' : 'Skip & Submit';
    }
    return 'Next';
  }

  bool get _showSkipButton {
    // Show skip on optional pages (Certificate and Storefront)
    return _currentPage == 2 || _currentPage == 3;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
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
                physics: const NeverScrollableScrollPhysics(), // Only navigate via buttons
                children: [
                  // Page 1: Welcome & Benefits
                  VerificationWelcomeSlide(
                    astrologer: widget.astrologer,
                    isResubmission: widget.isResubmission,
                  ),

                  // Page 2: ID Proof Upload (Mandatory)
                  VerificationIdProofSlide(
                    image: _idProofImage,
                    onImagePicked: (file) {
                      setState(() => _idProofImage = file);
                    },
                    onImageRemoved: () {
                      setState(() => _idProofImage = null);
                    },
                    isResubmission: widget.isResubmission,
                    rejectionReason:
                        widget.astrologer.verificationRejectionReason,
                  ),

                  // Page 3: Certificate Upload (Optional)
                  VerificationCertificateSlide(
                    image: _certificateImage,
                    onImagePicked: (file) {
                      setState(() => _certificateImage = file);
                    },
                    onImageRemoved: () {
                      setState(() => _certificateImage = null);
                    },
                  ),

                  // Page 4: Storefront Upload (Optional)
                  VerificationStorefrontSlide(
                    image: _storefrontImage,
                    onImagePicked: (file) {
                      setState(() => _storefrontImage = file);
                    },
                    onImageRemoved: () {
                      setState(() => _storefrontImage = null);
                    },
                  ),
                ],
              ),

              // Fixed navigation at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VerificationNavigation(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onBack: _currentPage > 0 ? _goToPreviousPage : null,
                  onNext: _isSubmitting ? null : _goToNextPage,
                  onSkip: _showSkipButton ? _skipToNext : null,
                  nextButtonText: _nextButtonText,
                  nextEnabled: _canProceedFromCurrentPage && !_isSubmitting,
                  isLoading: _isSubmitting,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

