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

class AppRoutes {
  static const String splash = '/';
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
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for minimum time
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    // Check if user is already authenticated
    final storage = StorageService();
    await storage.initialize();
    final isLoggedIn = await storage.getIsLoggedIn();
    final token = await storage.getAuthToken();
    
    print('SplashScreen: Auth check - isLoggedIn: $isLoggedIn, hasToken: ${token != null}');
    
    if (!mounted) return;
    
    // Navigate based on auth status
    if (isLoggedIn == true && token != null) {
      print('SplashScreen: User authenticated, going to dashboard');
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      print('SplashScreen: User not authenticated, going to login');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
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






