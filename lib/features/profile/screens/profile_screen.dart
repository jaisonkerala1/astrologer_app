import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../widgets/profile_screen_skeleton.dart';
import '../widgets/verification_status_card.dart';
import 'about_screen.dart';
import '../../clients/screens/my_clients_screen.dart';
import '../widgets/modern_profile_header.dart';
import '../widgets/profile_stats_cards_row.dart';
import '../widgets/modern_menu_item.dart';
import '../widgets/expandable_info_card.dart';
import '../widgets/info_row_item.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  void _onProfileUpdated() {
    context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true));
    widget.onProfileUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOutState) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else if (state is AccountDeletedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              if (profileState is ProfileLoading) {
                return ProfileScreenSkeleton(themeService: themeService);
              }

              if (profileState is ProfileErrorState) {
                return _buildErrorState(profileState, themeService, l10n);
              }

              final astrologer = profileState is ProfileLoadedState 
                  ? profileState.astrologer 
                  : profileState is ProfileUpdating
                      ? profileState.currentAstrologer
                      : null;

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
                backgroundColor: const Color(0xFFF5F5F7),
                appBar: _buildAppBar(themeService, l10n),
                floatingActionButton: FloatingChatButton(userProfile: astrologer),
                body: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: themeService.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Modern Profile Header
                        ModernProfileHeader(
                          astrologer: astrologer,
                          themeService: themeService,
                          onEditTap: () {
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
                        ),

                        const SizedBox(height: 20),

                        // Stats Cards Row
                        ProfileStatsCardsRow(
                          earningsValue: '₹${astrologer?.totalEarnings.toStringAsFixed(0) ?? '0'}',
                          earningsLabel: 'Total Earned',
                          ratingValue: '4.5',
                          ratingLabel: 'Rating',
                          clientsValue: '0',
                          clientsLabel: 'Clients',
                          themeService: themeService,
                          highlightFirst: false, // All cards same white style
                          onEarningsTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EarningsScreen(),
                              ),
                            );
                          },
                          onRatingTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReviewsOverviewScreen(),
                              ),
                            );
                          },
                          onClientsTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyClientsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Verification Status Card
                        if (astrologer != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: VerificationStatusCard(
                              astrologer: astrologer,
                              themeService: themeService,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Personal Information - Expandable
                        ExpandableInfoCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline,
                          themeService: themeService,
                          initiallyExpanded: false,
                          children: [
                            InfoRowItem(
                              icon: Icons.person,
                              label: 'Full Name',
                              value: astrologer?.name ?? 'Loading...',
                              themeService: themeService,
                            ),
                            InfoRowItem(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: astrologer?.phone ?? 'Loading...',
                              themeService: themeService,
                            ),
                            InfoRowItem(
                              icon: Icons.email,
                              label: 'Email',
                              value: astrologer?.email ?? 'Loading...',
                              themeService: themeService,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Professional Details - Expandable
                        ExpandableInfoCard(
                          title: 'Professional Details',
                          icon: Icons.business_center_outlined,
                          themeService: themeService,
                          initiallyExpanded: false,
                          children: [
                            InfoRowItem(
                              icon: Icons.school,
                              label: 'Experience',
                              value: '${astrologer?.experience ?? 0} Years',
                              themeService: themeService,
                            ),
                            InfoRowItem(
                              icon: Icons.star,
                              label: 'Specializations',
                              value: astrologer?.specializations.join(', ') ?? 'Loading...',
                              themeService: themeService,
                            ),
                            InfoRowItem(
                              icon: Icons.language,
                              label: 'Languages',
                              value: astrologer?.languages.join(', ') ?? 'Loading...',
                              themeService: themeService,
                            ),
                            InfoRowItem(
                              icon: Icons.currency_rupee,
                              label: 'Rate per Minute',
                              value: '₹${astrologer?.ratePerMinute ?? 0}',
                              themeService: themeService,
                            ),
                            if (astrologer?.bio.isNotEmpty == true)
                              InfoRowItem(
                                icon: Icons.description,
                                label: 'Bio',
                                value: astrologer!.bio,
                                themeService: themeService,
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Menu Items
                        ModernMenuItem(
                          icon: Icons.edit_outlined,
                          iconBackgroundColor: const Color(0xFF9B7FDB),
                          title: 'Edit Profile',
                          subtitle: 'Update personal details',
                          onTap: () {
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

                        ModernMenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          iconBackgroundColor: const Color(0xFF4CAF50),
                          title: 'Earnings',
                          subtitle: '₹${astrologer?.totalEarnings.toStringAsFixed(0) ?? '0'} total earned',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EarningsScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.people_outline,
                          iconBackgroundColor: const Color(0xFF2196F3),
                          title: 'My Clients',
                          subtitle: 'View all your clients',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyClientsScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.star_outline,
                          iconBackgroundColor: const Color(0xFFFF9800),
                          title: 'Reviews & Ratings',
                          subtitle: 'See what clients say',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReviewsOverviewScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.notifications_outlined,
                          iconBackgroundColor: const Color(0xFFE91E63),
                          title: l10n.notifications,
                          subtitle: 'Manage preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.language_outlined,
                          iconBackgroundColor: const Color(0xFF00BCD4),
                          title: l10n.language,
                          subtitle: 'English / हिंदी',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguageSelectionScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.palette_outlined,
                          iconBackgroundColor: const Color(0xFF673AB7),
                          title: 'Theme',
                          subtitle: 'Light / Dark / Auto',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ThemeSelectionScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.security_outlined,
                          iconBackgroundColor: const Color(0xFF607D8B),
                          title: l10n.privacy,
                          subtitle: 'Security & Privacy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacySettingsScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.help_outline,
                          iconBackgroundColor: const Color(0xFF3F51B5),
                          title: l10n.help,
                          subtitle: 'Get assistance',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.policy_outlined,
                          iconBackgroundColor: const Color(0xFF795548),
                          title: 'Terms & Privacy',
                          subtitle: 'Legal information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsPrivacyScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.info_outline,
                          iconBackgroundColor: const Color(0xFF9E9E9E),
                          title: l10n.about,
                          subtitle: 'App version & info',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutScreen(),
                              ),
                            );
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.share_outlined,
                          iconBackgroundColor: const Color(0xFF00BCD4),
                          title: 'Share Profile',
                          subtitle: 'Share with others',
                          onTap: () {
                            _shareProfile(astrologer);
                          },
                          themeService: themeService,
                        ),

                        ModernMenuItem(
                          icon: Icons.logout,
                          iconBackgroundColor: Colors.red,
                          title: l10n.logout,
                          subtitle: 'Sign out from app',
                          onTap: () => _showLogoutDialog(context, l10n),
                          themeService: themeService,
                          isDanger: true,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeService themeService, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: themeService.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Profile',
        style: TextStyle(
          color: themeService.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildErrorState(ProfileErrorState state, ThemeService themeService, AppLocalizations l10n) {
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
                state.message,
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

  void _shareProfile(AstrologerModel? astrologer) {
    if (astrologer == null) return;
    
    final String shareText = '''
Check out ${astrologer.name}'s profile!

🌟 Experience: ${astrologer.experience} years
💰 Rate: ₹${astrologer.ratePerMinute}/min
📚 Specializations: ${astrologer.specializations.join(', ')}

Download the Astrologer App to connect!
    ''';

    Share.share(shareText);
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

