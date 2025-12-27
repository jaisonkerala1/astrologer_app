import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/di/service_locator.dart';
import '../../auth/models/astrologer_model.dart';
import 'slides/verification_welcome_slide.dart';
import 'slides/verification_id_proof_slide.dart';
import 'slides/verification_certificate_slide.dart';
import 'slides/verification_storefront_slide.dart';
import 'slides/verification_final_slide.dart';
import '../widgets/verification_navigation.dart';

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

  // Total pages: Welcome + 3 upload pages + final celebration
  static const int _totalPages = 5;

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

    try {
      // Prepare multipart form data
      final formData = FormData();
      
      // Add ID proof (required)
      formData.files.add(MapEntry(
        'idProof',
        await MultipartFile.fromFile(
          _idProofImage!.path,
          filename: 'id_proof.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
      
      // Add certificate (optional)
      if (_certificateImage != null) {
        formData.files.add(MapEntry(
          'certificate',
          await MultipartFile.fromFile(
            _certificateImage!.path,
            filename: 'certificate.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }
      
      // Add storefront (optional)
      if (_storefrontImage != null) {
        formData.files.add(MapEntry(
          'storefront',
          await MultipartFile.fromFile(
            _storefrontImage!.path,
            filename: 'storefront.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }

      // Call backend API
      final apiService = getIt<ApiService>();
      final response = await apiService.post(
        '/profile/verification/upload-documents',
        data: formData,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (response.data['success'] == true) {
          // Go to final celebration page
          _pageController.animateToPage(
            _totalPages - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      case 4: // Final celebration - always can proceed
        return true;
      default:
        return false;
    }
  }

  String get _nextButtonText {
    if (_currentPage == 0) return 'Start';
    if (_currentPage == 3) {
      // Storefront page
      return _storefrontImage != null ? 'Submit for Review' : 'Skip & Submit';
    }
    if (_currentPage == 4) {
      // Final celebration page
      return 'Done';
    }
    return 'Next';
  }

  bool get _showSkipButton {
    // Show skip only on Certificate page (not on Storefront which has Skip & Submit)
    return _currentPage == 2;
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

                  // Page 5: Final Celebration
                  const VerificationFinalSlide(),
                ],
              ),

              // Fixed navigation at bottom (hide on final celebration page)
              if (_currentPage < _totalPages - 1)
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

              // Done button for final celebration page
              if (_currentPage == _totalPages - 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.95),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate back to profile
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

