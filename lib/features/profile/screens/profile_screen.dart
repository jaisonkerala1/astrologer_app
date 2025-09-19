import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/models/astrologer_model.dart';
import 'edit_profile_screen.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/animated_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AstrologerModel? _currentUser;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        setState(() {
          _currentUser = AstrologerModel.fromJson(userDataMap);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _onProfileUpdated() {
    _loadUserData();
    // Call the parent callback if provided
    widget.onProfileUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOutState) {
          // Navigate to login screen and clear all routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        } else if (state is AccountDeletedState) {
          // Show success message and navigate to login screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
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
            
            // Profile Header
            _buildProfileHeader(context, _currentUser),
            const SizedBox(height: 32),
            
            // Profile Stats
            _buildProfileStats(),
            const SizedBox(height: 24),
            
            // Profile Sections
            _buildProfileSection(
              'Personal Information',
              [
                _buildInfoTile(Icons.person, 'Full Name', _currentUser?.name ?? 'Loading...'),
                _buildInfoTile(Icons.phone, 'Phone', _currentUser?.phone ?? 'Loading...'),
                _buildInfoTile(Icons.email, 'Email', _currentUser?.email ?? 'Loading...'),
                _buildInfoTile(Icons.cake, 'Date of Birth', '15 Aug, 1985'),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildProfileSection(
              'Professional Details',
              [
                _buildInfoTile(Icons.school, 'Experience', '${_currentUser?.experience ?? 0} Years'),
                _buildInfoTile(Icons.star, 'Specializations', _currentUser?.specializations.join(', ') ?? 'Loading...'),
                _buildInfoTile(Icons.language, 'Languages', _currentUser?.languages.join(', ') ?? 'Loading...'),
                _buildInfoTile(Icons.currency_rupee, 'Rate per Minute', '₹${_currentUser?.ratePerMinute ?? 0}'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Settings Section
            _buildProfileSection(
              'Settings',
              [
                _buildSettingsTile(Icons.notifications_outlined, 'Notifications', 'Manage your notifications', () {}),
                _buildSettingsTile(Icons.language_outlined, 'Language', 'Change app language', () {}),
                _buildSettingsTile(Icons.dark_mode_outlined, 'Theme', 'Switch between light and dark mode', () {}),
                _buildSettingsTile(Icons.security_outlined, 'Privacy & Security', 'Manage your privacy settings', () {}),
              ],
            ),
            const SizedBox(height: 24),
            
            // Support Section
            _buildProfileSection(
              'Support',
              [
                _buildSettingsTile(Icons.help_outline, 'Help & Support', 'Get help and support', () {}),
                _buildSettingsTile(Icons.info_outline, 'About', 'App version and information', () {}),
                _buildSettingsTile(Icons.policy_outlined, 'Terms & Privacy', 'Read our terms and privacy policy', () {}),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AstrologerModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentUser: _currentUser,
                    onProfileUpdated: _onProfileUpdated,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                AnimatedAvatar(
                  imagePath: _currentUser?.profilePicture,
                  radius: 45,
                  backgroundColor: AppTheme.primaryColor,
                  textColor: Colors.white,
                  showEditIcon: false,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Loading...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Professional Astrologer',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Consultations', '127', Icons.event_note, AppTheme.infoColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Average Rating', '4.8', Icons.star, AppTheme.ratingColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('This Month', '23', Icons.calendar_month, AppTheme.callsColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textColor.withOpacity(0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildCompactButton(
                text: 'Edit Profile',
                icon: Icons.edit_outlined,
                color: AppTheme.primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        currentUser: _currentUser,
                        onProfileUpdated: _onProfileUpdated,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactButton(
                text: 'Share',
                icon: Icons.share_outlined,
                color: AppTheme.infoColor,
                onPressed: () {
                  // TODO: Share profile
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildCompactButton(
                text: 'Logout',
                icon: Icons.logout_outlined,
                color: AppTheme.warningColor,
                isOutlined: true,
                onPressed: () {
                  _showLogoutDialog(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactButton(
                text: 'Delete Account',
                icon: Icons.delete_outline,
                color: AppTheme.errorColor,
                isOutlined: true,
                onPressed: () {
                  _showDeleteAccountDialog(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: isOutlined ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutlined ? color : color,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOutlined ? color : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout? You will need to login again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutEvent());
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(DeleteAccountEvent());
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}