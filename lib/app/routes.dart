import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../features/auth/bloc/auth_state.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../features/dashboard/bloc/dashboard_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/consultations/screens/consultation_analytics_screen.dart';
import '../features/live/screens/live_streams_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
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
    
    // Reduced splash delay for faster startup
    print('⏳ [SPLASH] Starting 500ms delay...');
    await Future.delayed(const Duration(milliseconds: 500));
    print('✅ [SPLASH] Delay complete (took ${DateTime.now().difference(startTime).inMilliseconds}ms)');
    
    if (!mounted) {
      print('❌ [SPLASH] Widget not mounted after delay, aborting');
      return;
    }
    
    // Initialize storage and check app state
    print('💾 [SPLASH] Initializing StorageService...');
    final storageInitStart = DateTime.now();
    final storage = StorageService();
    await storage.initialize();
    print('✅ [SPLASH] StorageService initialized (took ${DateTime.now().difference(storageInitStart).inMilliseconds}ms)');
    
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
      print('🧭 [SPLASH] User authenticated, navigating to DASHBOARD');
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      print('✅ [SPLASH] Navigation command sent to DASHBOARD');
    } else {
      print('🧭 [SPLASH] User not authenticated, navigating to LOGIN');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      print('✅ [SPLASH] Navigation command sent to LOGIN');
    }
    
    print('🏁 [SPLASH] _checkAuthAndNavigate complete (total: ${DateTime.now().difference(startTime).inMilliseconds}ms)');
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [SPLASH] Building SplashScreen widget');
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Astrologer App',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your astrology practice',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}






