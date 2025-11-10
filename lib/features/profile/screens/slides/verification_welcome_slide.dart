import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../../../shared/widgets/verification_badge.dart';
import '../../../auth/models/astrologer_model.dart';

/// Welcome slide for verification flow - shows benefits and requirements
class VerificationWelcomeSlide extends StatelessWidget {
  final AstrologerModel astrologer;
  final bool isResubmission;

  const VerificationWelcomeSlide({
    super.key,
    required this.astrologer,
    this.isResubmission = false,
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
                // Badge Icon
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeService.primaryColor.withOpacity(0.1),
                        themeService.primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: VerificationBadge(
                    size: isSmallScreen ? 40 : 48,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Title
                Text(
                  isResubmission
                      ? 'Re-submit Verification'
                      : 'Become a Verified\nAstrologer',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 8 : 12),

                // Subtitle
                Text(
                  'Build trust and credibility with your clients',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: themeService.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                // Rejection reason (if resubmission)
                if (isResubmission &&
                    astrologer.verificationRejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Previous Rejection Reason',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                astrologer.verificationRejectionReason!,
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
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],

                // Why Get Verified?
                _buildBenefitsCard(themeService, isSmallScreen),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // What You'll Need
                _buildRequirementsCard(themeService, isSmallScreen),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Time estimate
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: themeService.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Takes only 2-3 minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 16,
                      color: themeService.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed in 24-48 hours',
                      style: TextStyle(
                        fontSize: 13,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitsCard(ThemeService themeService, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeService.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: themeService.primaryColor,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Why Get Verified?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildBenefitItem(
            Icons.verified,
            'Build Trust',
            'Verified badge shows you\'re authenticated',
            themeService,
            isSmallScreen,
          ),
          _buildBenefitItem(
            Icons.trending_up,
            'Higher Visibility',
            'Rank higher in search results',
            themeService,
            isSmallScreen,
          ),
          _buildBenefitItem(
            Icons.people,
            'More Bookings',
            'Clients prefer verified astrologers',
            themeService,
            isSmallScreen,
          ),
          _buildBenefitItem(
            Icons.workspace_premium,
            'Professional Badge',
            'Show commitment to quality',
            themeService,
            isSmallScreen,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    ThemeService themeService,
    bool isSmallScreen, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isSmallScreen ? 10 : 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: themeService.primaryColor,
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(ThemeService themeService, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeService.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: themeService.primaryColor,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'What You\'ll Need',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildRequirementItem(
            Icons.badge,
            'Government ID Proof',
            true,
            themeService,
            isSmallScreen,
          ),
          _buildRequirementItem(
            Icons.workspace_premium,
            'Astrology Certificate',
            false,
            themeService,
            isSmallScreen,
          ),
          _buildRequirementItem(
            Icons.store,
            'Storefront/Workspace Photo',
            false,
            themeService,
            isSmallScreen,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    IconData icon,
    String title,
    bool isRequired,
    ThemeService themeService,
    bool isSmallScreen, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isSmallScreen ? 10 : 12)),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeService.textSecondary,
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                color: themeService.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRequired
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isRequired ? Colors.red : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

