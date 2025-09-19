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
  const ProfileScreen({super.key});

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.infoColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: AnimatedAvatar(
              imagePath: _currentUser?.profilePicture,
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              textColor: Colors.white,
              showEditIcon: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      currentUser: _currentUser,
                      onProfileUpdated: () {
                        _loadUserData();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Loading...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Professional Astrologer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 8),
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor.withOpacity(0.7),
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
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.7),
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
    return SimpleTouchFeedback(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AnimatedButton(
          text: 'Edit Profile',
          icon: Icons.edit,
          width: double.infinity,
          height: 56,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  currentUser: _currentUser,
                  onProfileUpdated: () {
                    _loadUserData(); // Refresh user data
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedButton(
          text: 'Share Profile',
          icon: Icons.share,
          width: double.infinity,
          height: 56,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          isOutlined: true,
          onPressed: () {
            // TODO: Share profile
          },
        ),
        const SizedBox(height: 12),
        AnimatedButton(
          text: 'Logout',
          icon: Icons.logout,
          width: double.infinity,
          height: 56,
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          isOutlined: true,
          onPressed: () {
            context.read<AuthBloc>().add(LogoutEvent());
          },
        ),
        const SizedBox(height: 12),
        AnimatedButton(
          text: 'Delete Account',
          icon: Icons.delete_forever,
          width: double.infinity,
          height: 56,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          isOutlined: true,
          onPressed: () {
            _showDeleteAccountDialog(context);
          },
        ),
      ],
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