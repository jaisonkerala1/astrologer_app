import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/language_service.dart';
import 'core/services/status_service.dart';
import 'core/services/app_restart_service.dart';
import 'app/app.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService().initialize();
  ApiService().initialize();
  final languageService = LanguageService();
  await languageService.initialize();
  final statusService = StatusService();
  await statusService.initialize();
  
  print('Main: Language service initialized with locale: ${languageService.currentLocale}');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(RestartWidget(
    child: App(languageService: languageService, statusService: statusService),
  ));
}

