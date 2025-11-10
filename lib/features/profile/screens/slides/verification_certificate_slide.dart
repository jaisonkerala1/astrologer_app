import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../widgets/verification_upload_card.dart';

/// Certificate upload slide - optional but recommended
class VerificationCertificateSlide extends StatelessWidget {
  final File? image;
  final Function(File) onImagePicked;
  final VoidCallback onImageRemoved;

  const VerificationCertificateSlide({
    super.key,
    required this.image,
    required this.onImagePicked,
    required this.onImageRemoved,
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
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: isSmallScreen ? 40 : 48,
                    color: Colors.orange,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Title
                Text(
                  'Astrology Certificate',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 6 : 8),

                // Subtitle with Optional tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Optional but recommended',
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Benefits card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeService.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: themeService.primaryColor,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Why Add This?',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.bold,
                              color: themeService.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      _buildBenefitItem(
                        '• Higher credibility with clients',
                        themeService,
                        isSmallScreen,
                      ),
                      _buildBenefitItem(
                        '• Stand out from other astrologers',
                        themeService,
                        isSmallScreen,
                      ),
                      _buildBenefitItem(
                        '• Professional edge in listings',
                        themeService,
                        isSmallScreen,
                      ),
                      _buildBenefitItem(
                        '• Client trust increases by 40%',
                        themeService,
                        isSmallScreen,
                        isLast: true,
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
                  documentType: 'Certificate',
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Don't have one info
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeService.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: themeService.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Don\'t have a certificate?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeService.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No worries! You can skip this and still get verified.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeService.textSecondary,
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

  Widget _buildBenefitItem(
    String text,
    ThemeService themeService,
    bool isSmallScreen, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isSmallScreen ? 6 : 8)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: themeService.textPrimary,
        ),
      ),
    );
  }
}

