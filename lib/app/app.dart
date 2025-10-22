import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/services/language_service.dart';
import '../core/services/status_service.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/live/services/live_stream_service.dart';
import '../features/communication/services/communication_service.dart';
import '../shared/theme/services/theme_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/dashboard/bloc/dashboard_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/consultations/bloc/consultations_bloc.dart';
import '../features/reviews/bloc/reviews_bloc.dart';
import '../features/reviews/repository/reviews_repository.dart';
import '../shared/theme/app_theme.dart';
import 'routes.dart';
import '../features/auth/bloc/auth_event.dart';
import '../core/services/api_service.dart';

class AstrologerApp extends StatefulWidget {
  final LanguageService languageService;
  final StatusService statusService;
  final NotificationService notificationService;
  final LiveStreamService liveStreamService;
  final ThemeService themeService;
  
  const AstrologerApp({
    super.key, 
    required this.languageService, 
    required this.statusService,
    required this.notificationService,
    required this.liveStreamService,
    required this.themeService,
  });

  @override
  State<AstrologerApp> createState() => _AstrologerAppState();
}

class _AstrologerAppState extends State<AstrologerApp> {
  @override
  void initState() {
    super.initState();
    // Listen to language changes
    widget.languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    widget.languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    print('App: Language changed to ${widget.languageService.currentLocale}');
    setState(() {
      // This will trigger a rebuild with the new language
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>(
          create: (context) => widget.languageService,
        ),
        ChangeNotifierProvider<StatusService>(
          create: (context) => widget.statusService,
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (context) => widget.notificationService,
        ),
        Provider<LiveStreamService>(
          create: (context) => LiveStreamService(),
        ),
        ChangeNotifierProvider<CommunicationService>(
          create: (context) => CommunicationService(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (context) => widget.themeService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc()..add(InitializeAuthEvent()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(),
          ),
          BlocProvider<ConsultationsBloc>(
            create: (context) => ConsultationsBloc(),
          ),
          BlocProvider<ReviewsBloc>(
            create: (context) => ReviewsBloc(
              reviewsRepository: ReviewsRepository(
                apiService: ApiService(),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          // Removed key to prevent full app restart on language change
          // The locale property alone is sufficient for l10n updates
          title: 'Astrologer App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          locale: widget.languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('hi', ''), // Hindi
          ],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) {
            return child!;
          },
        ),
      ),
    );
  }
}
