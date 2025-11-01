import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../../auth/models/astrologer_model.dart';
import 'verification_document_upload_screen.dart';

class VerificationRequirementsScreen extends StatelessWidget {
  final AstrologerModel astrologer;
  
  const VerificationRequirementsScreen({
    super.key,
    required this.astrologer,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Get Verified'),
            backgroundColor: themeService.cardColor,
            elevation: 0,
            iconTheme: IconThemeData(color: themeService.textPrimary),
            titleTextStyle: TextStyle(
              color: themeService.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(themeService),
                _buildBenefitsSection(themeService),
                _buildRequirementsSection(context, themeService),
                _buildActionButton(context, themeService),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeService.cardColor,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
            child: const VerificationBadge(size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Become a Verified Astrologer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Build trust and credibility with clients',
            style: TextStyle(
              fontSize: 15,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Get Verified?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.verified,
            'Build Trust',
            'Verified badge shows you\'re authenticated',
            themeService,
          ),
          _buildBenefitItem(
            Icons.trending_up,
            'Higher Visibility',
            'Rank higher in search results',
            themeService,
          ),
          _buildBenefitItem(
            Icons.people,
            'More Bookings',
            'Clients prefer verified astrologers',
            themeService,
          ),
          _buildBenefitItem(
            Icons.workspace_premium,
            'Professional Image',
            'Show commitment to quality service',
            themeService,
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
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: themeService.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildRequirementsSection(BuildContext context, ThemeService themeService) {
    // Calculate progress
    final requirements = _getRequirements();
    final completed = requirements.where((r) => r['completed'] == true).length;
    final total = requirements.length;
    final progress = completed / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: themeService.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          ...requirements.map((req) => _buildRequirementItem(
            req['icon'] as IconData,
            req['title'] as String,
            req['description'] as String,
            req['completed'] as bool,
            themeService,
          )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRequirements() {
    // Mock data - in real app, calculate from astrologer data
    return [
      {
        'icon': Icons.phone_android,
        'title': 'Phone Verified',
        'description': 'OTP verification completed',
        'completed': true,
      },
      {
        'icon': Icons.admin_panel_settings,
        'title': 'Admin Approved',
        'description': 'Account reviewed and approved',
        'completed': true,
      },
      {
        'icon': Icons.person,
        'title': 'Complete Profile',
        'description': '100% profile completion required',
        'completed': astrologer.bio.isNotEmpty && 
                     astrologer.specializations.isNotEmpty && 
                     astrologer.languages.isNotEmpty,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Complete 10 Consultations',
        'description': 'Minimum consultation requirement',
        'completed': false, // Mock - should check real consultation count
      },
      {
        'icon': Icons.star,
        'title': 'Maintain 4.5+ Rating',
        'description': 'Good service quality',
        'completed': true, // Mock - should check real rating
      },
      {
        'icon': Icons.badge,
        'title': 'Upload ID Proof',
        'description': 'Government-issued ID (Required)',
        'completed': astrologer.verificationStatus == 'pending' || 
                     astrologer.verificationStatus == 'approved',
      },
      {
        'icon': Icons.workspace_premium,
        'title': 'Upload Certificate or Storefront',
        'description': 'Certification or shop photo (Optional)',
        'completed': astrologer.verificationStatus == 'pending' || 
                     astrologer.verificationStatus == 'approved',
      },
    ];
  }

  Widget _buildRequirementItem(
    IconData icon,
    String title,
    String description,
    bool completed,
    ThemeService themeService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed 
            ? Colors.green.withOpacity(0.05)
            : themeService.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed 
              ? Colors.green.withOpacity(0.3)
              : themeService.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: completed ? Colors.green : themeService.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : themeService.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeService themeService) {
    final status = astrologer.verificationStatus;
    
    if (status == 'pending') {
      return _buildPendingButton(themeService);
    } else if (status == 'rejected') {
      return _buildResubmitButton(context, themeService);
    } else {
      return _buildStartButton(context, themeService);
    }
  }

  Widget _buildStartButton(BuildContext context, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationDocumentUploadScreen(
                  astrologer: astrologer,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start Verification Process',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResubmitButton(BuildContext context, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationDocumentUploadScreen(
                  astrologer: astrologer,
                  isResubmission: true,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Re-submit Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingButton(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Under Review',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

