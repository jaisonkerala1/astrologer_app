// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astrologer_app/app/app.dart';
import 'package:astrologer_app/core/services/language_service.dart';
import 'package:astrologer_app/core/services/status_service.dart';
import 'package:astrologer_app/features/notifications/services/notification_service.dart';
import 'package:astrologer_app/features/live/services/live_stream_service.dart';
import 'package:astrologer_app/shared/theme/services/theme_service.dart';

void main() {
  testWidgets('App builds without crashing', (tester) async {
    await tester.pumpWidget(AstrologerApp(
      languageService: LanguageService(),
      statusService: StatusService(),
      notificationService: NotificationService(),
      liveStreamService: LiveStreamService(),
      themeService: ThemeService(),
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
