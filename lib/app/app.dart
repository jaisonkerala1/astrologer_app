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
import '../features/communication/bloc/call_event.dart';
import '../features/communication/screens/incoming_call_screen.dart';
import '../features/communication/screens/chat_screen.dart';
import '../features/communication/screens/voice_call_screen.dart';
import '../features/communication/screens/video_call_screen.dart';
import '../features/communication/models/communication_item.dart';
import '../core/services/fcm_service.dart';
import '../features/heal/bloc/heal_bloc.dart';
import '../features/help_support/bloc/help_support_bloc.dart';
import '../features/live/bloc/live_bloc.dart';
import '../features/notifications/bloc/notifications_bloc.dart';
import '../features/reviews/bloc/reviews_bloc.dart';
import '../core/fcm/fcm_bloc.dart';
import '../core/fcm/fcm_state.dart';
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
  // Root navigator key so we can present incoming call UI from anywhere
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  // Hold references to singletons to keep them alive
  late final FcmBloc _fcmBloc;
  late final CallBloc _callBloc;

  @override
  void initState() {
    super.initState();
    // Listen to language changes
    widget.languageService.addListener(_onLanguageChanged);
    
    // CRITICAL: Initialize FcmBloc (for background notifications)
    print('🚀 [APP] Initializing FcmBloc...');
    _fcmBloc = getIt<FcmBloc>();
    print('✅ [APP] FcmBloc initialized');
    
    // CRITICAL: Initialize CallBloc (for foreground Socket.IO calls)
    print('🚀 [APP] Initializing CallBloc...');
    _callBloc = getIt<CallBloc>();
    print('✅ [APP] CallBloc initialized: ${_callBloc.runtimeType}');
    print('✅ [APP] Socket service: ${_callBloc.socketService}');
    print('✅ [APP] Socket connected: ${_callBloc.socketService.isConnected}');
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
          BlocProvider<FcmBloc>.value(
            value: _fcmBloc, // FCM for background notifications
          ),
          BlocProvider<CallBloc>.value(
            value: _callBloc, // CallBloc for call management
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
          navigatorKey: _rootNavigatorKey,
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
            // Listen to both FCM (background) and CallBloc (foreground) for incoming calls
            return MultiBlocListener(
              listeners: [
                // Listen to FCM notifications (background/locked phone)
                BlocListener<FcmBloc, FcmState>(
                  listener: (context, state) {
                    if (state is FcmIncomingCallNotification) {
                      print('🔔 [APP] FCM call notification received, triggering CallBloc');
                      // Trigger CallBloc to handle the incoming call
                      context.read<CallBloc>().add(
                        IncomingCallEvent(
                          callId: state.callData['callId'] ?? '',
                          callerId: state.callData['callerId'] ?? '',
                          callerName: state.callData['callerName'] ?? 'Unknown',
                          callerType: state.callData['callerType'] ?? 'user',
                          callType: state.isVideo ? 'video' : 'voice',
                          channelName: state.callData['channelName'] ?? '',
                          agoraToken: state.callData['agoraToken'] ?? '',
                          agoraAppId: state.callData['agoraAppId'] ?? '',
                          callerAvatar: state.callData['callerAvatar'],
                        ),
                      );
                    } else if (state is FcmCallAccepted) {
                      print('✅ [APP] Call accepted from notification button, going directly to call screen');
                      
                      // User pressed Accept button in notification → Skip IncomingCallScreen, go directly to call
                      final callData = state.callData;
                      final isVideo = state.isVideo;
                      
                      // Navigate directly to Voice/VideoCallScreen
                      if (isVideo) {
                        _rootNavigatorKey.currentState?.push(
                          MaterialPageRoute(
                            builder: (context) => VideoCallScreen(
                              contactId: callData['callerId'] ?? '',
                              contactName: callData['callerName'] ?? 'Unknown',
                              contactType: callData['callerType'] == 'admin' 
                                  ? ContactType.admin 
                                  : ContactType.user,
                              isIncoming: true,
                              callId: callData['callId'] ?? '',
                              channelName: callData['channelName'] ?? '',
                              token: callData['agoraToken'] ?? '',
                              avatarUrl: callData['callerAvatar'],
                            ),
                          ),
                        );
                      } else {
                        _rootNavigatorKey.currentState?.push(
                          MaterialPageRoute(
                            builder: (context) => VoiceCallScreen(
                              callId: callData['callId'] ?? '',
                              contactId: callData['callerId'] ?? '',
                              contactName: callData['callerName'] ?? 'Unknown',
                              contactType: callData['callerType'] == 'admin' 
                                  ? ContactType.admin 
                                  : ContactType.user,
                              channelName: callData['channelName'] ?? '',
                              token: callData['agoraToken'] ?? '',
                              agoraAppId: callData['agoraAppId'] ?? '6358473261094f98be1fea84042b1fcf',
                              avatarUrl: callData['callerAvatar'],
                            ),
                          ),
                        );
                      }
                      
                      // Trigger CallBloc to accept in the background (for Socket.IO sync)
                      context.read<CallBloc>().add(
                        AcceptCallEvent(
                          callId: callData['callId'] ?? '',
                          contactId: callData['callerId'] ?? '',
                          channelName: callData['channelName'],
                          agoraToken: callData['agoraToken'],
                          agoraAppId: callData['agoraAppId'],
                          isVideo: isVideo,
                        ),
                      );
                    } else if (state is FcmCallDeclined) {
                      print('❌ [APP] Call declined from notification');
                      final callBloc = context.read<CallBloc>();
                      
                      // Decline the call
                      callBloc.add(
                        DeclineCallEvent(
                          callId: state.callData['callId'] ?? '',
                        ),
                      );
                      
                      // Cancel the notification
                      final fcmService = getIt<FcmService>();
                      fcmService.cancelCallNotification(state.callData['callId'] ?? '');
                    } else if (state is FcmNavigateToChat) {
                      print('💬 [APP] Navigating to chat: ${state.conversationId}');
                      // Navigate to chat screen (WhatsApp-like behavior)
                      _rootNavigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            contactId: state.senderId,
                            contactName: state.senderName,
                            contactType: state.senderType == 'admin' 
                                ? ContactType.admin 
                                : ContactType.user,
                            conversationId: state.conversationId,
                            avatarUrl: null,
                          ),
                        ),
                      );
                    }
                  },
                ),

                // Listen to CallBloc (foreground Socket.IO or triggered by FCM)
                BlocListener<CallBloc, CallState>(
                  listener: (context, state) {
                    if (state is CallIncoming) {
                      print('📞 [APP] Showing incoming call screen');
                      _rootNavigatorKey.currentState?.push(
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
                            agoraAppId: state.agoraAppId,
                            channelName: state.channelName,
                            avatarUrl: state.callerAvatar,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
              child: OfflineIndicator(child: child!),
            );
          },
        ),
      ),
    );
  }
}
