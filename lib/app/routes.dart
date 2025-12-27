import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/approval_waiting_screen.dart';
import '../features/auth/models/astrologer_model.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../features/auth/bloc/auth_state.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/fcm_service.dart';
import '../core/di/service_locator.dart';
import '../core/constants/api_constants.dart';
import '../features/dashboard/bloc/dashboard_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/consultations/screens/consultation_analytics_screen.dart';
import '../features/live/screens/live_streams_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String approvalWaiting = '/approval-waiting';
  static const String dashboard = '/dashboard';
  static const String consultationAnalytics = '/consultation-analytics';
  static const String liveStreams = '/live-streams';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case approvalWaiting:
        final args = settings.arguments as Map<String, dynamic>?;
        final astrologer = args?['astrologer'];
        return MaterialPageRoute(
          builder: (_) => ApprovalWaitingScreen(astrologer: astrologer),
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      case consultationAnalytics:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTabIndex = args?['initialTabIndex'] as int? ?? 2;
        return MaterialPageRoute(
          builder: (_) => ConsultationAnalyticsScreen(initialTabIndex: initialTabIndex),
        );
      case liveStreams:
        return MaterialPageRoute(
          builder: (_) => const LiveStreamsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('🎬 [SPLASH] SplashScreen initState called');
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    print('🚀 [SPLASH] Starting _checkAuthAndNavigate...');
    final startTime = DateTime.now();
    
    // Remove artificial delay for faster startup
    print('⏳ [SPLASH] Skipping artificial delay');
    
    if (!mounted) {
      print('❌ [SPLASH] Widget not mounted after delay, aborting');
      return;
    }
    
    // Use already-initialized StorageService from DI
    print('💾 [SPLASH] Using StorageService from DI');
    final storage = getIt<StorageService>();
    
    // Read all storage values in parallel for better performance
    print('📖 [SPLASH] Reading storage values in parallel...');
    final storageReadStart = DateTime.now();
    final results = await Future.wait([
      storage.getHasSeenOnboarding(),
      storage.getIsLoggedIn(),
      storage.getAuthToken(),
    ]);
    print('✅ [SPLASH] Storage values read (took ${DateTime.now().difference(storageReadStart).inMilliseconds}ms)');
    
    final hasSeenOnboarding = results[0] as bool?;
    final isLoggedIn = results[1] as bool?;
    final token = results[2] as String?;
    
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║           SPLASH SCREEN DEBUG REPORT                  ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ hasSeenOnboarding: $hasSeenOnboarding');
    print('║ hasSeenOnboarding type: ${hasSeenOnboarding.runtimeType}');
    print('║ hasSeenOnboarding != true: ${hasSeenOnboarding != true}');
    print('║ isLoggedIn: $isLoggedIn');
    print('║ hasToken: ${token != null}');
    print('║ Total time so far: ${DateTime.now().difference(startTime).inMilliseconds}ms');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    
    // First time user - show onboarding
    if (hasSeenOnboarding != true) {
      print('✅✅✅ [SPLASH] CONDITION MET: Navigating to ONBOARDING ✅✅✅');
      if (!mounted) {
        print('❌ [SPLASH] Widget not mounted before navigation, aborting');
        return;
      }
      print('🧭 [SPLASH] Calling Navigator.pushReplacementNamed(AppRoutes.onboarding)');
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      print('✅ [SPLASH] Navigation command sent to ONBOARDING');
      return;
    }
    
    print('❌❌❌ [SPLASH] CONDITION NOT MET: Skipping onboarding (hasSeenOnboarding is true) ❌❌❌');
    
    print('🔐 [SPLASH] Auth check - isLoggedIn: $isLoggedIn, hasToken: ${token != null}');
    
    if (!mounted) {
      print('❌ [SPLASH] Widget not mounted, aborting');
      return;
    }
    
    // Navigate based on auth status
    if (isLoggedIn == true && token != null) {
      // ✅ VALIDATE TOKEN WITH SERVER (Prevents flash to dashboard)
      print('🔐 [SPLASH] Token found locally, validating with server...');
      final apiService = ApiService();
      apiService.setAuthToken(token);
      
      try {
        final validationStart = DateTime.now();
        final response = await apiService.get(ApiConstants.profile);
        print('✅ [SPLASH] Token validation response received (took ${DateTime.now().difference(validationStart).inMilliseconds}ms)');
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          print('✅ [SPLASH] Token VALID - User authenticated');
          print('👤 [SPLASH] User: ${response.data['data']['name']}');
          
          // Check if account is approved
          final isApproved = response.data['data']['isApproved'] ?? false;
          print('🔐 [SPLASH] Account approval status: $isApproved');
          
          if (!mounted) {
            print('❌ [SPLASH] Widget not mounted, aborting');
            return;
          }

          // If not approved, navigate to approval waiting screen
          if (!isApproved) {
            print('⏳ [SPLASH] Account not approved - navigating to approval waiting screen');
            final astrologerData = response.data['data'];
            final astrologer = AstrologerModel.fromJson(astrologerData);
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.approvalWaiting,
              arguments: {'astrologer': astrologer},
            );
            return;
          }

          // WhatsApp-style cold start orchestration:
          // 1) If there is a pending CALL intent from native (force-stopped), handle it first.
          // 2) Else, if there is a MESSAGE initialMessage, open chat directly.
          final fcmService = getIt<FcmService>();

          print('📞 [SPLASH] Checking for pending call intent...');
          final pendingCallIntent = await fcmService.getPendingCallIntent();
          if (pendingCallIntent != null) {
            print('📞 [SPLASH] Pending call intent detected - routing to call UI');
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            // Mark boot complete before emitting to avoid Splash -> Dashboard disposing call UI.
            Future.microtask(() {
              fcmService.markBootstrapped();
              fcmService.processCallIntent(pendingCallIntent);
            });
            return;
          }

          // Check if app was opened from FCM notification (chat/message)
          // WhatsApp-style: Go directly to chat, but have Dashboard in the stack
          print('🔔 [SPLASH] Checking for FCM initial message...');
          final fcmInitialMessage = await FirebaseMessaging.instance.getInitialMessage();

          if (fcmInitialMessage != null) {
            final notificationType = fcmInitialMessage.data['type'] as String?;
            if (notificationType == 'message' || notificationType == 'chat') {
              print('💬 [SPLASH] Message notification detected - going directly to chat (WhatsApp-style)');
              // Navigate to Dashboard first (silently builds navigation stack)
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              // Immediately emit to FCM - ChatScreen will push on top in same frame
              fcmService.markBootstrapped();
              fcmService.emitMessageNotification(fcmInitialMessage);
              return;
            }
          }
          
          // Normal flow: just go to Dashboard
          print('🧭 [SPLASH] Navigating to DASHBOARD');
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          fcmService.markBootstrapped();
          print('✅ [SPLASH] Navigation command sent to DASHBOARD');
        } else {
          print('❌ [SPLASH] Token INVALID - Server returned error');
          await _clearAuthAndGoToLogin(storage);
        }
      } catch (e) {
        print('❌ [SPLASH] Token validation failed: $e');
        
        // Check if it's a 401 error (expired token)
        if (e.toString().contains('401')) {
          print('⚠️ [SPLASH] Token expired (401), clearing auth data');
          await _clearAuthAndGoToLogin(storage);
        } else {
          // Network error or server down - allow offline access
          print('⚠️ [SPLASH] Network error, allowing offline dashboard access');
          
          if (!mounted) return;

          // WhatsApp-style cold start orchestration (offline):
          // 1) Pending CALL intent first
          // 2) Else MESSAGE initialMessage
          final fcmService = getIt<FcmService>();

          print('📞 [SPLASH] Checking for pending call intent (offline mode)...');
          final pendingCallIntent = await fcmService.getPendingCallIntent();
          if (pendingCallIntent != null) {
            print('📞 [SPLASH] Pending call intent detected (offline) - routing to call UI');
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            Future.microtask(() {
              fcmService.markBootstrapped();
              fcmService.processCallIntent(pendingCallIntent);
            });
            return;
          }

          // Check for FCM initial message even in offline mode
          // WhatsApp-style: Go directly to chat, but have Dashboard in the stack
          print('🔔 [SPLASH] Checking for FCM initial message (offline mode)...');
          final fcmInitialMessage = await FirebaseMessaging.instance.getInitialMessage();

          if (fcmInitialMessage != null) {
            final notificationType = fcmInitialMessage.data['type'] as String?;
            if (notificationType == 'message' || notificationType == 'chat') {
              print('💬 [SPLASH] Message notification detected (offline) - going directly to chat');
              // Navigate to Dashboard first (silently builds navigation stack)
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              // Immediately emit to FCM - ChatScreen will push on top in same frame
              fcmService.markBootstrapped();
              fcmService.emitMessageNotification(fcmInitialMessage);
              return;
            }
          }
          
          // Normal flow: just go to Dashboard
          print('🧭 [SPLASH] Navigating to DASHBOARD (offline mode)');
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          fcmService.markBootstrapped();
          print('✅ [SPLASH] Navigation command sent to DASHBOARD (offline)');
        }
      }
    } else {
      print('🧭 [SPLASH] User not authenticated, navigating to LOGIN');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      print('✅ [SPLASH] Navigation command sent to LOGIN');
    }
    
    print('🏁 [SPLASH] _checkAuthAndNavigate complete (total: ${DateTime.now().difference(startTime).inMilliseconds}ms)');
  }
  
  /// Clear auth data and navigate to login
  Future<void> _clearAuthAndGoToLogin(StorageService storage) async {
    print('🧹 [SPLASH] Clearing expired auth data...');
    await storage.clearAuthData();
    print('✅ [SPLASH] Auth data cleared');
    
    if (!mounted) {
      print('❌ [SPLASH] Widget not mounted, aborting');
      return;
    }
    
    print('🧭 [SPLASH] Navigating to LOGIN');
    Navigator.pushReplacementNamed(context, AppRoutes.login);
    print('✅ [SPLASH] Navigation command sent to LOGIN');
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [SPLASH] Building SplashScreen widget');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content - centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo with modern circular container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1), // Indigo-500
                          Color(0xFF8B5CF6), // Violet-500
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App name with modern typography
                  Text(
                    'AstroGuru',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Connect. Guide. Transform.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom loading indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Column(
                children: [
                  // Modern minimal progress indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF6366F1).withOpacity(0.8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Powered by text
                  Text(
                    'Empowering Astrologers',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}






