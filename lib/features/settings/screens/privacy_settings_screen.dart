import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Privacy settings state
  bool _dataCollectionEnabled = true;
  bool _analyticsEnabled = true;
  bool _marketingEmails = false;
  bool _pushNotifications = true;
  bool _locationTracking = false;
  bool _cameraAccess = true;
  bool _microphoneAccess = true;
  bool _contactsAccess = false;
  bool _calendarAccess = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(l10n.privacy),
            backgroundColor: themeService.surfaceColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrivacyHeader(themeService),
                const SizedBox(height: 24),
                
                // Data & Privacy Section
                _buildSection(
                  'Data & Privacy',
                  [
                    _buildSwitchTile(
                      'Data Collection',
                      'Allow collection of usage data to improve the app',
                      _dataCollectionEnabled,
                      (value) => setState(() => _dataCollectionEnabled = value),
                      Icons.analytics_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Analytics',
                      'Help us understand how you use the app',
                      _analyticsEnabled,
                      (value) => setState(() => _analyticsEnabled = value),
                      Icons.bar_chart_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Marketing Emails',
                      'Receive promotional content and updates',
                      _marketingEmails,
                      (value) => setState(() => _marketingEmails = value),
                      Icons.email_outlined,
                      themeService,
                    ),
                  ],
                  themeService,
                ),
                
                const SizedBox(height: 24),
                
                // Notifications Section
                _buildSection(
                  'Notifications',
                  [
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive important updates and reminders',
                      _pushNotifications,
                      (value) => setState(() => _pushNotifications = value),
                      Icons.notifications_outlined,
                      themeService,
                    ),
                  ],
                  themeService,
                ),
                
                const SizedBox(height: 24),
                
                // Permissions Section
                _buildSection(
                  'App Permissions',
                  [
                    _buildSwitchTile(
                      'Location Access',
                      'Allow location tracking for better services',
                      _locationTracking,
                      (value) => setState(() => _locationTracking = value),
                      Icons.location_on_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Camera Access',
                      'Required for video consultations',
                      _cameraAccess,
                      (value) => setState(() => _cameraAccess = value),
                      Icons.camera_alt_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Microphone Access',
                      'Required for voice consultations',
                      _microphoneAccess,
                      (value) => setState(() => _microphoneAccess = value),
                      Icons.mic_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Contacts Access',
                      'Access contacts for easy client management',
                      _contactsAccess,
                      (value) => setState(() => _contactsAccess = value),
                      Icons.contacts_outlined,
                      themeService,
                    ),
                    _buildSwitchTile(
                      'Calendar Access',
                      'Sync with calendar for appointment scheduling',
                      _calendarAccess,
                      (value) => setState(() => _calendarAccess = value),
                      Icons.calendar_today_outlined,
                      themeService,
                    ),
                  ],
                  themeService,
                ),
                
                const SizedBox(height: 24),
                
                // Privacy Actions Section
                _buildSection(
                  'Privacy Actions',
                  [
                    _buildActionTile(
                      'View Privacy Policy',
                      'Read our complete privacy policy',
                      Icons.privacy_tip_outlined,
                      () => _showPrivacyPolicy(themeService),
                      themeService,
                    ),
                    _buildActionTile(
                      'Data Export',
                      'Download your personal data',
                      Icons.download_outlined,
                      () => _exportData(themeService),
                      themeService,
                    ),
                    _buildActionTile(
                      'Delete Account',
                      'Permanently delete your account and data',
                      Icons.delete_forever_outlined,
                      () => _showDeleteAccountDialog(themeService),
                      themeService,
                      isDestructive: true,
                    ),
                  ],
                  themeService,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyHeader(ThemeService themeService) {
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
              Icons.security_outlined,
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
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control your data and privacy settings',
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

  Widget _buildSection(String title, List<Widget> children, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeService.borderColor,
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    ThemeService themeService,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: themeService.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: themeService.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: themeService.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: themeService.primaryColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeService themeService, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? themeService.errorColor : themeService.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? themeService.errorColor : themeService.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: themeService.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: themeService.textSecondary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showPrivacyPolicy(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.surfaceColor,
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: themeService.textPrimary),
        ),
        content: Text(
          'Our privacy policy outlines how we collect, use, and protect your personal information. We are committed to maintaining the privacy and security of your data.',
          style: TextStyle(color: themeService.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: themeService.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(ThemeService themeService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data export initiated. You will receive an email with your data.'),
        backgroundColor: themeService.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.surfaceColor,
        title: Text(
          'Delete Account',
          style: TextStyle(color: themeService.textPrimary),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: themeService.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account deletion request submitted.'),
                  backgroundColor: themeService.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: themeService.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}


