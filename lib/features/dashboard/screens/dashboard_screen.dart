import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_assets.dart';
import '../../../app/routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/status_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/models/app_theme.dart' show AppThemeType;
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
import '../../../shared/widgets/value_shimmer.dart';
import '../../consultations/screens/consultations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../communication/services/communication_service.dart';
import '../../communication/models/communication_item.dart';
import '../../communication/bloc/communication_bloc.dart';
import '../../communication/bloc/communication_event.dart';
import '../../communication/bloc/communication_state.dart';
import '../../settings/screens/settings_screen.dart';
import '../../heal/screens/heal_screen.dart';
import '../../heal/screens/discussion_screen.dart';
import '../../../shared/widgets/empty_states/empty_state_gallery_screen.dart';
import '../../communication/screens/communication_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../communication/screens/incoming_call_screen.dart';
import '../../reviews/screens/reviews_overview_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/screens/astrologer_profile_screen.dart';
import '../../clients/screens/client_detail_screen.dart';
import '../../clients/screens/my_clients_screen.dart';
import '../../clients/models/client_model.dart';
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
  int _selectedIndex = 0; // Bottom nav selected index (0-4)
  int _currentPageIndex = 1; // PageView current page (0-5, starts at 1 for Dashboard)
  AstrologerModel? _currentUser;
  final StorageService _storageService = StorageService();
  late PageController _pageController;
  DashboardStatsModel? _currentStats;

  @override
  void initState() {
    super.initState();
    
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║          🏠 DASHBOARD SCREEN INITIALIZED             ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Timestamp: ${DateTime.now()}');
    print('║ InitialTabIndex: ${widget.initialTabIndex}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    
    // Set initial tab if provided (bottom nav index)
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
      _currentPageIndex = _selectedIndex + 1; // Map to page index (add 1 for hidden Live Prep page)
    }
    
    // Initialize PageController starting at Dashboard (page index 1)
    // Page 0 = Live Prep (hidden), Page 1 = Dashboard, Page 2 = Communication, etc.
    _pageController = PageController(
      initialPage: _currentPageIndex,
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
      print('📖 [DASHBOARD] Starting _loadUserData...');
      final userData = await _storageService.getUserData();
      final sessionId = await _storageService.getSessionId();
      final isLoggedIn = await _storageService.getIsLoggedIn();
      final authToken = await _storageService.getAuthToken();
      
      print('');
      print('╔═══════════════════════════════════════════════════════╗');
      print('║        📊 DASHBOARD USER DATA LOAD REPORT            ║');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ HasUserData: ${userData != null}');
      print('║ HasSessionId: ${sessionId != null}');
      print('║ IsLoggedIn: $isLoggedIn');
      print('║ HasAuthToken: ${authToken != null}');
      if (userData != null) {
        print('║ UserData length: ${userData.length} chars');
      }
      print('╚═══════════════════════════════════════════════════════╝');
      print('');
      
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

        print('✅ [DASHBOARD] User loaded: ${_currentUser?.name} (ID: ${_currentUser?.id})');

        if (_currentStats?.astrologer != null) {
          _currentUser = _currentStats!.astrologer;
        }
      } else {
        print('⚠️ [DASHBOARD] No user data found, using fallback');
        _setFallbackUser();
      }
    } catch (e) {
      print('❌ [DASHBOARD] Error loading user data: $e');
      print('Stack trace: ${StackTrace.current}');
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
  // PageView Structure (6 pages total):
  // Page 0: Live Prep (HIDDEN - swipe right from Dashboard to reveal)
  // Page 1: Dashboard - Overview with stats and quick actions
  // Page 2: Communication - Live calls and messages (real-time)
  // Page 3: Heal - Community and content feature
  // Page 4: Consultations - Scheduled/pre-booked appointments (calendar-based)
  // Page 5: Profile - Account settings and earnings
  //
  // Bottom Nav Structure (5 items, maps to pages 1-5):
  // Nav 0 → Page 1: Dashboard
  // Nav 1 → Page 2: Communication
  // Nav 2 → Page 3: Heal
  // Nav 3 → Page 4: Consultations
  // Nav 4 → Page 5: Profile
  Widget _buildPageWithAnimation(int index) {
    switch (index) {
      case 0:
        return LivePreparationScreen(
          onClose: () {
            // Navigate back to dashboard page when close is pressed
            _pageController.animateToPage(
              1, // Dashboard page
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ); // Hidden page - swipe right from Dashboard
      case 1:
        return _buildDashboardContent(); // Dashboard
      case 2:
        return const CommunicationScreen(); // Communication
      case 3:
        return const HealScreen(); // Heal
      case 4:
        return const ConsultationsScreen(); // Consultations
      case 5:
        return ProfileScreen(onProfileUpdated: refreshUserData); // Profile
      default:
        return _buildDashboardContent();
    }
  }

  // Method to navigate to specific tab programmatically
  // Maps bottom nav index (0-4) to page index (1-5)
  void navigateToTab(int navIndex) {
    final pageIndex = navIndex + 1; // Add 1 to skip hidden Live Prep page
    if (pageIndex != _currentPageIndex) {
      HapticFeedback.selectionClick();
      _pageController.jumpToPage(pageIndex);
    }
  }
  
  // Method to navigate to Live Prep (hidden page at index 0)
  void _navigateToLivePrep() {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      0, // Live Prep page
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Go Live button method - now navigates to hidden page instead of pushing new screen
  void _goLive() {
    _navigateToLivePrep();
  }

  // Open notifications method
  void _openNotifications() {
    HapticFeedback.selectionClick();
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
    print('🔍 [Dashboard] Opening Communication screen with tab: $tab');
    
    // Map string tab to CommunicationFilter enum
    CommunicationFilter filter;
    switch (tab) {
      case 'calls':
        filter = CommunicationFilter.calls;
        print('✅ [Dashboard] Setting filter to CALLS');
        break;
      case 'messages':
        filter = CommunicationFilter.messages;
        print('✅ [Dashboard] Setting filter to MESSAGES');
        break;
      case 'video':
        filter = CommunicationFilter.video;
        print('✅ [Dashboard] Setting filter to VIDEO');
        break;
      default:
        filter = CommunicationFilter.all;
        print('✅ [Dashboard] Setting filter to ALL');
    }
    
    // Use BLoC to set the filter (not old CommunicationService)
    context.read<CommunicationBloc>().add(FilterCommunicationsEvent(filter));
    
    // Animate to Communication tab (index 2) with smooth sliding
    // Page structure: 0=LivePrep(hidden), 1=Dashboard, 2=Communication, 3=Heal, 4=Consultations, 5=Profile
    _pageController.animateToPage(
      2, // Communication tab index (was 1 before Live Prep page was added)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    print('🚀 [Dashboard] Navigating to Communication tab with filter: $filter');
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

  // Method to reset onboarding for testing
  Future<void> _resetOnboarding() async {
    print('🔄 [DASHBOARD] Resetting onboarding flag');
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text('This will show the onboarding screens again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Show Onboarding'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear the onboarding flag
      await _storageService.setHasSeenOnboarding(false);
      print('✅ [DASHBOARD] Onboarding flag cleared');
      
      // Verify it was cleared
      final checkFlag = await _storageService.getHasSeenOnboarding();
      print('🔍 [DASHBOARD] Verified flag after reset: $checkFlag');
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing onboarding...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Wait a moment then navigate directly to onboarding screen
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      // Navigate directly to onboarding screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive sizes for bottom navigation
    final double navBarHeight = 68.0; // Increased height for improved touch comfort
    final double selectedIconSize = screenWidth < 360 ? 24.0 : 26.0; // Reduced for minimal look
    final double unselectedIconSize = screenWidth < 360 ? 22.0 : 24.0; // Reduced for minimal look
    final double iconWidth = screenWidth < 360 ? 25.0 : screenWidth < 400 ? 27.0 : 29.0; // Reduced for minimal look
    final double svgIconWidth = screenWidth < 360 ? 27.0 : screenWidth < 400 ? 29.0 : 31.0; // Slightly larger for SVG icons
    final double selectedFontSize = screenWidth < 360 ? 9.0 : 11.0;
    final double unselectedFontSize = screenWidth < 360 ? 8.5 : 10.0;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: Stack(
            children: [
              PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(), // Enables smooth swipe gestures
            onPageChanged: (pageIndex) {
              setState(() {
                _currentPageIndex = pageIndex;
                
                // Update bottom nav selection based on page index
                // Page 0 (Live Prep) = hidden, keep Dashboard (nav 0) highlighted
                // Pages 1-5 = map to nav indices 0-4
                if (pageIndex == 0) {
                  // On Live Prep page - keep Dashboard highlighted in nav
                  _selectedIndex = 0;
                } else {
                  // Map page index to bottom nav index (subtract 1)
                  _selectedIndex = pageIndex - 1;
                }
              });
            },
            itemCount: 6, // 6 pages: Live Prep (hidden) + 5 main tabs
            itemBuilder: (context, index) {
              return _buildPageWithAnimation(index);
            },
          ),
          ],
          ),
          bottomNavigationBar: Container(
            height: navBarHeight,
            decoration: BoxDecoration(
              color: themeService.currentTheme.type == AppThemeType.dark 
                  ? themeService.surfaceColor 
                  : Colors.white,
              border: Border(
                top: BorderSide(
                  color: themeService.currentTheme.type == AppThemeType.dark
                      ? themeService.borderColor
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              selectedIconTheme: IconThemeData(size: selectedIconSize),
              unselectedIconTheme: IconThemeData(size: unselectedIconSize),
              currentIndex: _selectedIndex,
              onTap: (navIndex) {
                // Add soft haptic feedback (same for all tabs)
                HapticFeedback.selectionClick();
                
                // Map bottom nav index to page index (add 1 for hidden Live Prep page)
                // Nav 0 → Page 1 (Dashboard)
                // Nav 1 → Page 2 (Communication)
                // Nav 2 → Page 3 (Heal)
                // Nav 3 → Page 4 (Consultations)
                // Nav 4 → Page 5 (Profile)
                final pageIndex = navIndex + 1;
                
                _pageController.jumpToPage(pageIndex);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF10B981), // Emerald green
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              showUnselectedLabels: true,
              selectedFontSize: selectedFontSize,
              unselectedFontSize: unselectedFontSize,
              iconSize: unselectedIconSize,
                items: [
                  BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SvgPicture.asset(
                          AppAssets.dashboardIcon,
                          width: svgIconWidth,
                          height: svgIconWidth,
                          color: _selectedIndex == 0
                              ? const Color(0xFF10B981) // emerald active
                              : Colors.grey,
                        ),
                      ),
                    ),
                    label: l10n.dashboard,
                   ),
                  BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.phone_outlined,
                          size: iconWidth,
                          color: _selectedIndex == 1
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    label: 'Communication',
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.spa,
                          size: iconWidth,
                          color: _selectedIndex == 2
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    label: l10n.heal,
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SvgPicture.asset(
                          AppAssets.calendarIcon,
                          width: svgIconWidth,
                          height: svgIconWidth,
                          color: _selectedIndex == 3
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    label: l10n.consultations,
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.account_circle_outlined,
                          size: iconWidth,
                          color: _selectedIndex == 4
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                    ),
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
    final themeService = Provider.of<ThemeService>(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
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
            print('');
            print('╔═══════════════════════════════════════════════════════╗');
            print('║      🔐 AUTH STATE CHANGED IN DASHBOARD              ║');
            print('╠═══════════════════════════════════════════════════════╣');
            print('║ State Type: ${authState.runtimeType}');
            print('║ Timestamp: ${DateTime.now()}');
            print('╚═══════════════════════════════════════════════════════╝');
            print('');
            
            if (authState is AuthUnauthenticatedState) {
              print('❌ [DASHBOARD] User is UNAUTHENTICATED - Redirecting to LOGIN');
              print('🧭 [DASHBOARD] Navigator.pushReplacementNamed(AppRoutes.login)');
              // User is not authenticated, redirect to login
              Navigator.pushReplacementNamed(context, AppRoutes.login);
              print('✅ [DASHBOARD] Navigation to login triggered');
            } else if (authState is AuthSuccessState) {
              print('✅ [DASHBOARD] User is AUTHENTICATED - Updating user data');
              print('👤 [DASHBOARD] User: ${authState.astrologer.name}');
              // User is authenticated, update current user data
              _updateUserFromAuthState(authState);
            } else {
              print('ℹ️ [DASHBOARD] AuthState is neither Success nor Unauthenticated: ${authState.runtimeType}');
            }
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
            // Show skeleton loader only on initial load with no user data
            if (_currentUser == null) {
              return const DashboardSkeletonLoader();
            }
            
            bool isLoading = false;
            DashboardStatsModel? statsToShow;
            
            if (state is DashboardLoading) {
              // Show progressive loading with placeholder or previous data
              isLoading = true;
              statsToShow = _currentStats ?? DashboardStatsModel(
                todayEarnings: 0,
                totalEarnings: 0,
                callsToday: 0,
                totalCalls: 0,
                isOnline: false,
                totalSessions: 0,
                averageRating: 0,
                averageSessionDuration: 0,
                todayCount: 0,
                astrologer: _currentUser,
              );
            } else if (state is DashboardLoadedState) {
              _currentStats = state.stats; // Store current stats for refresh
              if (state.stats.astrologer != null) {
                _currentUser = state.stats.astrologer;
              }
              isLoading = false;
              statsToShow = state.stats;
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
              isLoading = false;
              statsToShow = _currentStats ?? DashboardStatsModel(
                todayEarnings: 0,
                totalEarnings: 0,
                callsToday: 0,
                totalCalls: 0,
                isOnline: false,
                totalSessions: 0,
                averageRating: 0,
                averageSessionDuration: 0,
                todayCount: 0,
                astrologer: _currentUser,
              );
            }
            
            // Always show the dashboard body with progressive loading
            return _buildDashboardBody(statsToShow!, isLoading: isLoading);
          },
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(stats, {bool isLoading = false}) {
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
                            isLoading: isLoading,
                            onRefresh: () {
                              context.read<DashboardBloc>().add(RefreshDashboardEvent());
                            },
                            onTap: () {
                              // Navigate to earnings screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EarningsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Communication Cards - Redesigned
                          Column(
                            children: [
                              // Calls Today Card - New Design
                              _buildCallsCard(stats.callsToday, isLoading: isLoading),
                              const SizedBox(height: 12),
                              // Messages Today Card - New Design
                              _buildMessagesCard(isLoading: isLoading),
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
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: StatsCardWidget(
                                title: 'Avg Rating',
                                value: stats.averageRating.toStringAsFixed(1),
                                icon: Icons.star,
                                color: AppTheme.ratingColor,
                                isLoading: isLoading,
                                onTap: () => _openReviewsScreen(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatsCardWidget(
                                title: 'My Clients',
                                value: '${stats.totalSessions}', // Using total sessions as client count
                                icon: Icons.people,
                                color: AppTheme.infoColor,
                                isLoading: isLoading,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyClientsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
                          
                          const SizedBox(height: 16),
                          
                          // Test Button for User Profile
                          AnimatedButton(
                            onPressed: () {
                              // Use the first mock client (Priya Sharma - VIP client)
                              final sampleClient = MockClientsData.getMockClients()[0];
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientDetailScreen(
                                    client: sampleClient,
                                  ),
                                ),
                              );
                            },
                            text: 'View Sample User Profile',
                            icon: Icons.person_outline,
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            width: double.infinity,
                            height: 56,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Test Button for Astrologer Profile (End-User View)
                          AnimatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AstrologerProfileScreen(),
                                ),
                              );
                            },
                            text: 'View Astrologer Profile (User View)',
                            icon: Icons.auto_awesome,
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            width: double.infinity,
                            height: 56,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Test Button to Reset Onboarding
                          AnimatedButton(
                            onPressed: _resetOnboarding,
                            text: 'Reset Onboarding (Test)',
                            icon: Icons.refresh,
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            width: double.infinity,
                            height: 56,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 🎨 Empty States Gallery Button - Swiggy Style!
                          AnimatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmptyStateGalleryScreen(),
                                ),
                              );
                            },
                            text: '🎨 View Empty States Gallery',
                            icon: Icons.palette,
                            backgroundColor: const Color(0xFFFC5185),
                            foregroundColor: Colors.white,
                            width: double.infinity,
                            height: 56,
                          ),
                          
                          const SizedBox(height: 32),
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
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent, // Transparent status bar
              statusBarIconBrightness: Brightness.light, // White icons
              statusBarBrightness: Brightness.light, // For iOS
          ),
          child: Container(
            width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeService.primaryColor.withOpacity(0.9), themeService.primaryColor], // Use theme primary color
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
            statusBarStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
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
              // Broadcast icon
              const Icon(
                Icons.sensors,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
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
                    const SizedBox(width: 16),
                    // 3D Discussion Illustration
                    Image.asset(
                      'discussion.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
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
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewsOverviewScreen(),
      ),
    );
  }

  // Redesigned Calls Today Card
  Widget _buildCallsCard(int callsToday, {bool isLoading = false}) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Check if Vedic theme
        final isVedic = themeService.isVedicMode();
        
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _openCommunicationScreen('calls');
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: isVedic 
                ? const Color(0xFFF59E0B).withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            highlightColor: isVedic
                ? const Color(0xFFF59E0B).withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
              // Use solid beige color for Vedic, surface color for others
              color: isVedic ? const Color(0xFFFFF3E0) : themeService.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Left side - Icon container as circle (same size as profile picture)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isVedic 
                        ? const Color(0xFFF59E0B)
                        : themeService.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              const SizedBox(width: 20),
              // Middle - Number and label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const ValueShimmer(
                            width: 60,
                            height: 36,
                            borderRadius: 8,
                          )
                        : Text(
                            callsToday.toString(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: themeService.textPrimary,
                              height: 1.0,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      'Calls Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: themeService.textPrimary,
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
                      color: themeService.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: themeService.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '12%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: themeService.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ),
          ),
        );
      },
    );
  }

  // Redesigned Messages Today Card
  Widget _buildMessagesCard({bool isLoading = false}) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Check if Vedic theme
        final isVedic = themeService.isVedicMode();
        
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _openCommunicationScreen('messages');
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: isVedic 
                ? const Color(0xFFF59E0B).withOpacity(0.2)
                : themeService.primaryColor.withOpacity(0.15),
            highlightColor: isVedic
                ? const Color(0xFFF59E0B).withOpacity(0.1)
                : themeService.primaryColor.withOpacity(0.1),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
              // Use solid beige color for Vedic, surface color for others
              color: isVedic ? const Color(0xFFFFF3E0) : themeService.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Left side - Icon container as circle (same size as profile picture)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              const SizedBox(width: 20),
              // Middle - Number and label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const ValueShimmer(
                            width: 60,
                            height: 36,
                            borderRadius: 8,
                          )
                        : Text(
                            '12',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: themeService.textPrimary,
                              height: 1.0,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      'Messages Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: themeService.textPrimary,
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
                      color: themeService.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: themeService.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '8%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: themeService.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
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
