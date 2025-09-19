import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _emailNotifications = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AccountDeletedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          // Navigate to login screen after account deletion
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } else if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            
            // Header
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Account Settings
            _buildSection(
              'Account',
              [
                _buildListTile(
                  Icons.person,
                  'Profile Settings',
                  'Update your profile information',
                  onTap: () {
                    // TODO: Navigate to profile settings
                  },
                ),
                _buildListTile(
                  Icons.security,
                  'Privacy & Security',
                  'Manage your privacy settings',
                  onTap: () {
                    // TODO: Navigate to privacy settings
                  },
                ),
                _buildListTile(
                  Icons.payment,
                  'Payment Methods',
                  'Manage withdrawal methods',
                  onTap: () {
                    // TODO: Navigate to payment settings
                  },
                ),
              ],
            ),
            
            // Notification Settings
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  Icons.notifications,
                  'Push Notifications',
                  'Receive notifications for new consultations',
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  Icons.volume_up,
                  'Sound',
                  'Play sound for notifications',
                  _soundEnabled,
                  (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  Icons.vibration,
                  'Vibration',
                  'Vibrate for notifications',
                  _vibrationEnabled,
                  (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  Icons.email,
                  'Email Notifications',
                  'Receive emails for important updates',
                  _emailNotifications,
                  (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
              ],
            ),
            
            // App Preferences
            _buildSection(
              'Preferences',
              [
                _buildDropdownTile(
                  Icons.language,
                  'Language',
                  _selectedLanguage,
                  ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'],
                  (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                  },
                ),
                _buildDropdownTile(
                  Icons.palette,
                  'Theme',
                  _selectedTheme,
                  ['Light', 'Dark', 'System'],
                  (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
                _buildListTile(
                  Icons.schedule,
                  'Working Hours',
                  'Set your availability schedule',
                  onTap: () {
                    _showWorkingHoursDialog();
                  },
                ),
              ],
            ),
            
            // Help & Support
            _buildSection(
              'Help & Support',
              [
                _buildListTile(
                  Icons.help,
                  'FAQ',
                  'Frequently asked questions',
                  onTap: () {
                    // TODO: Navigate to FAQ
                  },
                ),
                _buildListTile(
                  Icons.support_agent,
                  'Contact Support',
                  'Get help from our support team',
                  onTap: () {
                    _showSupportDialog();
                  },
                ),
                _buildListTile(
                  Icons.rate_review,
                  'Rate the App',
                  'Share your feedback',
                  onTap: () {
                    // TODO: Open app store rating
                  },
                ),
                _buildListTile(
                  Icons.info,
                  'About',
                  'App version and information',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
              ],
            ),
            
            // Danger Zone
            _buildSection(
              'Account Actions',
              [
                _buildListTile(
                  Icons.logout,
                  'Logout',
                  'Sign out of your account',
                  textColor: AppTheme.errorColor,
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
                _buildListTile(
                  Icons.delete_forever,
                  'Delete Account',
                  'Permanently delete your account',
                  textColor: AppTheme.errorColor,
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? AppTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textColor,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showWorkingHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Working Hours'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set your availability schedule:'),
            SizedBox(height: 16),
            Text('Monday - Friday: 9:00 AM - 9:00 PM'),
            Text('Saturday - Sunday: 10:00 AM - 8:00 PM'),
            SizedBox(height: 16),
            Text('This feature will be implemented soon.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('support@astrologerapp.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('+91 8050381803'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('24/7 Support Available'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Astrologer App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: MVP Release'),
            SizedBox(height: 16),
            Text('Developed for professional astrologers to manage consultations and earnings efficiently.'),
            SizedBox(height: 16),
            Text('© 2024 Astrologer App. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(DeleteAccountEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
