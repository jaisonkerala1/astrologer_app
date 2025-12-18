import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/services/language_service.dart';
import '../core/services/status_service.dart';
import '../core/services/connectivity_service.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/live/services/live_stream_service.dart';
import '../features/communication/services/communication_service.dart';
import '../shared/theme/services/theme_service.dart';
import '../shared/widgets/offline_indicator.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/dashboard/bloc/dashboard_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/consultations/bloc/consultations_bloc.dart';
import '../features/calendar/bloc/calendar_bloc.dart';
import '../features/earnings/bloc/earnings_bloc.dart';
import '../features/communication/bloc/communication_bloc.dart';
import '../features/communication/bloc/call_bloc.dart';
import '../features/communication/bloc/call_state.dart';
import '../features/communication/screens/incoming_call_screen.dart';
import '../features/communication/models/communication_item.dart';
import '../features/heal/bloc/heal_bloc.dart';
import '../features/help_support/bloc/help_support_bloc.dart';
import '../features/live/bloc/live_bloc.dart';
import '../features/notifications/bloc/notifications_bloc.dart';
import '../features/reviews/bloc/reviews_bloc.dart';
import '../shared/theme/app_theme.dart';
import 'routes.dart';
import '../features/auth/bloc/auth_event.dart';
import '../core/di/service_locator.dart';

class AstrologerApp extends StatefulWidget {
  final LanguageService languageService;
  final StatusService statusService;
  final ConnectivityService connectivityService;
  final NotificationService notificationService;
  final LiveStreamService liveStreamService;
  final ThemeService themeService;
  
  const AstrologerApp({
    super.key, 
    required this.languageService, 
    required this.statusService,
    required this.connectivityService,
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
        ChangeNotifierProvider<ConnectivityService>(
          create: (context) => widget.connectivityService,
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (context) => widget.notificationService,
        ),
        Provider<LiveStreamService>(
          create: (context) => widget.liveStreamService,
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
            create: (context) => getIt<AuthBloc>()..add(InitializeAuthEvent()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => getIt<DashboardBloc>(),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => getIt<ProfileBloc>(),
          ),
          BlocProvider<ConsultationsBloc>(
            create: (context) => getIt<ConsultationsBloc>(),
          ),
          BlocProvider<CalendarBloc>(
            create: (context) => getIt<CalendarBloc>(),
          ),
          BlocProvider<EarningsBloc>(
            create: (context) => getIt<EarningsBloc>(),
          ),
          BlocProvider<CommunicationBloc>(
            create: (context) => getIt<CommunicationBloc>(),
          ),
          BlocProvider<CallBloc>(
            create: (context) => getIt<CallBloc>(),
          ),
          BlocProvider<HealBloc>(
            create: (context) => getIt<HealBloc>(),
          ),
          BlocProvider<HelpSupportBloc>(
            create: (context) => getIt<HelpSupportBloc>(),
          ),
          BlocProvider<LiveBloc>(
            create: (context) => getIt<LiveBloc>(),
          ),
          BlocProvider<NotificationsBloc>(
            create: (context) => getIt<NotificationsBloc>(),
          ),
          BlocProvider<ReviewsBloc>(
            create: (context) => getIt<ReviewsBloc>(),
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
            // Listen inside MaterialApp so Navigator exists in context
            return BlocListener<CallBloc, CallState>(
              listener: (context, state) {
                if (state is CallIncoming) {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => IncomingCallScreen(
                        callId: state.callId,
                        contactId: state.callerId,
                        contactName: state.callerName,
                        contactType: state.contactType,
                        phoneNumber: '', // Not provided in call event
                        callType: state.callType,
                        agoraToken: state.agoraToken,
                        channelName: state.channelName,
                        avatarUrl: state.callerAvatar,
                      ),
                    ),
                  );
                }
              },
              child: OfflineIndicator(child: child!),
            );
          },
        ),
      ),
    );
  }
}
