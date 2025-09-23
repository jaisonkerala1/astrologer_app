import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_model.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    
    // Request notification permission
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Show dialog explaining why permission is needed
      return false;
    } else if (status.isPermanentlyDenied) {
      // Show dialog to go to settings
      return false;
    }
    
    return false;
  }

  static Future<bool> checkPermissions() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<bool> sendTestNotification() async {
    await initialize();

    // Check if permissions are granted
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      return false;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Test Notification',
      'This is a test notification from your astrologer app!',
      details,
      payload: 'test_notification',
    );

    return true;
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType? type,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'main_channel',
      'Astrologer App Notifications',
      channelDescription: 'Main notification channel for astrologer app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> sendConsultationNotification({
    required String clientName,
    required String time,
  }) async {
    await sendNotification(
      title: 'New Consultation Request',
      body: '$clientName has requested a consultation at $time',
      type: NotificationType.consultationRequest,
      payload: 'consultation_request',
    );
  }

  static Future<void> sendPaymentNotification({
    required String amount,
    required String clientName,
  }) async {
    await sendNotification(
      title: 'Payment Received',
      body: 'You received ₹$amount from $clientName',
      type: NotificationType.paymentReceived,
      payload: 'payment_received',
    );
  }

  static Future<void> sendMessageNotification({
    required String clientName,
    required String message,
  }) async {
    await sendNotification(
      title: 'New Message from $clientName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: NotificationType.messageReceived,
      payload: 'new_message',
    );
  }

  static Future<void> sendReviewNotification({
    required String clientName,
    required int rating,
  }) async {
    await sendNotification(
      title: 'New Review Received',
      body: '$clientName gave you $rating stars!',
      type: NotificationType.reviewReceived,
      payload: 'new_review',
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
