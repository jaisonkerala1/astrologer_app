import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/status_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'edit_profile_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../settings/screens/language_selection_screen.dart';
import '../../chat/widgets/floating_chat_button.dart';
import '../../reviews/screens/reviews_overview_screen.dart';
import '../../help_support/screens/help_support_screen.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import '../../theme/screens/theme_selection_screen.dart';
import '../../settings/screens/privacy_settings_screen.dart';
import '../../settings/screens/terms_privacy_screen.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../widgets/profile_screen_skeleton.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch

  @override
  void initState() {
    super.initState();
    // Load profile data using BLoC
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  void _onProfileUpdated() {
    // Force reload profile using BLoC
    context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true));
    // Call the parent callback if provided
    widget.onProfileUpdated?.call();
  }

  ImageProvider? _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('/uploads/')) {
      // Network URL - construct full URL for Railway backend
      if (imagePath.startsWith('/uploads/')) {
        return NetworkImage('https://astrologerapp-production.up.railway.app$imagePath');
      }
      return NetworkImage(imagePath);
    } else {
      // Local file path
      return FileImage(File(imagePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              // Handle loading state with beautiful skeleton loader
              if (profileState is ProfileLoading) {
                return ProfileScreenSkeleton(themeService: themeService);
              }

              // Handle error state
              if (profileState is ProfileErrorState) {
                return Scaffold(
                  backgroundColor: themeService.backgroundColor,
                  appBar: AppBar(
                    backgroundColor: themeService.primaryColor,
                    elevation: 0,
                    title: const Text('Profile', style: TextStyle(color: Colors.white)),
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: themeService.errorColor),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: themeService.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profileState.message,
                            style: TextStyle(color: themeService.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeService.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Get astrologer from loaded state or updating state
              final astrologer = profileState is ProfileLoadedState 
                  ? profileState.astrologer 
                  : profileState is ProfileUpdating
                      ? profileState.currentAstrologer
                      : null;
              
              // Check if we're currently updating
              final isUpdating = profileState is ProfileUpdating;
              final updatingField = isUpdating ? (profileState as ProfileUpdating).field : null;

              // Show success message if available
              if (profileState is ProfileLoadedState && profileState.successMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(profileState.successMessage!),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                });
              }

              return Scaffold(
                backgroundColor: themeService.backgroundColor,
                appBar: AppBar(
                  backgroundColor: themeService.primaryColor,
                  elevation: 0,
                  centerTitle: false,
                  titleSpacing: 16,
                  title: Row(
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (isUpdating) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (isUpdating)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            'Updating ${updatingField ?? ""}...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                floatingActionButton: FloatingChatButton(userProfile: astrologer),
                body: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        // Force refresh profile from backend
                        context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true));
                        
                        // Wait for the state to update
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: themeService.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header - Full width
                        _buildProfileHeader(context, astrologer, themeService),
                        const SizedBox(height: 32),
                  
                  // Content with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Stats
                        _buildProfileStats(themeService),
                        const SizedBox(height: 24),
                        
                        // Earnings Section - Quick Access
                        _buildEarningsQuickAccess(themeService),
                        const SizedBox(height: 24),
                        
                        // Profile Sections
                        _buildProfileSection(
                          'Personal Information',
                          [
                            _buildInfoTile(Icons.person, 'Full Name', astrologer?.name ?? 'Loading...', themeService),
                            _buildInfoTile(Icons.phone, 'Phone', astrologer?.phone ?? 'Loading...', themeService),
                            _buildInfoTile(Icons.email, 'Email', astrologer?.email ?? 'Loading...', themeService),
                            _buildInfoTile(Icons.cake, 'Date of Birth', '15 Aug, 1985', themeService),
                          ],
                          themeService,
                        ),
                        const SizedBox(height: 24),
                        
                        _buildProfileSection(
                          'Professional Details',
                          [
                            _buildInfoTile(Icons.school, 'Experience', '${astrologer?.experience ?? 0} Years', themeService),
                            _buildInfoTile(Icons.star, 'Specializations', astrologer?.specializations.join(', ') ?? 'Loading...', themeService),
                            _buildInfoTile(Icons.language, 'Languages', astrologer?.languages.join(', ') ?? 'Loading...', themeService),
                            _buildInfoTile(Icons.currency_rupee, 'Rate per Minute', '₹${astrologer?.ratePerMinute ?? 0}', themeService),
                          ],
                          themeService,
                        ),
                        const SizedBox(height: 24),
                        
                        // Settings Section
                        _buildProfileSection(
                          AppLocalizations.of(context)!.settings,
                          [
                            _buildSettingsTile(Icons.notifications_outlined, AppLocalizations.of(context)!.notifications, 'Manage your notifications', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsScreen(),
                                ),
                              );
                            }, themeService),
                            _buildSettingsTile(Icons.language_outlined, AppLocalizations.of(context)!.language, 'Change app language', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LanguageSelectionScreen(),
                                ),
                              );
                            }, themeService),
                            _buildSettingsTile(Icons.palette_outlined, 'Theme', 'Choose your preferred theme', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ThemeSelectionScreen(),
                                ),
                              );
                            }, themeService),
                            _buildSettingsTile(Icons.security_outlined, AppLocalizations.of(context)!.privacy, 'Manage your privacy settings', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacySettingsScreen(),
                                ),
                              );
                            }, themeService),
                          ],
                          themeService,
                        ),
                        const SizedBox(height: 24),
                        
                        // Support Section
                        _buildProfileSection(
                          'Support',
                          [
                            _buildSettingsTile(Icons.help_outline, AppLocalizations.of(context)!.help, 'Get help and support', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpSupportScreen(),
                                ),
                              );
                            }, themeService),
                            _buildSettingsTile(Icons.info_outline, AppLocalizations.of(context)!.about, 'App version and information', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              );
                            }, themeService),
                            _buildSettingsTile(Icons.policy_outlined, 'Terms & Privacy', 'Read our terms and privacy policy', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsPrivacyScreen(),
                                ),
                              );
                            }, themeService),
                          ],
                          themeService,
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        _buildActionButtons(context, themeService, astrologer),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                      ],
                    ),
                  ),
                    ),
                    
                    // Subtle refresh indicator at top (Instagram/WhatsApp-style)
                    if (profileState is ProfileLoadedState && profileState.isRefreshing)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              themeService.primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AstrologerModel? user, ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        border: Border.all(color: themeService.borderColor, width: 1),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentUser: user,
                    onProfileUpdated: _onProfileUpdated,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                ProfileAvatarWidget(
                  imagePath: user?.profilePicture,
                  radius: 45,
                  fallbackText: user?.name?.isNotEmpty == true 
                      ? user!.name!.substring(0, 1).toUpperCase()
                      : 'A',
                  backgroundColor: themeService.primaryColor,
                  textColor: Colors.white,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Professional Astrologer',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<StatusService>(
            builder: (context, statusService, child) {
              if (statusService == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final l10n = AppLocalizations.of(context)!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusService.statusColorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusService.statusColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusService.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusService.isOnline ? l10n.onlineStatus : l10n.offlineStatus,
                      style: TextStyle(
                        color: statusService.statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats(ThemeService themeService) {
    return Row(
      children: [
        Expanded(
          child: _buildInteractiveStatCard(
            title: 'This Month',
            value: '23',
            icon: Icons.calendar_month,
            color: themeService.primaryColor,
            themeService: themeService,
            onTap: () => _navigateToConsultationAnalytics(initialTabIndex: 1), // Monthly tab
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInteractiveStatCard(
            title: 'Average Rating',
            value: '4.8',
            icon: Icons.star,
            color: themeService.warningColor,
            themeService: themeService,
            onTap: () => _navigateToReviews(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInteractiveStatCard(
            title: 'Total Consultations',
            value: '127',
            icon: Icons.event_note,
            color: themeService.infoColor,
            themeService: themeService,
            onTap: () => _navigateToConsultationAnalytics(initialTabIndex: 2), // All Time tab
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsQuickAccess(ThemeService themeService) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EarningsScreen(),
            ),
          );
        },
        borderRadius: themeService.borderRadius,
        splashColor: themeService.successColor.withOpacity(0.15),
        highlightColor: themeService.successColor.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeService.successColor,
                themeService.successColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: themeService.borderRadius,
            boxShadow: [
              BoxShadow(
                color: themeService.successColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Earnings & Payments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View your income and transaction history',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        border: Border.all(color: themeService.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: themeService.borderRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: themeService.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Enhanced interactive stat card with Material Design ripple and hover effects
  Widget _buildInteractiveStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeService themeService,
    required VoidCallback onTap,
  }) {
    return Material(
      color: themeService.cardColor,
      elevation: 1,
      borderRadius: themeService.borderRadius,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: themeService.borderRadius,
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: themeService.borderRadius,
            border: Border.all(
              color: themeService.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: themeService.borderRadius,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              // Value text
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Title text
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: themeService.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            border: Border.all(color: themeService.borderColor, width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: themeService.borderRadius,
            ),
            child: Icon(icon, color: themeService.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: themeService.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeService.textSecondary,
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

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap, ThemeService themeService) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: themeService.borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: themeService.borderRadius,
                ),
                child: Icon(icon, color: themeService.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: themeService.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: themeService.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeService themeService, AstrologerModel? astrologer) {
    return Column(
      children: [
        // Primary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildCompactButton(
                text: 'Edit Profile',
                icon: Icons.edit_outlined,
                color: themeService.primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        currentUser: astrologer,
                        onProfileUpdated: _onProfileUpdated,
                      ),
                    ),
                  );
                },
                themeService: themeService,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactButton(
                text: 'Share',
                icon: Icons.share_outlined,
                color: themeService.infoColor,
                onPressed: () {
                  _showShareOptions(context, astrologer);
                },
                themeService: themeService,
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
                color: themeService.warningColor,
                isOutlined: true,
                onPressed: () {
                  _showLogoutDialog(context);
                },
                themeService: themeService,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactButton(
                text: 'Delete Account',
                icon: Icons.delete_outline,
                color: themeService.errorColor,
                isOutlined: true,
                onPressed: () {
                  _showDeleteAccountDialog(context);
                },
                themeService: themeService,
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
    required ThemeService themeService,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: themeService.borderRadius,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
            borderRadius: themeService.borderRadius,
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

  void _showShareOptions(BuildContext context, AstrologerModel? astrologer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Share Profile',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.text_fields,
                    color: AppTheme.infoColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Share as Text',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                subtitle: const Text(
                  'Share profile details as text message',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfileAsText(astrologer);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Share with Image',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                subtitle: const Text(
                  'Share profile with profile picture',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfileWithImage(astrologer);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Share Profile Link',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                subtitle: const Text(
                  'Share a link to your profile',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfileLink(astrologer);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _shareProfileAsText(AstrologerModel? astrologer) {
    if (astrologer == null) return;

    final profileText = _generateProfileText(astrologer);
    
    Share.share(
      profileText,
      subject: '${astrologer.name} - Professional Astrologer Profile',
    );
  }

  void _shareProfileWithImage(AstrologerModel? astrologer) {
    if (astrologer == null) return;

    final profileText = _generateProfileText(astrologer);
    
    if (astrologer.profilePicture != null && 
        astrologer.profilePicture!.isNotEmpty) {
      // Share with image
      Share.shareXFiles(
        [XFile(astrologer.profilePicture!)],
        text: profileText,
        subject: '${astrologer.name} - Professional Astrologer Profile',
      );
    } else {
      // Fallback to text only if no image
      _shareProfileAsText(astrologer);
    }
  }

  void _shareProfileLink(AstrologerModel? astrologer) {
    if (astrologer == null) return;

    final profileText = _generateProfileText(astrologer);
    final profileLink = 'https://astrologerapp.com/profile/${astrologer.id}';
    
    final linkText = '''
$profileText

🔗 View my full profile: $profileLink

Download the Astrologer App to connect with me and get personalized astrological guidance!
''';

    Share.share(
      linkText,
      subject: '${astrologer.name} - Professional Astrologer Profile',
    );
  }

  void _navigateToReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewsOverviewScreen(),
      ),
    );
  }

  void _navigateToConsultationAnalytics({required int initialTabIndex}) {
    Navigator.pushNamed(
      context, 
      '/consultation-analytics',
      arguments: {'initialTabIndex': initialTabIndex},
    );
  }

  String _generateProfileText(AstrologerModel astrologer) {
    final specializations = astrologer.specializations.join(', ');
    final languages = astrologer.languages.join(', ');
    
    return '''
🌟 ${astrologer.name} - Professional Astrologer

📱 Phone: ${astrologer.phone}
📧 Email: ${astrologer.email}

🔮 Specializations: $specializations
🗣️ Languages: $languages
⭐ Experience: ${astrologer.experience} years
💰 Rate: ₹${astrologer.ratePerMinute}/minute

📊 Profile Stats:
• Total Consultations: 127
• Average Rating: 4.8/5
• This Month: 23 sessions

✨ Get personalized astrological guidance and insights from a professional astrologer with ${astrologer.experience} years of experience!

#Astrology #ProfessionalAstrologer #${astrologer.specializations.first.replaceAll(' ', '')} #SpiritualGuidance
''';
  }
}