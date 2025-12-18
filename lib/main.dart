import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/di/service_locator.dart';
import 'core/services/language_service.dart';
import 'core/services/status_service.dart';
import 'core/services/app_restart_service.dart';
import 'core/services/connectivity_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/live/services/live_stream_service.dart';
import 'features/communication/bloc/call_bloc.dart';
import 'shared/theme/services/theme_service.dart';
import 'app/app.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await setupServiceLocator();
  
  // Eagerly initialize CallBloc so socket connects immediately
  // This ensures incoming calls/messages work even before opening chat
  try {
    final callBloc = getIt<CallBloc>();
    debugPrint('✅ [MAIN] CallBloc initialized eagerly: ${callBloc.runtimeType}');
    debugPrint('✅ [MAIN] Socket connected: ${callBloc.socketService.isConnected}');
  } catch (e, stackTrace) {
    debugPrint('❌ [MAIN] Failed to initialize CallBloc: $e');
    debugPrint('❌ [MAIN] StackTrace: $stackTrace');
  }
  
  // Set system UI overlay style for transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // White icons on blue background
      statusBarBrightness: Brightness.light, // For iOS - light content on dark background
      systemNavigationBarColor: Colors.white, // Keep navigation bar white
      systemNavigationBarIconBrightness: Brightness.dark, // Dark icons on white nav bar
    ),
  );
  
  // Initialize services (Storage and API already initialized in service locator)
  final languageService = LanguageService();
  final statusService = StatusService();
  final connectivityService = ConnectivityService();
  final notificationService = NotificationService();
  final liveStreamService = LiveStreamService();
  final themeService = ThemeService();
  
  // Kick off non-critical initializations in background (do not block first frame)
  // These services will notify listeners when ready
  // Avoid awaiting here to minimize time before runApp
  // ignore: discarded_futures
  languageService.initialize();
  // ignore: discarded_futures
  statusService.initialize();
  // ignore: discarded_futures
  connectivityService.initialize();
  // ignore: discarded_futures
  notificationService.initialize();
  // ignore: discarded_futures
  themeService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(RestartWidget(
    child: AstrologerApp(
      languageService: languageService, 
      statusService: statusService,
      connectivityService: connectivityService,
      notificationService: notificationService,
      liveStreamService: liveStreamService,
      themeService: themeService,
    ),
  ));
}

