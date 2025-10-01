import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/status_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../models/dashboard_stats_model.dart';
import '../widgets/status_toggle_widget.dart';
import '../widgets/earnings_card_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/calendar_card_widget.dart';
import '../widgets/dashboard_skeleton_loader.dart';
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
import '../../live/screens/live_preparation_screen.dart';
import '../../../shared/widgets/animated_button.dart';

class DashboardScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const DashboardScreen({
    super.key,
    this.initialTabIndex,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Start with Dashboard (first tab) as default
  AstrologerModel? _currentUser;
  final StorageService _storageService = StorageService();
  late PageController _pageController;
  DashboardStatsModel? _currentStats;

  @override
  void initState() {
    super.initState();
    
    // Set initial tab if provided
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
    
    // Initialize PageController with smooth physics
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 1.0,
    );
    
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
      final sessionId = await _storageService.getSessionId();
      
      print('Dashboard: Loading userIs: $userData');
      
      if (userData != null) {
        final Map<String, dynamic> data = jsonDecode(userData);
        final idValue = data['id'] ?? data['_id'];
        if (idValue != null) {
          data['id'] = idValue;
          data['_id'] = idValue;
        }
        if (sessionId != null) {
          data['sessionId'] = sessionId;
        }
        setState(() {
          _currentUser = AstrologerModel.fromJson(data);
        });

        if (_currentStats?.astrologer != null) {
          _currentUser = _currentStats!.astrologer;
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
          bio: '',
          awards: '',
          certificates: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sessionId: null,
        );
      });
    }
  }

  // Method to refresh user data when profile is updated
  void refreshUserData() {
    _loadUserData();
  }

  // Update user data from auth state
  void _updateUserFromAuthState(AuthSuccessState authState) {
    if (mounted) {
      setState(() {
        _currentUser = authState.astrologer;
        print('👤 [DASHBOARD] Updated user from auth state: ${_currentUser?.name}');
      });
    }
  }

  // Build page without double animation - PageView handles transitions
  Widget _buildPageWithAnimation(int index) {
    switch (index) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const ConsultationsScreen();
      case 2:
        return const HealScreen();
      case 3:
        return const EarningsScreen();
      case 4:
        return ProfileScreen(onProfileUpdated: refreshUserData);
      default:
        return _buildDashboardContent();
    }
  }

  // Method to navigate to specific tab programmatically
  void navigateToTab(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.selectionClick();
      _pageController.jumpToPage(index); // Instant jump - no sliding through tabs
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Go Live button method
  void _goLive() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LivePreparationScreen(),
      ),
    );
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
          body: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildPageWithAnimation(index);
            },
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
                HapticFeedback.selectionClick();
                
                // Jump to selected page - instant navigation for taps
                _pageController.jumpToPage(index);
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
                    icon: const Icon(Icons.healing_outlined),
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
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthUnauthenticatedState) {
              // User is not authenticated, redirect to login
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            } else if (authState is AuthSuccessState) {
              // User is authenticated, update current user data
              _updateUserFromAuthState(authState);
            }
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
            // Always show loading if user data is not ready yet
            if (_currentUser == null) {
              return const DashboardSkeletonLoader();
            }
            
            if (state is DashboardLoading) {
              // Show skeleton loader during initial load, existing content during refresh
              if (_currentStats == null) {
                return const DashboardSkeletonLoader();
              } else {
                // Show existing content during refresh to prevent flash animation
                return _buildDashboardBody(_currentStats!);
              }
            } else if (state is DashboardLoadedState) {
              _currentStats = state.stats; // Store current stats for refresh
              if (state.stats.astrologer != null) {
                _currentUser = state.stats.astrologer;
              }
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
                              navigateToTab(3); // Earnings tab
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Communication Cards - Redesigned
                          Column(
                            children: [
                              // Calls Today Card - New Design
                              _buildCallsCard(stats.callsToday),
                              const SizedBox(height: 12),
                              // Messages Today Card - New Design
                              _buildMessagesCard(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: StatsCardWidget(
                                  title: 'Avg Rating',
                                  value: stats.averageRating.toStringAsFixed(1),
                                  icon: Icons.star,
                                  color: AppTheme.ratingColor,
                                  onTap: () => _openReviewsScreen(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatsCardWidget(
                                  title: 'Avg Duration',
                                  value: '${stats.averageSessionDuration.toStringAsFixed(0)}m',
                                  icon: Icons.timer,
                                  color: AppTheme.secondaryColor,
                                  onTap: () {
                                    // TODO: Add navigation for average duration
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Calendar Card
                          CalendarCardWidget(
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
                          AnimatedButton(
                            onPressed: _simulateIncomingCall,
                            text: 'Test Incoming Call',
                            icon: Icons.call_received,
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            width: double.infinity,
                            height: 56,
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
                      navigateToTab(4); // Profile tab
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
                            navigateToTab(4); // Profile tab
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeService.primaryColor,
                themeService.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiscussionScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discussion',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
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
          ),
        );
      },
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

  // Redesigned Calls Today Card
  Widget _buildCallsCard(int callsToday) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _openCommunicationScreen('calls');
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeService.primaryColor,
                themeService.primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side - Icon container with backdrop blur effect
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              // Middle - Number and label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      callsToday.toString(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Calls Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - VS YESTERDAY and percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VS YESTERDAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        '12%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  // Redesigned Messages Today Card
  Widget _buildMessagesCard() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Material(
          color: themeService.surfaceColor,
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          shadowColor: themeService.primaryColor.withOpacity(0.1),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _openCommunicationScreen('messages');
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: themeService.primaryColor.withOpacity(0.15),
            highlightColor: themeService.primaryColor.withOpacity(0.1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeService.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                    children: [
                      // Left side - Label, number, and trend badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MESSAGES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: themeService.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '12',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: themeService.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Trend badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981), // emerald - success color
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        '+8%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'from last week',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeService.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Right side - Icon container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeService.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.message,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }
}
