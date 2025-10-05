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
          
          // CRITICAL DISCLAIMER - PROMINENT
          _buildCriticalDisclaimer(themeService),
          const SizedBox(height: 24),
          
          _buildSection(
            '1. Acceptance of Terms',
            'By accessing and using this application ("Platform"), you accept and agree to be bound by these terms and conditions. If you do not agree to these terms, please do not use the Platform. Your continued use of the Platform constitutes acceptance of any modifications to these terms.',
            themeService,
          ),
          
          _buildSection(
            '2. Use License',
            'Permission is granted to temporarily download one copy of the materials on this Platform for personal, non-commercial transitory viewing only. This license shall automatically terminate if you violate any of these restrictions and may be terminated by AXIOM LEAP at any time.',
            themeService,
          ),
          
          // NEW: PLATFORM NATURE
          _buildHighlightedSection(
            '2A. Platform Nature & Intermediary Status',
            'AXIOM LEAP operates as an intermediary platform under the Information Technology Act, 2000, Section 79. We are a technology service provider that:\n\n'
            '• Facilitates connections between users and independent astrologers\n'
            '• Provides a digital marketplace for astrology services\n'
            '• Does NOT provide astrology services directly\n'
            '• Does NOT employ astrologers as staff members\n'
            '• Acts solely as a technical facilitator and aggregator\n'
            '• Does NOT endorse, verify, or guarantee any astrologer or their predictions\n\n'
            'All astrology services are provided by independent third-party professionals who register on our Platform.',
            themeService,
            Icons.info_outline,
          ),
          
          // NEW: ASTROLOGER LIABILITY - MOST CRITICAL
          _buildHighlightedSection(
            '2B. Astrologer Services & Liability',
            'INDEPENDENT PROFESSIONAL SERVICES:\n'
            'All astrologers on this Platform are independent professionals who are solely and exclusively responsible for:\n\n'
            '• Their predictions, readings, interpretations, and opinions\n'
            '• The accuracy, quality, and reliability of their services\n'
            '• Professional advice, guidance, and recommendations provided\n'
            '• Methods, techniques, and calculations used in their practice\n'
            '• Any consequences arising from their services or advice\n'
            '• Compliance with applicable professional and ethical standards\n'
            '• Their own professional liability and insurance\n\n'
            'PLATFORM\'S LIMITED ROLE:\n'
            'The Platform:\n'
            '• Has NO control over the content of astrology services\n'
            '• Does NOT validate, verify, or certify predictions or advice\n'
            '• Does NOT supervise astrologer-user interactions\n'
            '• Is NOT responsible for the quality or accuracy of services\n'
            '• Cannot guarantee any outcomes or results\n'
            '• Does NOT participate in service delivery\n\n'
            'Users engage with astrologers entirely at their own discretion and risk. The Platform is not liable for any astrologer\'s actions, advice, or predictions.',
            themeService,
            Icons.warning_amber_outlined,
          ),
          
          // NEW: NATURE OF ASTROLOGY
          _buildHighlightedSection(
            '2C. Nature of Astrology Services',
            'IMPORTANT UNDERSTANDING:\n'
            'Users acknowledge and understand that:\n\n'
            '• Astrology is a BELIEF-BASED and INTERPRETATIVE practice\n'
            '• Predictions are OPINIONS and INTERPRETATIONS, not facts or guarantees\n'
            '• Results depend on individual belief, faith, and interpretation\n'
            '• Services are for GUIDANCE and ENTERTAINMENT purposes only\n'
            '• Astrological advice is NOT a substitute for professional medical, legal, financial, or psychological advice\n'
            '• No astrologer can guarantee specific outcomes or events\n'
            '• Past performance or testimonials do not guarantee future results\n\n'
            'The Platform provides NO WARRANTY regarding:\n'
            '• Accuracy of predictions or readings\n'
            '• Effectiveness of remedies or solutions\n'
            '• Outcomes of following astrological advice\n'
            '• Timing or occurrence of predicted events',
            themeService,
            Icons.psychology_outlined,
          ),
          
          // NEW: USER ACKNOWLEDGMENT
          _buildHighlightedSection(
            '2D. User Acknowledgment & Consent',
            'BY USING THIS PLATFORM, YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT:\n\n'
            '1. You are engaging with INDEPENDENT ASTROLOGERS, not the Platform\n'
            '2. The Platform is NOT RESPONSIBLE for any astrologer\'s advice, predictions, or actions\n'
            '3. You use all services ENTIRELY AT YOUR OWN RISK\n'
            '4. You will NOT make critical life decisions based solely on astrological predictions\n'
            '5. You will seek appropriate professional advice (medical, legal, financial) when needed\n'
            '6. The Platform is NOT LIABLE for any direct, indirect, incidental, consequential, or punitive damages\n'
            '7. You release the Platform from all claims arising from astrologer services\n'
            '8. You understand the speculative and belief-based nature of astrology\n\n'
            'This acknowledgment is a fundamental condition of using the Platform.',
            themeService,
            Icons.check_circle_outline,
          ),
          
          _buildSection(
            '3. Disclaimer (Enhanced)',
            'COMPREHENSIVE DISCLAIMER:\n\n'
            'The Platform and all materials are provided on an "AS IS" and "AS AVAILABLE" basis. We make NO WARRANTIES, expressed or implied, including but not limited to:\n\n'
            '• Merchantability or fitness for a particular purpose\n'
            '• Accuracy, reliability, or completeness of any content\n'
            '• Uninterrupted or error-free service\n'
            '• Quality or accuracy of astrologer services\n'
            '• Outcomes or results from using the Platform\n\n'
            'SPECIFIC ASTROLOGY DISCLAIMERS:\n'
            '• We do NOT guarantee the accuracy of any astrological predictions\n'
            '• We do NOT endorse any astrologer\'s methods or advice\n'
            '• We are NOT responsible for user-astrologer disputes\n'
            '• We do NOT verify astrologers\' qualifications or credentials\n'
            '• We do NOT control the quality of services provided\n\n'
            'We hereby disclaim and negate all warranties and conditions, and expressly exclude liability for any astrologer\'s predictions, advice, or services.',
            themeService,
          ),
          
          _buildSection(
            '4. Limitation of Liability (Enhanced)',
            'MAXIMUM LIABILITY PROTECTION:\n\n'
            'TO THE FULLEST EXTENT PERMITTED BY LAW:\n\n'
            'The Platform, its operators, directors, employees, and affiliates SHALL NOT BE LIABLE for any damages whatsoever, including but not limited to:\n\n'
            '• Direct, indirect, incidental, consequential, or punitive damages\n'
            '• Loss of profits, data, revenue, or business opportunities\n'
            '• Emotional distress or psychological harm\n'
            '• Financial losses from following astrological advice\n'
            '• Personal decisions made based on predictions\n'
            '• Damages arising from astrologer misconduct or negligence\n'
            '• Disputes between users and astrologers\n'
            '• Service interruptions or technical failures\n'
            '• Unauthorized access or data breaches\n\n'
            'This limitation applies even if we have been notified of the possibility of such damages. Our total liability, if any, shall not exceed the amount you paid to the Platform in the preceding 30 days.\n\n'
            'Some jurisdictions do not allow limitation of liability, so these limitations may not apply to you.',
            themeService,
          ),
          
          _buildSection(
            '5. Accuracy of Materials',
            'The materials appearing on this Platform, including astrologer profiles, descriptions, and user reviews, could include technical, typographical, or photographic errors. We do not warrant that any materials are accurate, complete, or current. We may make changes to materials at any time without notice. We do not commit to updating materials.',
            themeService,
          ),
          
          _buildSection(
            '6. Links to Third-Party Sites',
            'We have not reviewed all sites linked to our Platform and are not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by us. Use of any linked website is at the user\'s own risk.',
            themeService,
          ),
          
          _buildSection(
            '7. Modifications to Terms',
            'We reserve the right to revise these terms of service at any time without prior notice. By using this Platform, you agree to be bound by the then-current version of these terms. We encourage you to periodically review these terms. Your continued use after modifications constitutes acceptance of the revised terms.',
            themeService,
          ),
          
          // NEW: GRIEVANCE REDRESSAL
          _buildHighlightedSection(
            '8. Grievance Redressal Mechanism',
            'COMPLIANCE WITH IT ACT 2000:\n\n'
            'In accordance with the Information Technology Act, 2000 and Intermediary Guidelines and Digital Media Ethics Code Rules, 2021, we have appointed a Grievance Officer to address complaints.\n\n'
            'GRIEVANCE OFFICER DETAILS:\n'
            'Name: Grievance Redressal Officer\n'
            'Company: AXIOM LEAP\n'
            'Email: grievance@axiomleap.com\n'
            'Support Email: support@axiomleap.com\n\n'
            'COMPLAINT PROCESS:\n'
            '• Submit complaints via email with details\n'
            '• Include your user ID and issue description\n'
            '• We will acknowledge receipt within 24 hours\n'
            '• Resolution will be provided within 15 days as per IT Act requirements\n\n'
            'For urgent matters, you may also contact: support@axiomleap.com',
            themeService,
            Icons.support_agent_outlined,
          ),
          
          // NEW: PROHIBITED USES
          _buildSection(
            '9. Prohibited Uses',
            'You agree NOT to use the Platform for:\n\n'
            '• Any unlawful purpose or in violation of applicable laws\n'
            '• Harassing, abusing, or threatening astrologers or other users\n'
            '• Posting false, misleading, or defamatory content\n'
            '• Attempting to gain unauthorized access to the Platform\n'
            '• Reverse engineering or copying Platform features\n'
            '• Commercial purposes without written consent\n'
            '• Distributing viruses or harmful code\n'
            '• Impersonating others or providing false information\n'
            '• Violating intellectual property rights\n\n'
            'Violation of these terms may result in immediate account termination and legal action.',
            themeService,
          ),
          
          // NEW: REFUND & DISPUTE POLICY
          _buildSection(
            '10. Refund & Dispute Resolution',
            'REFUND POLICY:\n'
            '• Refund requests must be submitted within 24 hours of service\n'
            '• Each case is evaluated individually based on circumstances\n'
            '• Technical failures qualify for refunds; service dissatisfaction may not\n'
            '• Refunds are processed within 7-10 business days if approved\n\n'
            'DISPUTE RESOLUTION:\n'
            '• User-astrologer disputes should be resolved directly first\n'
            '• Platform may offer mediation but is not obligated to do so\n'
            '• Platform\'s mediation role is facilitative only, not binding\n'
            '• Platform decisions on disputes are final\n\n'
            'ARBITRATION:\n'
            '• Disputes with the Platform shall be resolved through arbitration in accordance with Indian Arbitration and Conciliation Act, 1996\n'
            '• Arbitration shall be conducted in [Your City], India\n'
            '• Language of arbitration: English',
            themeService,
          ),
          
          _buildSection(
            '11. Company Information',
            'This Platform is operated by:\n\n'
            'Company Name: AXIOM LEAP\n'
            'Business Type: Technology Service Provider / Intermediary Platform\n'
            'Primary Contact: support@axiomleap.com\n'
            'Grievance Officer: grievance@axiomleap.com\n'
            'Website: www.axiomleap.com\n\n'
            'For legal notices, correspondence, or official communication, please contact us at the above email addresses. We are committed to addressing your concerns promptly and professionally.',
            themeService,
          ),
          
          _buildSection(
            '12. Governing Law & Jurisdiction',
            'APPLICABLE LAW:\n'
            'These terms and conditions are governed by and construed in accordance with the laws of India, including but not limited to:\n\n'
            '• Information Technology Act, 2000 and amendments\n'
            '• Intermediary Guidelines and Digital Media Ethics Code Rules, 2021\n'
            '• Consumer Protection Act, 2019\n'
            '• Indian Contract Act, 1872\n'
            '• Other applicable Indian laws and regulations\n\n'
            'JURISDICTION:\n'
            '• Exclusive jurisdiction lies with the courts of [Your City], India\n'
            '• Any legal proceedings must be initiated in these courts only\n'
            '• You consent to the personal jurisdiction of these courts\n\n'
            'COMPLIANCE:\n'
            'We comply with all applicable Indian laws regarding data protection, consumer rights, and intermediary obligations.',
            themeService,
          ),
          
          _buildSection(
            '13. Intellectual Property Rights',
            'All content on the Platform, including but not limited to text, graphics, logos, icons, images, audio clips, video clips, and software, is the property of AXIOM LEAP or its content suppliers and is protected by Indian and international copyright, trademark, and other intellectual property laws.\n\n'
            'You may not reproduce, modify, distribute, or exploit any content without express written permission.',
            themeService,
          ),
          
          _buildSection(
            '14. Severability',
            'If any provision of these terms is held to be invalid, illegal, or unenforceable by a court of competent jurisdiction, such provision shall be modified to the minimum extent necessary to make it enforceable, or if it cannot be made enforceable, it shall be severed from these terms. The remaining provisions shall continue in full force and effect.',
            themeService,
          ),
          
          _buildSection(
            '15. Entire Agreement',
            'These terms of service, together with our Privacy Policy and any other legal notices or policies published by us on the Platform, constitute the entire agreement between you and AXIOM LEAP regarding the use of the Platform and supersede all prior agreements and understandings.',
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
            'Introduction',
            'AXIOM LEAP ("we", "our", "us") is committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, store, and protect your data when you use our Platform as an intermediary connecting users with independent astrologers.\n\n'
            'By using our Platform, you consent to the data practices described in this policy.',
            themeService,
          ),
          
          _buildSection(
            '1. Information We Collect',
            'PERSONAL INFORMATION:\n'
            'We collect information you provide directly to us, including:\n\n'
            '• Account Information: Name, email address, phone number, date of birth, profile photo\n'
            '• Birth Details: Date, time, and place of birth (for astrology services)\n'
            '• Identity Verification: Government ID, professional certificates (for astrologers)\n'
            '• Payment Information: Payment method details, transaction history\n'
            '• Communication Data: Messages, reviews, ratings, feedback\n'
            '• Preferences: Language, notification settings, service preferences\n\n'
            'AUTOMATICALLY COLLECTED INFORMATION:\n'
            '• Device information (device type, operating system, unique identifiers)\n'
            '• Usage data (features accessed, time spent, interaction patterns)\n'
            '• Location data (with your permission)\n'
            '• Log data (IP address, browser type, access times)\n'
            '• Cookies and tracking technologies',
            themeService,
          ),
          
          // NEW: DATA SHARING WITH ASTROLOGERS
          _buildHighlightedSection(
            '2. Data Shared with Astrologers',
            'IMPORTANT DISCLOSURE:\n\n'
            'As an intermediary platform, we share certain user information with astrologers to facilitate services:\n\n'
            'INFORMATION SHARED:\n'
            '• Your name and basic profile information\n'
            '• Birth details (date, time, place) for chart preparation\n'
            '• Contact information for service delivery\n'
            '• Questions or concerns you submit\n'
            '• Previous consultation history (with that astrologer)\n\n'
            'ASTROLOGER DATA HANDLING:\n'
            '• Astrologers are INDEPENDENT THIRD PARTIES\n'
            '• Each astrologer has their own data practices\n'
            '• We are NOT RESPONSIBLE for how astrologers use or store your data\n'
            '• Astrologers must comply with applicable privacy laws independently\n'
            '• We recommend reviewing astrologer-specific policies\n\n'
            'USER CONSENT:\n'
            'By using our services, you explicitly consent to sharing this information with astrologers for service delivery purposes.',
            themeService,
            Icons.share_outlined,
          ),
          
          _buildSection(
            '3. How We Use Your Information',
            'We use collected information for the following purposes:\n\n'
            'SERVICE PROVISION:\n'
            '• Facilitate connections between you and astrologers\n'
            '• Process and manage consultations and bookings\n'
            '• Enable communication between users and astrologers\n'
            '• Process payments and maintain transaction records\n'
            '• Provide customer support and resolve disputes\n\n'
            'PLATFORM IMPROVEMENT:\n'
            '• Analyze usage patterns and improve features\n'
            '• Develop new services and functionality\n'
            '• Conduct research and analytics\n'
            '• Test and troubleshoot technical issues\n\n'
            'COMMUNICATION:\n'
            '• Send service-related notifications and updates\n'
            '• Provide appointment reminders and confirmations\n'
            '• Share promotional offers (with your consent)\n'
            '• Request feedback and reviews\n\n'
            'LEGAL COMPLIANCE:\n'
            '• Comply with legal obligations and regulations\n'
            '• Enforce terms of service and policies\n'
            '• Prevent fraud and ensure platform security\n'
            '• Respond to legal requests and court orders',
            themeService,
          ),
          
          // NEW: INTERMEDIARY STATUS IN PRIVACY
          _buildHighlightedSection(
            '4. Our Role as Intermediary',
            'PLATFORM\'S LIMITED DATA PROCESSING:\n\n'
            'As a technology intermediary under IT Act 2000:\n\n'
            '• We process data ONLY to facilitate services\n'
            '• We do NOT analyze or use consultation content\n'
            '• We do NOT sell your personal data to third parties\n'
            '• Our data processing is limited to technical operations\n\n'
            'THIRD-PARTY ASTROLOGERS:\n'
            '• Astrologers are independent data controllers\n'
            '• They are responsible for their own data practices\n'
            '• We cannot control their data handling\n'
            '• They must comply with privacy laws independently\n\n'
            'PLATFORM RESPONSIBILITY:\n'
            '• We are responsible ONLY for data on our servers\n'
            '• We ensure security of Platform-stored data\n'
            '• We are NOT liable for astrologer data breaches',
            themeService,
            Icons.security_outlined,
          ),
          
          _buildSection(
            '5. Information Sharing & Disclosure',
            'We do not sell, trade, or rent your personal information to third parties. However, we may share information in the following circumstances:\n\n'
            'WITH ASTROLOGERS:\n'
            '• Necessary information to provide requested services\n'
            '• Birth details and consultation requests\n'
            '• Communication for service delivery\n\n'
            'WITH SERVICE PROVIDERS:\n'
            '• Payment processors for transaction handling\n'
            '• Cloud hosting providers for data storage\n'
            '• Analytics services for platform improvement\n'
            '• Communication services for notifications\n\n'
            'LEGAL REQUIREMENTS:\n'
            '• Compliance with laws, regulations, or court orders\n'
            '• Response to lawful government requests\n'
            '• Protection of our rights and property\n'
            '• Investigation of fraud or security issues\n\n'
            'BUSINESS TRANSFERS:\n'
            '• In case of merger, acquisition, or asset sale\n'
            '• With your continued consent after notification\n\n'
            'WITH YOUR CONSENT:\n'
            '• Any other sharing with your explicit permission',
            themeService,
          ),
          
          _buildSection(
            '6. Data Security',
            'We implement comprehensive security measures to protect your personal information:\n\n'
            'TECHNICAL SAFEGUARDS:\n'
            '• Encryption of data in transit (SSL/TLS)\n'
            '• Encryption of sensitive data at rest\n'
            '• Secure authentication mechanisms\n'
            '• Regular security audits and updates\n'
            '• Firewall and intrusion detection systems\n\n'
            'ORGANIZATIONAL MEASURES:\n'
            '• Restricted access to personal data (need-to-know basis)\n'
            '• Employee training on data protection\n'
            '• Confidentiality agreements with staff and vendors\n'
            '• Incident response and breach notification procedures\n\n'
            'LIMITATIONS:\n'
            'However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security. You are responsible for maintaining the confidentiality of your account credentials.',
            themeService,
          ),
          
          _buildSection(
            '7. Data Retention',
            'We retain your personal information for as long as necessary to:\n\n'
            '• Provide our services to you\n'
            '• Comply with legal obligations (tax, accounting, auditing)\n'
            '• Resolve disputes and enforce agreements\n'
            '• Maintain records as required by law\n\n'
            'RETENTION PERIODS:\n'
            '• Active account data: Retained while account is active\n'
            '• Transaction records: 7 years (as per Indian financial regulations)\n'
            '• Communication logs: 90 days (unless required for disputes)\n'
            '• Deleted account data: 30 days (for recovery) then permanently deleted\n\n'
            'You may request deletion of your account and data, subject to legal retention requirements.',
            themeService,
          ),
          
          _buildSection(
            '8. Your Rights & Choices',
            'You have the following rights regarding your personal information:\n\n'
            'ACCESS & PORTABILITY:\n'
            '• Request a copy of your personal data\n'
            '• Export your data in a portable format\n'
            '• View your profile and account information anytime\n\n'
            'CORRECTION & UPDATE:\n'
            '• Update your profile information through settings\n'
            '• Correct inaccurate or incomplete data\n'
            '• Request correction of information we hold\n\n'
            'DELETION & ERASURE:\n'
            '• Delete your account at any time\n'
            '• Request removal of specific information\n'
            '• Right to be forgotten (subject to legal exceptions)\n\n'
            'CONSENT WITHDRAWAL:\n'
            '• Opt out of marketing communications\n'
            '• Disable location tracking\n'
            '• Revoke data sharing permissions\n\n'
            'RESTRICTION & OBJECTION:\n'
            '• Restrict processing of your data\n'
            '• Object to certain uses of your information\n'
            '• Lodge complaints with data protection authorities\n\n'
            'To exercise these rights, contact us at support@axiomleap.com',
            themeService,
          ),
          
          _buildSection(
            '9. Cookies & Tracking Technologies',
            'We use cookies and similar tracking technologies to:\n\n'
            'ESSENTIAL COOKIES:\n'
            '• Maintain your session and login status\n'
            '• Remember your preferences and settings\n'
            '• Enable core Platform functionality\n\n'
            'ANALYTICS COOKIES:\n'
            '• Understand how you use the Platform\n'
            '• Analyze traffic and usage patterns\n'
            '• Improve user experience and performance\n\n'
            'MARKETING COOKIES:\n'
            '• Deliver personalized content and offers\n'
            '• Track campaign effectiveness\n'
            '• Provide targeted advertisements\n\n'
            'COOKIE MANAGEMENT:\n'
            'You can control cookies through your browser settings. However, disabling cookies may limit Platform functionality. Most browsers allow you to:\n'
            '• View and delete cookies\n'
            '• Block third-party cookies\n'
            '• Receive notifications when cookies are set\n'
            '• Clear cookies when closing the browser',
            themeService,
          ),
          
          _buildSection(
            '10. Children\'s Privacy',
            'Our Platform is NOT intended for children under 18 years of age.\n\n'
            '• We do not knowingly collect personal information from minors\n'
            '• We require users to be 18+ to create accounts\n'
            '• Parents/guardians must consent for users under 18\n'
            '• If we discover data from a child under 18, we will delete it promptly\n\n'
            'If you believe a child has provided us with information, please contact us immediately at support@axiomleap.com so we can take appropriate action.',
            themeService,
          ),
          
          _buildSection(
            '11. International Data Transfers',
            'Your information may be transferred to and processed in countries other than India:\n\n'
            '• We use cloud services that may store data internationally\n'
            '• All transfers comply with applicable data protection laws\n'
            '• We ensure adequate safeguards for international transfers\n'
            '• Data is primarily stored in India or countries with adequate protection\n\n'
            'By using our Platform, you consent to such transfers.',
            themeService,
          ),
          
          _buildSection(
            '12. Changes to This Privacy Policy',
            'We may update this Privacy Policy from time to time to reflect:\n\n'
            '• Changes in our practices or services\n'
            '• Legal or regulatory requirements\n'
            '• Technological developments\n'
            '• User feedback and industry best practices\n\n'
            'NOTIFICATION:\n'
            '• Material changes will be notified via email or Platform notification\n'
            '• Updated "Last updated" date will be posted\n'
            '• Continued use after changes constitutes acceptance\n'
            '• You are encouraged to review this policy periodically\n\n'
            'For significant changes, we may require explicit consent before the changes take effect.',
            themeService,
          ),
          
          _buildSection(
            '13. Grievance Redressal',
            'For privacy-related concerns or complaints:\n\n'
            'GRIEVANCE OFFICER:\n'
            'Name: Grievance Redressal Officer\n'
            'Company: AXIOM LEAP\n'
            'Email: grievance@axiomleap.com\n'
            'Support Email: support@axiomleap.com\n\n'
            'RESPONSE TIME:\n'
            '• Acknowledgment within 24 hours\n'
            '• Resolution within 15 days (as per IT Act 2000)\n'
            '• Escalation process for unresolved complaints\n\n'
            'You also have the right to lodge a complaint with data protection authorities.',
            themeService,
          ),
          
          _buildSection(
            '14. Contact Information',
            'For questions, concerns, or requests regarding this Privacy Policy or your personal information:\n\n'
            'Company: AXIOM LEAP\n'
            'Email: support@axiomleap.com\n'
            'Grievance Officer: grievance@axiomleap.com\n'
            'Website: www.axiomleap.com\n\n'
            'We are committed to addressing your concerns promptly and professionally.',
            themeService,
          ),
          
          _buildSection(
            '15. Legal Compliance',
            'This Privacy Policy complies with:\n\n'
            '• Information Technology Act, 2000, Section 43A\n'
            '• Information Technology (Reasonable Security Practices) Rules, 2011\n'
            '• Intermediary Guidelines and Digital Media Ethics Code Rules, 2021\n'
            '• Consumer Protection Act, 2019\n'
            '• Other applicable Indian privacy and data protection laws\n\n'
            'We are committed to maintaining the highest standards of data protection and privacy.',
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

  // CRITICAL DISCLAIMER - Prominent visual treatment
  Widget _buildCriticalDisclaimer(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.15),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 28,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '⚠️ IMPORTANT DISCLAIMER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'PLEASE READ CAREFULLY:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This platform is an INTERMEDIARY that connects users with INDEPENDENT ASTROLOGERS. '
            'All predictions, readings, and advice are provided by individual astrologers who are '
            'SOLELY RESPONSIBLE for their services.\n\n'
            '• The platform does NOT endorse, verify, or guarantee any predictions\n'
            '• Astrology services are BELIEF-BASED and for GUIDANCE ONLY\n'
            '• Astrologers are independent professionals, not our employees\n'
            '• Users engage with astrologers ENTIRELY AT THEIR OWN RISK\n'
            '• The platform is NOT LIABLE for any consequences of astrological advice\n\n'
            'By using this platform, you acknowledge and accept these terms.',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Highlighted sections for critical legal content
  Widget _buildHighlightedSection(
    String title,
    String content,
    ThemeService themeService,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeService.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: themeService.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeService.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
              height: 1.6,
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
              height: 1.6,
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
