import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/status_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/status_toggle_widget.dart';
import '../widgets/earnings_card_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/calendar_card_widget.dart';
import '../../consultations/screens/consultations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../heal/screens/heal_screen.dart';
import '../../heal/screens/discussion_screen.dart';
import '../../communication/screens/communication_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../communication/screens/incoming_call_screen.dart';
import '../../reviews/screens/reviews_overview_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../widgets/live_astrologers_stories_widget.dart';
import '../widgets/minimal_availability_toggle_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Start with Dashboard (first tab) as default
  AstrologerModel? _currentUser;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Set status bar style for transparent status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.light, // White icons on blue background
        statusBarBrightness: Brightness.light, // For iOS - light content on dark background
        systemNavigationBarColor: Colors.white, // Keep navigation bar white
        systemNavigationBarIconBrightness: Brightness.dark, // Dark icons on white nav bar
      ),
    );
    // Load user data first, then load dashboard stats
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load user data first
    await _loadUserData();
    
    // Then load dashboard stats
    if (mounted) {
      context.read<DashboardBloc>().add(LoadDashboardStatsEvent());
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      print('👤 [DASHBOARD] User data from storage: $userData');
      if (userData != null && userData.isNotEmpty && mounted) {
        final userDataMap = jsonDecode(userData);
        print('👤 [DASHBOARD] Parsed user data: $userDataMap');
        
        // Validate that the user data contains required fields
        if (userDataMap is Map<String, dynamic> && userDataMap.containsKey('id')) {
          setState(() {
            _currentUser = AstrologerModel.fromJson(userDataMap);
            print('👤 [DASHBOARD] Current user profile picture: ${_currentUser?.profilePicture}');
          });
        } else {
          print('👤 [DASHBOARD] Invalid user data format, using fallback');
          _setFallbackUser();
        }
      } else {
        print('👤 [DASHBOARD] No user data found, using fallback');
        _setFallbackUser();
      }
    } catch (e) {
      print('Error loading user data: $e');
      _setFallbackUser();
    }
  }

  void _setFallbackUser() {
    if (mounted) {
      setState(() {
        _currentUser = AstrologerModel(
          id: 'unknown',
          name: 'User',
          email: '',
          phone: '',
          profilePicture: null, // Explicitly set to null
          specializations: [],
          languages: [],
          experience: 0,
          ratePerMinute: 0.0,
          isOnline: false,
          totalEarnings: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  // Method to refresh user data when profile is updated
  void refreshUserData() {
    _loadUserData();
  }

  // Go Live button method
  void _goLive() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/live-preparation');
  }

  // Open notifications method
  void _openNotifications() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  ImageProvider? _getImageProvider(String imagePath) {
    try {
      print('🖼️ [DASHBOARD] Loading profile picture: $imagePath');
      
      // Validate imagePath is not empty
      if (imagePath.isEmpty) {
        print('🖼️ [DASHBOARD] Image path is empty, returning null');
        return null;
      }
      
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('/uploads/')) {
        // Network URL - construct full URL for Railway backend
        if (imagePath.startsWith('/uploads/')) {
          final fullUrl = 'https://astrologerapp-production.up.railway.app$imagePath';
          print('🖼️ [DASHBOARD] Full URL: $fullUrl');
          
          // Return NetworkImage with error handling
          return NetworkImage(fullUrl);
        }
        print('🖼️ [DASHBOARD] Direct URL: $imagePath');
        return NetworkImage(imagePath);
      } else {
        // Local file path
        print('🖼️ [DASHBOARD] Local file: $imagePath');
        return FileImage(File(imagePath));
      }
    } catch (e) {
      print('🖼️ [DASHBOARD] Error creating image provider: $e');
      return null;
    }
  }

  // Method to open communication screen with specific tab
  void _openCommunicationScreen(String tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunicationScreen(initialTab: tab),
      ),
    );
  }

  // Method to simulate incoming call
  void _simulateIncomingCall() {
    print('📞 [DASHBOARD] Simulating incoming call');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomingCallScreen(
          phoneNumber: '+91 98765 43210',
          contactName: 'Sarah Miller',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboardContent(),
              const ConsultationsScreen(),
              const HealScreen(),
              const EarningsScreen(),
              ProfileScreen(onProfileUpdated: refreshUserData),
            ],
          ),
          bottomNavigationBar: Container(
            height: 80, // Increased height for better touch targets
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: themeService.borderColor,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                // Add soft haptic feedback
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: themeService.primaryColor,
          unselectedItemColor: themeService.textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              iconSize: 22, // Slightly larger icons for better visibility
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    label: l10n.dashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: l10n.consultations,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.auto_awesome),
                    label: l10n.heal,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.trending_up_outlined),
                    label: l10n.earnings,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.account_circle_outlined),
                    label: l10n.profile,
                  ),
                ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
        return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1E40AF), // Force blue status bar
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.light, // For iOS
          ),
      child: SafeArea(
        top: false, // Don't add top padding since we handle status bar manually
        child: Container(
          width: double.infinity,
          height: double.infinity,
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            // Always show loading if user data is not ready yet
            if (_currentUser == null) {
              return const DashboardSkeletonLoader();
            }
            
            if (state is DashboardLoading) {
              return const DashboardSkeletonLoader();
            } else if (state is DashboardLoadedState) {
              return _buildDashboardBody(state.stats);
            } else if (state is DashboardErrorState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DashboardBloc>().add(LoadDashboardStatsEvent());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Fallback for any unhandled states (like StatusUpdatedState)
              return const DashboardSkeletonLoader();
            }
          },
        ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(stats) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Header (includes status toggle) - Full width
            _buildHeader(_currentUser),
            
            // Live Astrologers Stories Widget - Instagram Style
            const LiveAstrologersStoriesWidget(),
            
            // Minimal Availability Toggle - Above Earnings Card
            const MinimalAvailabilityToggleWidget(),
            
            // Content with padding
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            
            // Earnings Card
            EarningsCardWidget(
              todayEarnings: stats.todayEarnings,
              totalEarnings: stats.totalEarnings,
              onRefresh: () {
                context.read<DashboardBloc>().add(RefreshDashboardEvent());
              },
              onTap: () {
                // Navigate to earnings screen
                setState(() {
                  _selectedIndex = 3; // Earnings tab (updated index)
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Communication Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openCommunicationScreen('calls'),
                    child: StatsCardWidget(
                      title: 'Calls Today',
                      value: stats.callsToday.toString(),
                      icon: Icons.phone,
                      color: AppTheme.callsColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openCommunicationScreen('messages'),
                    child: StatsCardWidget(
                      title: 'Messages Today',
                      value: '12', // Mock data - replace with actual messages today
                      icon: Icons.message,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openReviewsScreen(),
                    child: StatsCardWidget(
                      title: 'Avg Rating',
                      value: stats.averageRating.toStringAsFixed(1),
                      icon: Icons.star,
                      color: AppTheme.ratingColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Avg Duration',
                    value: '${stats.averageSessionDuration.toStringAsFixed(0)}m',
                    icon: Icons.timer,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Calendar Card
            CalendarCardWidget(
              todayBookings: stats.todayCount,
              upcomingBookings: 5, // Mock data - replace with actual upcoming bookings
              onTap: () {
                // Navigate to calendar screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Discussion Card
            _buildDiscussionCard(),
            
            const SizedBox(height: 16),
            
            // Temporary Test Button for Incoming Call
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _simulateIncomingCall,
                icon: const Icon(Icons.call_received, color: Colors.white),
                label: const Text(
                  'Test Incoming Call',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
                ],
              ),
            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AstrologerModel? user) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Only modify for dark and Vedic themes, keep light theme original
        if (themeService.isLightMode()) {
          // Keep original light theme header
        return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF1E40AF), // Force blue status bar
              statusBarIconBrightness: Brightness.light, // White icons
              statusBarBrightness: Brightness.light, // For iOS
          ),
          child: Container(
            width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)], // Modern blue gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 0),
          child: Column(
            children: [
              // User info row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to profile
                      setState(() {
                        _selectedIndex = 4; // Profile tab (updated index)
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: ProfileAvatarWidget(
                        imagePath: user?.profilePicture,
                        radius: 28,
                        fallbackText: user?.name?.isNotEmpty == true 
                                    ? user!.name!.substring(0, 1).toUpperCase()
                            : 'A',
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Loading...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // Header action buttons
                  Row(
                    children: [
                      // Live Video Button
                      _buildGoLiveButton(),
                      const SizedBox(width: 12),
                      // Notifications Button
                      Consumer<NotificationService>(
                        builder: (context, notificationService, child) {
                          return _buildHeaderButton(
                            icon: Icons.notifications_outlined,
                            onTap: _openNotifications,
                            tooltip: 'Notifications',
                            badge: notificationService.unreadCount,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
        );
        } else {
          // Enhanced header for dark and Vedic themes
          LinearGradient headerGradient;
          SystemUiOverlayStyle statusBarStyle;
          
          if (themeService.isVedicMode()) {
            // Vedic theme: Dark gradient similar to earnings card
            headerGradient = const LinearGradient(
              colors: [
                Color(0xFF1a1a2e), // Deep dark blue
                Color(0xFF16213e), // Slightly lighter dark blue
                Color(0xFF0f3460), // Dark blue with hint of purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            );
            statusBarStyle = const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF1a1a2e),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            );
          } else {
            // Dark theme: Elegant dark gradient
            headerGradient = LinearGradient(
              colors: [
                themeService.primaryColor.withOpacity(0.9),
                themeService.primaryColor.withOpacity(0.7),
                themeService.backgroundColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            );
            statusBarStyle = SystemUiOverlayStyle(
              statusBarColor: themeService.primaryColor.withOpacity(0.9),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            );
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: statusBarStyle,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isVedicMode() 
                        ? Colors.black.withOpacity(0.4)
                        : themeService.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 0),
                child: Column(
                  children: [
                    // User info row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile
                            setState(() {
                              _selectedIndex = 4; // Profile tab (updated index)
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeService.isVedicMode() 
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.3), 
                                width: 2
                              ),
                            ),
                            child: ProfileAvatarWidget(
                              imagePath: user?.profilePicture,
                              radius: 28,
                              fallbackText: user?.name?.isNotEmpty == true 
                                  ? user!.name!.substring(0, 1).toUpperCase()
                                  : 'A',
                              backgroundColor: themeService.isVedicMode() 
                                  ? const Color(0xFF1a1a2e)
                                  : Colors.white,
                              textColor: themeService.isVedicMode() 
                                  ? Colors.white
                                  : themeService.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: themeService.isVedicMode() 
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Loading...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // Header action buttons
                  Row(
                    children: [
                      // Live Video Button
                      _buildGoLiveButton(),
                      const SizedBox(width: 12),
                      // Notifications Button
                      Consumer<NotificationService>(
                        builder: (context, notificationService, child) {
                          return _buildHeaderButton(
                            icon: Icons.notifications_outlined,
                            onTap: _openNotifications,
                            tooltip: 'Notifications',
                            badge: notificationService.unreadCount,
                          );
                        },
                      ),
                    ],
                  ),
                      ],
                    ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
        }
      },
    );
  }

  // Build Go Live button
  Widget _buildGoLiveButton() {
    return Tooltip(
      message: 'Go Live',
      child: GestureDetector(
        onTap: _goLive,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4444).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live indicator dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Camera icon
              Icon(
                Icons.videocam,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              // LIVE text
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build header button
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    int? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDiscussionCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)], // Purple to blue-purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SimpleTouchFeedback(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DiscussionScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Discuss topics of interest with loved ones',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // 3D Illustration placeholder - you can replace this with an actual illustration
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.forum,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReviewsScreen() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewsOverviewScreen(),
      ),
    );
  }
}
