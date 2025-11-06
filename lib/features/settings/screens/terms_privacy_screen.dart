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
            'Astrologer Terms of Service',
            'Last updated: January 1, 2025',
            Icons.description_outlined,
            themeService,
          ),
          const SizedBox(height: 24),
          
          // CRITICAL ACKNOWLEDGMENT - PROMINENT
          _buildCriticalAcknowledgment(themeService),
          const SizedBox(height: 24),
          
          _buildSection(
            '1. Acceptance of Terms',
            'By registering and using this Platform as an astrologer ("Service Provider"), you accept and agree to be bound by these Astrologer Terms of Service. These terms constitute a legally binding agreement between you (the astrologer) and AXIOM LEAP. If you do not agree to these terms, you must not register or use the Platform.\n\n'
            'Your continued use of the Platform constitutes acceptance of any modifications to these terms.',
            themeService,
          ),
          
          // NEW: INDEPENDENT CONTRACTOR STATUS
          _buildHighlightedSection(
            '2. Independent Contractor Relationship',
            'PROFESSIONAL INDEPENDENCE:\n\n'
            'You acknowledge and agree that:\n\n'
            '• You are an INDEPENDENT CONTRACTOR, not an employee, partner, or agent of AXIOM LEAP\n'
            '• You provide astrology services in your own name and capacity\n'
            '• You have complete control over how you provide your services\n'
            '• You set your own rates, schedules, and service methods\n'
            '• You are responsible for your own taxes, insurance, and professional obligations\n'
            '• No employment relationship exists between you and the Platform\n'
            '• You have no authority to bind or represent AXIOM LEAP\n'
            '• You maintain your own independent business\n\n'
            'PLATFORM\'S ROLE:\n'
            'AXIOM LEAP operates as an intermediary platform under IT Act 2000, Section 79. We:\n'
            '• Provide technology to connect you with users seeking astrology services\n'
            '• Facilitate payments and communication\n'
            '• Do NOT control, supervise, or direct your professional services\n'
            '• Do NOT validate or certify your predictions or methods\n'
            '• Act solely as a marketplace facilitator',
            themeService,
            Icons.business_outlined,
          ),
          
          // NEW: ASTROLOGER'S PROFESSIONAL RESPONSIBILITY - MOST CRITICAL
          _buildHighlightedSection(
            '3. Your Professional Responsibility & Liability',
            'FULL PROFESSIONAL LIABILITY:\n\n'
            'As an independent astrology professional, YOU ARE SOLELY AND EXCLUSIVELY RESPONSIBLE FOR:\n\n'
            'SERVICE QUALITY:\n'
            '• All predictions, readings, interpretations, and opinions you provide\n'
            '• The accuracy, quality, and reliability of your astrology services\n'
            '• Professional advice, guidance, and recommendations you give\n'
            '• Methods, techniques, and calculations you use in your practice\n'
            '• Birth chart calculations and astrological analysis\n'
            '• Any remedies, solutions, or actions you suggest\n\n'
            'LEGAL LIABILITY:\n'
            '• Any and all consequences arising from your services or advice\n'
            '• Professional negligence or malpractice claims\n'
            '• Disputes with users regarding your services\n'
            '• Compliance with applicable laws and professional standards\n'
            '• Maintaining appropriate professional liability insurance (recommended)\n'
            '• Any legal action brought against you by users\n\n'
            'ETHICAL OBLIGATIONS:\n'
            '• Providing honest, genuine, and professional services\n'
            '• Not making guarantees about specific outcomes\n'
            '• Respecting user privacy and confidentiality\n'
            '• Not exploiting vulnerable users\n'
            '• Following ethical astrology practices\n\n'
            'PLATFORM DISCLAIMER:\n'
            'The Platform has NO control over, responsibility for, or liability regarding your professional services. Users engage with YOU directly, and all liability rests with YOU.',
            themeService,
            Icons.gavel_outlined,
          ),
          
          // NEW: INDEMNIFICATION - PROTECTING THE PLATFORM
          _buildHighlightedSection(
            '4. Indemnification & Hold Harmless',
            'MANDATORY INDEMNIFICATION:\n\n'
            'YOU AGREE TO INDEMNIFY, DEFEND, AND HOLD HARMLESS:\n'
            '• AXIOM LEAP and its directors, officers, employees, and affiliates\n'
            '• From and against ANY and ALL claims, damages, losses, liabilities, costs, and expenses (including legal fees)\n\n'
            'ARISING FROM OR RELATED TO:\n'
            '• Your astrology services, predictions, or advice\n'
            '• Any user complaints or disputes regarding your services\n'
            '• Your breach of these terms or applicable laws\n'
            '• Your professional negligence or misconduct\n'
            '• Any injury, loss, or damage suffered by users due to your services\n'
            '• Your violation of user rights or data protection laws\n'
            '• Any claims that your services were inaccurate or harmful\n'
            '• Tax obligations or employment-related claims\n\n'
            'LEGAL PROCEEDINGS:\n'
            '• You will defend AXIOM LEAP in any legal action brought against us due to your services\n'
            '• You will pay all settlements, judgments, and legal costs\n'
            '• AXIOM LEAP has the right to participate in defense at your expense\n\n'
            'This indemnification survives termination of your account.',
            themeService,
            Icons.shield_outlined,
          ),
          
          // NEW: SERVICE STANDARDS
          _buildSection(
            '5. Service Standards & Code of Conduct',
            'PROFESSIONAL STANDARDS:\n\n'
            'You agree to:\n\n'
            'QUALITY COMMITMENTS:\n'
            '• Provide professional, accurate, and timely services\n'
            '• Honor all accepted consultation bookings\n'
            '• Respond to user inquiries promptly\n'
            '• Maintain professional behavior at all times\n'
            '• Keep your availability calendar updated\n'
            '• Complete consultations within scheduled time\n\n'
            'PROHIBITED CONDUCT:\n'
            'You must NOT:\n'
            '• Make guaranteed predictions about specific outcomes\n'
            '• Provide medical, legal, or financial advice (unless licensed)\n'
            '• Exploit vulnerable or desperate users\n'
            '• Demand additional payments outside the Platform\n'
            '• Share user contact information with third parties\n'
            '• Engage in fraudulent or deceptive practices\n'
            '• Harass, abuse, or threaten users\n'
            '• Post false credentials or qualifications\n'
            '• Use bots or automated responses\n'
            '• Solicit users to move off-platform\n\n'
            'COMPLIANCE:\n'
            '• Follow all applicable laws and regulations\n'
            '• Respect user privacy and data protection laws\n'
            '• Maintain professional ethics\n'
            '• Cooperate with Platform investigations',
            themeService,
          ),
          
          // NEW: PAYMENT TERMS
          _buildSection(
            '6. Payment Terms & Commission',
            'PAYMENT STRUCTURE:\n\n'
            'COMMISSION:\n'
            '• The Platform charges a service fee/commission on each consultation\n'
            '• Commission rates are displayed in your dashboard\n'
            '• Commission covers technology, payment processing, and support\n'
            '• Rates may be updated with 30 days notice\n\n'
            'PAYOUTS:\n'
            '• Earnings are credited to your wallet after consultation completion\n'
            '• Minimum withdrawal threshold may apply\n'
            '• Withdrawals processed within 7-10 business days\n'
            '• You are responsible for providing valid bank details\n'
            '• Transaction fees may apply to withdrawals\n\n'
            'REFUNDS:\n'
            '• User refund requests are evaluated case-by-case\n'
            '• Justified refunds (technical issues) are processed without affecting you\n'
            '• Service quality disputes may result in refunds deducted from your earnings\n'
            '• Excessive refund requests may lead to account review\n\n'
            'TAXES:\n'
            '• You are solely responsible for all tax obligations\n'
            '• You must report income and pay taxes as per Indian laws\n'
            '• Platform does NOT withhold taxes (you are not our employee)\n'
            '• You may need to provide PAN/GST details',
            themeService,
          ),
          
          // NEW: DATA HANDLING BY ASTROLOGERS
          _buildHighlightedSection(
            '7. User Data Handling & Privacy Obligations',
            'DATA YOU RECEIVE:\n\n'
            'Through the Platform, you receive user personal information including:\n'
            '• Names and contact details\n'
            '• Birth details (date, time, place)\n'
            '• Questions and consultation history\n'
            '• Communication with users\n\n'
            'YOUR OBLIGATIONS:\n\n'
            'You MUST:\n'
            '• Use data ONLY for providing astrology services\n'
            '• Maintain strict confidentiality of user information\n'
            '• Protect data with reasonable security measures\n'
            '• Delete user data when no longer needed\n'
            '• Comply with IT Act 2000 Section 43A and data protection laws\n'
            '• Not share, sell, or misuse user data\n'
            '• Not contact users outside the Platform without consent\n'
            '• Not use data for marketing or other purposes\n\n'
            'YOU MUST NOT:\n'
            '• Store user data on insecure devices or platforms\n'
            '• Share user information with third parties\n'
            '• Use user data for any purpose other than consultations\n'
            '• Retain data longer than necessary\n\n'
            'CONSEQUENCES:\n'
            'Violation of data privacy obligations may result in:\n'
            '• Immediate account termination\n'
            '• Legal action under IT Act and other laws\n'
            '• You bearing full liability for data breaches\n'
            '• Criminal prosecution for serious violations',
            themeService,
            Icons.privacy_tip_outlined,
          ),
          
          _buildSection(
            '8. Intellectual Property',
            'YOUR CONTENT:\n'
            '• You retain ownership of your profile content, photos, and descriptions\n'
            '• By uploading content, you grant AXIOM LEAP a license to display it on the Platform\n'
            '• You represent that you own or have rights to all content you upload\n'
            '• You are responsible for not infringing others\' intellectual property\n\n'
            'PLATFORM PROPERTY:\n'
            '• AXIOM LEAP owns all Platform technology, code, and features\n'
            '• You may not copy, reverse engineer, or replicate Platform functionality\n'
            '• Platform trademarks and branding remain our property\n'
            '• You may use Platform branding only as permitted',
            themeService,
          ),
          
          _buildSection(
            '9. Account Suspension & Termination',
            'PLATFORM\'S RIGHT TO TERMINATE:\n\n'
            'We may suspend or terminate your account:\n\n'
            'IMMEDIATE TERMINATION (without notice) for:\n'
            '• Fraudulent or deceptive practices\n'
            '• Serious misconduct or user harassment\n'
            '• Violation of data privacy obligations\n'
            '• Criminal activity or illegal services\n'
            '• Multiple user complaints about service quality\n'
            '• Breach of professional standards\n\n'
            'WITH NOTICE for:\n'
            '• Repeated minor violations\n'
            '• Poor service ratings or excessive refunds\n'
            '• Inactive account (no services for 6+ months)\n'
            '• Non-compliance with Platform policies\n\n'
            'YOUR RIGHT TO TERMINATE:\n'
            '• You may close your account at any time\n'
            '• Must fulfill pending consultations before closure\n'
            '• Pending payments will be processed\n'
            '• Data retention as per legal requirements\n\n'
            'CONSEQUENCES OF TERMINATION:\n'
            '• Loss of access to Platform and earnings dashboard\n'
            '• Pending withdrawals processed (if no disputes)\n'
            '• User data must be deleted\n'
            '• Indemnification obligations survive termination',
            themeService,
          ),
          
          _buildSection(
            '10. Limitation of Platform Liability',
            'PLATFORM\'S LIMITED LIABILITY:\n\n'
            'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n\n'
            '• AXIOM LEAP provides the Platform "AS IS" without warranties\n'
            '• We do NOT guarantee uninterrupted service or freedom from errors\n'
            '• We are NOT responsible for disputes between you and users\n'
            '• We are NOT liable for lost earnings due to technical issues\n'
            '• We do NOT validate your qualifications or service quality\n'
            '• Our total liability to you shall not exceed the fees paid to you in the preceding 30 days\n\n'
            'NO LIABILITY FOR:\n'
            '• User complaints or negative reviews\n'
            '• Service quality disputes\n'
            '• Changes to Platform features or commission rates\n'
            '• Account suspension or termination\n'
            '• Third-party payment processor issues\n'
            '• Data breaches on your end\n'
            '• Your professional liability or legal costs',
            themeService,
          ),
          
          // NEW: GRIEVANCE REDRESSAL
          _buildHighlightedSection(
            '11. Grievance Redressal & Dispute Resolution',
            'FOR ASTROLOGER COMPLAINTS:\n\n'
            'If you have concerns about the Platform:\n\n'
            'GRIEVANCE OFFICER:\n'
            'Name: Grievance Redressal Officer\n'
            'Company: AXIOM LEAP\n'
            'Email: grievance@axiomleap.com\n'
            'Support Email: support@axiomleap.com\n\n'
            'PROCESS:\n'
            '• Submit complaints via email with details\n'
            '• Include your astrologer ID and issue description\n'
            '• Acknowledgment within 24 hours\n'
            '• Resolution within 15 days (as per IT Act 2000)\n\n'
            'USER COMPLAINTS AGAINST YOU:\n'
            '• Users may file complaints about your services\n'
            '• You will be notified and given opportunity to respond\n'
            '• Platform may investigate and request information\n'
            '• Repeated complaints may lead to account action\n'
            '• Platform decisions on complaints are final\n\n'
            'ARBITRATION:\n'
            '• Disputes with Platform resolved through arbitration\n'
            '• Governed by Indian Arbitration and Conciliation Act, 1996\n'
            '• Arbitration in [Your City], India\n'
            '• Language: English',
            themeService,
            Icons.support_agent_outlined,
          ),
          
          _buildSection(
            '12. Modifications to Terms',
            'We reserve the right to modify these terms at any time. Changes may include:\n\n'
            '• Commission rate adjustments\n'
            '• Policy updates and new requirements\n'
            '• Feature additions or removals\n'
            '• Compliance with new laws\n\n'
            'NOTIFICATION:\n'
            '• Material changes will be notified via email and Platform notification\n'
            '• 30 days notice for commission changes\n'
            '• Continued use after changes constitutes acceptance\n'
            '• If you disagree, you may terminate your account\n\n'
            'You are responsible for regularly reviewing these terms.',
            themeService,
          ),
          
          _buildSection(
            '13. Company Information',
            'This Platform is operated by:\n\n'
            'Company Name: AXIOM LEAP\n'
            'Business Type: Technology Service Provider / Intermediary Platform\n'
            'Primary Contact: support@axiomleap.com\n'
            'Grievance Officer: grievance@axiomleap.com\n'
            'Website: www.axiomleap.com\n\n'
            'For professional queries, payments, or support, contact us at the above emails.',
            themeService,
          ),
          
          _buildSection(
            '14. Governing Law & Jurisdiction',
            'APPLICABLE LAW:\n'
            'These terms are governed by the laws of India, including:\n\n'
            '• Information Technology Act, 2000 and amendments\n'
            '• Indian Contract Act, 1872\n'
            '• Income Tax Act, 1961\n'
            '• Consumer Protection Act, 2019\n'
            '• Other applicable Indian laws\n\n'
            'JURISDICTION:\n'
            '• Exclusive jurisdiction: Courts of [Your City], India\n'
            '• All legal proceedings must be in these courts\n'
            '• You consent to jurisdiction of these courts\n\n'
            'COMPLIANCE:\n'
            '• You must comply with all Indian laws\n'
            '• Professional licensing requirements (if applicable)\n'
            '• Tax obligations under Indian tax laws\n'
            '• Data protection and privacy laws',
            themeService,
          ),
          
          _buildSection(
            '15. Severability & Entire Agreement',
            'SEVERABILITY:\n'
            'If any provision is held invalid or unenforceable, it will be modified to the minimum extent necessary or severed. Remaining provisions remain in full effect.\n\n'
            'ENTIRE AGREEMENT:\n'
            'These terms, together with our Privacy Policy and other Platform policies, constitute the entire agreement between you and AXIOM LEAP regarding your use of the Platform as an astrologer.',
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
            'Astrologer Privacy Policy',
            'Last updated: January 1, 2025',
            Icons.privacy_tip_outlined,
            themeService,
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            'Introduction',
            'AXIOM LEAP ("we", "our", "us") is committed to protecting the privacy of astrologers who use our Platform. This Privacy Policy explains how we collect, use, store, and protect YOUR personal information as a service provider on our Platform.\n\n'
            'By registering as an astrologer, you consent to the data practices described in this policy.',
            themeService,
          ),
          
          _buildSection(
            '1. Information We Collect from Astrologers',
            'REGISTRATION & PROFILE INFORMATION:\n'
            '• Full name, date of birth, gender\n'
            '• Email address and phone number\n'
            '• Profile photo and bio\n'
            '• Professional qualifications and experience\n'
            '• Specializations and expertise areas\n'
            '• Languages spoken\n'
            '• Service rates and availability\n\n'
            'IDENTITY VERIFICATION:\n'
            '• Government-issued ID (Aadhaar, PAN, etc.)\n'
            '• Professional certificates or credentials\n'
            '• Background verification documents\n'
            '• Address proof\n\n'
            'FINANCIAL INFORMATION:\n'
            '• Bank account details for payouts\n'
            '• PAN card for tax purposes\n'
            '• GST number (if applicable)\n'
            '• Transaction history and earnings\n'
            '• Withdrawal requests and payment details\n\n'
            'SERVICE DATA:\n'
            '• Consultation history and records\n'
            '• User communications (chat, call logs)\n'
            '• Service ratings and reviews\n'
            '• Response times and availability\n'
            '• Refund requests and disputes\n\n'
            'DEVICE & USAGE DATA:\n'
            '• Device information (type, OS, identifiers)\n'
            '• App usage patterns and session duration\n'
            '• Location data (with permission)\n'
            '• Login times and IP addresses',
            themeService,
          ),
          
          _buildSection(
            '2. How We Use Your Information',
            'ACCOUNT MANAGEMENT:\n'
            '• Create and maintain your astrologer profile\n'
            '• Verify your identity and credentials\n'
            '• Display your services to users\n'
            '• Process your availability and bookings\n\n'
            'SERVICE FACILITATION:\n'
            '• Connect you with users seeking astrology services\n'
            '• Enable communication between you and users\n'
            '• Process consultation bookings and payments\n'
            '• Provide consultation platform (chat, call, video)\n\n'
            'PAYMENTS & FINANCIAL:\n'
            '• Calculate earnings and commission\n'
            '• Process payout requests to your bank account\n'
            '• Generate invoices and financial statements\n'
            '• Comply with tax regulations (reporting)\n\n'
            'PLATFORM IMPROVEMENT:\n'
            '• Analyze service quality and user satisfaction\n'
            '• Improve matching algorithms\n'
            '• Develop new features and functionality\n'
            '• Conduct performance analytics\n\n'
            'COMMUNICATION:\n'
            '• Send booking notifications and reminders\n'
            '• Provide earnings and payout updates\n'
            '• Share Platform updates and policy changes\n'
            '• Send promotional opportunities (with consent)\n'
            '• Customer support and assistance\n\n'
            'QUALITY & COMPLIANCE:\n'
            '• Monitor service quality and user feedback\n'
            '• Investigate user complaints\n'
            '• Ensure compliance with terms of service\n'
            '• Prevent fraud and abuse\n'
            '• Verify professional standards',
            themeService,
          ),
          
          // NEW: HOW USER DATA IS SHARED WITH ASTROLOGERS
          _buildHighlightedSection(
            '3. User Data Shared with You',
            'INFORMATION YOU RECEIVE:\n\n'
            'To facilitate consultations, we share user information with you:\n\n'
            'USER DETAILS:\n'
            '• User name and profile photo\n'
            '• Birth details (date, time, place) for chart preparation\n'
            '• Contact information (for consultation delivery)\n'
            '• Questions and consultation requests\n'
            '• Previous consultation history with you\n\n'
            'YOUR RESPONSIBILITIES:\n\n'
            'When handling user data, you MUST:\n'
            '• Use data ONLY for providing astrology services\n'
            '• Maintain strict confidentiality\n'
            '• Protect data with reasonable security\n'
            '• Delete data when no longer needed\n'
            '• Comply with IT Act 2000, Section 43A\n'
            '• Not share, sell, or misuse user data\n'
            '• Not contact users outside Platform without consent\n\n'
            'DATA BREACH LIABILITY:\n'
            '• YOU are responsible for securing user data you receive\n'
            '• YOU are liable for any data breaches on your end\n'
            '• You must report breaches to us immediately\n'
            '• You may face legal action for data misuse',
            themeService,
            Icons.warning_amber_outlined,
          ),
          
          _buildSection(
            '4. How We Share Your Information',
            'WITH USERS:\n'
            '• Your public profile (name, photo, bio, ratings)\n'
            '• Your specializations and experience\n'
            '• Your availability and service rates\n'
            '• General consultation history (anonymized stats)\n\n'
            'WITH SERVICE PROVIDERS:\n'
            '• Payment processors (for payouts)\n'
            '• Cloud hosting providers (for data storage)\n'
            '• Identity verification services\n'
            '• Communication services (for calls/chat)\n'
            '• Analytics providers (anonymized data)\n\n'
            'LEGAL DISCLOSURE:\n'
            '• Compliance with laws and court orders\n'
            '• Response to legal requests from authorities\n'
            '• Tax reporting to government (as required)\n'
            '• Protection of Platform rights and safety\n'
            '• Investigation of fraud or violations\n\n'
            'BUSINESS TRANSFERS:\n'
            '• In case of merger, acquisition, or sale\n'
            '• With notification and continued consent\n\n'
            'WITH YOUR CONSENT:\n'
            '• Any other sharing with your explicit permission\n\n'
            'WE DO NOT:\n'
            '• Sell your personal information to third parties\n'
            '• Share your financial details with users\n'
            '• Disclose your ID documents publicly',
            themeService,
          ),
          
          _buildSection(
            '5. Data Security',
            'SECURITY MEASURES:\n\n'
            'We protect your information with:\n\n'
            'TECHNICAL SAFEGUARDS:\n'
            '• Encryption of data in transit (SSL/TLS)\n'
            '• Encryption of sensitive data at rest\n'
            '• Secure authentication and access controls\n'
            '• Regular security audits and updates\n'
            '• Firewall and intrusion detection\n'
            '• Secure payment processing\n\n'
            'ORGANIZATIONAL MEASURES:\n'
            '• Restricted employee access (need-to-know)\n'
            '• Staff training on data protection\n'
            '• Confidentiality agreements\n'
            '• Incident response procedures\n'
            '• Regular security assessments\n\n'
            'YOUR RESPONSIBILITIES:\n'
            '• Keep your login credentials confidential\n'
            '• Use strong, unique passwords\n'
            '• Enable two-factor authentication (if available)\n'
            '• Protect devices used for Platform access\n'
            '• Report suspicious activity immediately\n'
            '• Secure user data you receive\n\n'
            'LIMITATIONS:\n'
            'While we implement strong security, no system is 100% secure. We cannot guarantee absolute security.',
            themeService,
          ),
          
          _buildSection(
            '6. Data Retention',
            'We retain your information as follows:\n\n'
            'ACTIVE ACCOUNT:\n'
            '• Profile and service data: While account is active\n'
            '• Consultation records: 3 years (for dispute resolution)\n'
            '• Communication logs: 90 days (unless needed for investigations)\n\n'
            'FINANCIAL RECORDS:\n'
            '• Transaction history: 7 years (Indian tax law requirement)\n'
            '• Payment details: As long as payouts are pending\n'
            '• Tax documents: As required by law\n\n'
            'CLOSED ACCOUNT:\n'
            '• Personal data deleted 30 days after account closure\n'
            '• Financial records retained per legal requirements\n'
            '• Anonymized analytics data may be retained\n'
            '• Dispute-related data retained until resolution\n\n'
            'LEGAL OBLIGATIONS:\n'
            '• Some data retained longer for legal compliance\n'
            '• Court-ordered data preservation\n'
            '• Tax and audit requirements',
            themeService,
          ),
          
          _buildSection(
            '7. Your Rights & Choices',
            'ACCESS & PORTABILITY:\n'
            '• View your profile and account data anytime\n'
            '• Request a copy of your personal information\n'
            '• Export your data in portable format\n'
            '• Access your earnings and transaction history\n\n'
            'CORRECTION & UPDATE:\n'
            '• Update your profile through app settings\n'
            '• Correct inaccurate information\n'
            '• Request corrections of data we hold\n'
            '• Update bank and payment details\n\n'
            'DELETION & ACCOUNT CLOSURE:\n'
            '• Close your account at any time\n'
            '• Request deletion of specific data\n'
            '• Right to be forgotten (subject to legal exceptions)\n'
            '• Complete pending consultations before closure\n\n'
            'CONSENT MANAGEMENT:\n'
            '• Opt out of promotional communications\n'
            '• Disable location tracking\n'
            '• Manage notification preferences\n'
            '• Control data sharing settings\n\n'
            'RESTRICTION & OBJECTION:\n'
            '• Restrict certain data processing\n'
            '• Object to specific uses of data\n'
            '• Lodge complaints with authorities\n\n'
            'To exercise these rights, contact: support@axiomleap.com',
            themeService,
          ),
          
          _buildSection(
            '8. Cookies & Tracking',
            'We use cookies and tracking technologies for:\n\n'
            'ESSENTIAL:\n'
            '• Maintain your login session\n'
            '• Remember your preferences\n'
            '• Enable Platform functionality\n\n'
            'ANALYTICS:\n'
            '• Understand Platform usage\n'
            '• Monitor service performance\n'
            '• Improve user experience\n\n'
            'FUNCTIONAL:\n'
            '• Personalize your dashboard\n'
            '• Remember availability settings\n'
            '• Track consultation metrics\n\n'
            'COOKIE CONTROL:\n'
            'You can manage cookies through browser settings, though this may limit functionality.',
            themeService,
          ),
          
          _buildSection(
            '9. Third-Party Services',
            'INTEGRATED SERVICES:\n\n'
            'We use third-party services for:\n\n'
            'PAYMENT PROCESSING:\n'
            '• Razorpay, PayU, or similar (for payouts)\n'
            '• Subject to their privacy policies\n'
            '• We don\'t store full bank account details\n\n'
            'IDENTITY VERIFICATION:\n'
            '• KYC verification partners\n'
            '• Document verification services\n'
            '• Background check providers\n\n'
            'COMMUNICATION:\n'
            '• Call/video service providers\n'
            '• SMS/email notification services\n'
            '• Push notification platforms\n\n'
            'These third parties have their own privacy policies. We select vendors with strong data protection practices.',
            themeService,
          ),
          
          _buildSection(
            '10. International Data Transfers',
            'DATA STORAGE LOCATION:\n'
            '• Primary storage in India\n'
            '• May use international cloud services\n'
            '• Transfers comply with Indian data protection laws\n'
            '• Adequate safeguards for international transfers\n\n'
            'By using the Platform, you consent to such transfers.',
            themeService,
          ),
          
          _buildSection(
            '11. Changes to Privacy Policy',
            'We may update this policy to reflect:\n\n'
            '• Changes in data practices\n'
            '• New features or services\n'
            '• Legal or regulatory requirements\n'
            '• Industry best practices\n\n'
            'NOTIFICATION:\n'
            '• Material changes notified via email\n'
            '• Updated "Last updated" date\n'
            '• Continued use = acceptance\n'
            '• Review policy periodically\n\n'
            'Significant changes may require explicit consent.',
            themeService,
          ),
          
          _buildSection(
            '12. Grievance Redressal',
            'For privacy concerns:\n\n'
            'GRIEVANCE OFFICER:\n'
            'Name: Grievance Redressal Officer\n'
            'Company: AXIOM LEAP\n'
            'Email: grievance@axiomleap.com\n'
            'Support: support@axiomleap.com\n\n'
            'RESPONSE:\n'
            '• Acknowledgment within 24 hours\n'
            '• Resolution within 15 days (IT Act 2000)\n'
            '• Escalation for unresolved issues\n\n'
            'You may also lodge complaints with data protection authorities.',
            themeService,
          ),
          
          _buildSection(
            '13. Contact Information',
            'For questions or requests:\n\n'
            'Company: AXIOM LEAP\n'
            'Email: support@axiomleap.com\n'
            'Grievance Officer: grievance@axiomleap.com\n'
            'Website: www.axiomleap.com\n\n'
            'We are committed to protecting your privacy.',
            themeService,
          ),
          
          _buildSection(
            '14. Legal Compliance',
            'This Privacy Policy complies with:\n\n'
            '• Information Technology Act, 2000, Section 43A\n'
            '• IT (Reasonable Security Practices) Rules, 2011\n'
            '• Intermediary Guidelines Rules, 2021\n'
            '• Income Tax Act, 1961 (for financial reporting)\n'
            '• Other applicable Indian privacy laws\n\n'
            'We maintain high standards of data protection and privacy.',
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

  // CRITICAL ACKNOWLEDGMENT for Astrologers - Prominent visual treatment
  Widget _buildCriticalAcknowledgment(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.deepOrange.withOpacity(0.1),
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
                  Icons.check_circle_outline,
                  size: 28,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '⚠️ YOUR ACKNOWLEDGMENT',
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
            'BY REGISTERING AS AN ASTROLOGER, YOU ACKNOWLEDGE:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• You are an INDEPENDENT CONTRACTOR, not an employee\n'
            '• You are SOLELY RESPONSIBLE for your predictions and advice\n'
            '• You bear FULL LIABILITY for your professional services\n'
            '• You INDEMNIFY the Platform from all claims related to your services\n'
            '• The Platform is an INTERMEDIARY with no control over your services\n'
            '• You must maintain professional standards and ethical conduct\n'
            '• You are responsible for taxes and legal compliance\n'
            '• You will protect user data and maintain confidentiality\n\n'
            'These terms are legally binding. By using this Platform, you accept full professional responsibility for your astrology services.',
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
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Website: www.axiomleap.com'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
