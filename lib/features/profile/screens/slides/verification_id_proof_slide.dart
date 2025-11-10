import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../widgets/verification_upload_card.dart';

/// ID Proof upload slide - mandatory document
class VerificationIdProofSlide extends StatelessWidget {
  final File? image;
  final Function(File) onImagePicked;
  final VoidCallback onImageRemoved;
  final bool isResubmission;
  final String? rejectionReason;

  const VerificationIdProofSlide({
    super.key,
    required this.image,
    required this.onImagePicked,
    required this.onImageRemoved,
    this.isResubmission = false,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Responsive sizing
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenHeight < 700;
        final horizontalPadding = screenWidth > 600 ? 48.0 : 24.0;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: isSmallScreen ? 16 : 32,
              bottom: 120, // Space for navigation
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge,
                    size: isSmallScreen ? 40 : 48,
                    color: themeService.primaryColor,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Title
                Text(
                  'Government ID Proof',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 6 : 8),

                // Subtitle with Required tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Required for verification',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Accepted documents - minimal flat design
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepted Documents',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                          color: themeService.textSecondary,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDocumentChip('Aadhaar', themeService),
                          _buildDocumentChip('PAN', themeService),
                          _buildDocumentChip('Passport', themeService),
                          _buildDocumentChip('Driver\'s License', themeService),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Upload card
                VerificationUploadCard(
                  image: image,
                  onImagePicked: onImagePicked,
                  onImageRemoved: onImageRemoved,
                  themeService: themeService,
                  documentType: 'ID Proof',
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Why required info
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why is this required?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Identity verification ensures authenticity and builds client trust. Your information is kept secure and confidential.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeService.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentChip(String text, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: themeService.textPrimary,
        ),
      ),
    );
  }
}

