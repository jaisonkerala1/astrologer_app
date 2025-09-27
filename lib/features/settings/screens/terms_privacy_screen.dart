import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Terms & Privacy'),
            backgroundColor: themeService.surfaceColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: themeService.primaryColor,
              labelColor: themeService.primaryColor,
              unselectedLabelColor: themeService.textSecondary,
              tabs: const [
                Tab(text: 'Terms of Service'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTermsContent(themeService),
              _buildPrivacyContent(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsContent(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Terms of Service',
            'Last updated: January 1, 2025',
            Icons.description_outlined,
            themeService,
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            '1. Acceptance of Terms',
            'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
            themeService,
          ),
          
          _buildSection(
            '2. Use License',
            'Permission is granted to temporarily download one copy of the materials on this application for personal, non-commercial transitory viewing only.',
            themeService,
          ),
          
          _buildSection(
            '3. Disclaimer',
            'The materials on this application are provided on an \'as is\' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            themeService,
          ),
          
          _buildSection(
            '4. Limitations',
            'In no event shall we or our suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on this application, even if we or our authorized representative has been notified orally or in writing of the possibility of such damage.',
            themeService,
          ),
          
          _buildSection(
            '5. Accuracy of Materials',
            'The materials appearing on this application could include technical, typographical, or photographic errors. We do not warrant that any of the materials on its website are accurate, complete, or current.',
            themeService,
          ),
          
          _buildSection(
            '6. Links',
            'We have not reviewed all of the sites linked to our application and are not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by us of the site.',
            themeService,
          ),
          
          _buildSection(
            '7. Modifications',
            'We may revise these terms of service for its application at any time without notice. By using this application, you are agreeing to be bound by the then current version of these terms of service.',
            themeService,
          ),
          
          _buildSection(
            '8. Company Information',
            'This application is operated by AXIOM LEAP. For any legal notices or correspondence, please contact us at support@axiomleap.com.',
            themeService,
          ),
          
          _buildSection(
            '9. Governing Law',
            'These terms and conditions are governed by and construed in accordance with the laws of India.',
            themeService,
          ),
          
          const SizedBox(height: 32),
          _buildWebsiteLink(themeService),
        ],
      ),
    );
  }

  Widget _buildPrivacyContent(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Privacy Policy',
            'Last updated: January 1, 2025',
            Icons.privacy_tip_outlined,
            themeService,
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            '1. Information We Collect',
            'We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support. This may include your name, email address, phone number, and other information you choose to provide.',
            themeService,
          ),
          
          _buildSection(
            '2. How We Use Your Information',
            'We use the information we collect to provide, maintain, and improve our services, process transactions, send you technical notices and support messages, and communicate with you about products, services, and promotional offers.',
            themeService,
          ),
          
          _buildSection(
            '3. Information Sharing',
            'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this privacy policy or as required by law.',
            themeService,
          ),
          
          _buildSection(
            '4. Data Security',
            'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.',
            themeService,
          ),
          
          _buildSection(
            '5. Data Retention',
            'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this privacy policy, unless a longer retention period is required or permitted by law.',
            themeService,
          ),
          
          _buildSection(
            '6. Your Rights',
            'You have the right to access, update, or delete your personal information. You may also have the right to restrict or object to certain processing of your information.',
            themeService,
          ),
          
          _buildSection(
            '7. Cookies and Tracking',
            'We use cookies and similar tracking technologies to collect and use personal information about you. You can control cookies through your browser settings.',
            themeService,
          ),
          
          _buildSection(
            '8. Children\'s Privacy',
            'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            themeService,
          ),
          
          _buildSection(
            '9. Changes to This Policy',
            'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date.',
            themeService,
          ),
          
          _buildSection(
            '10. Company Information',
            'This application is operated by AXIOM LEAP. We are committed to protecting your privacy and ensuring the security of your personal information.',
            themeService,
          ),
          
          _buildSection(
            '11. Contact Us',
            'If you have any questions about this privacy policy or our data practices, please contact us at support@axiomleap.com.',
            themeService,
          ),
          
          const SizedBox(height: 32),
          _buildWebsiteLink(themeService),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle, IconData icon, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.1),
            themeService.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: themeService.primaryColor,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildSection(String title, String content, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
      ),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteLink(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.language,
            size: 32,
            color: themeService.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Visit our website for more information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeService.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'www.axiomleap.com',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeService.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AXIOM LEAP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _launchWebsite,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Website'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchWebsite() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Website: www.axiomleap.com'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
