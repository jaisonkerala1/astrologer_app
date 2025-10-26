import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../base_repository.dart';
import 'notifications_repository.dart';

class NotificationsRepositoryImpl extends BaseRepository implements NotificationsRepository {
  final ApiService apiService;
  final StorageService storageService;

  NotificationsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<List<NotificationModel>> getNotifications({
    NotificationStatus? status,
    NotificationType? type,
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with real API call when backend is ready
    // For now, return dummy data to avoid 404 errors
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return dummy notifications
      return _getDummyNotifications();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }
  
  List<NotificationModel> _getDummyNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        title: 'New Consultation Request',
        body: 'You have a new consultation request from Priya Sharma for Vedic Astrology reading.',
        type: NotificationType.consultationRequest,
        status: NotificationStatus.unread,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isActionable: true,
        actionText: 'View Request',
        actionUrl: '/consultations',
      ),
      NotificationModel(
        id: '2',
        title: 'Payment Received',
        body: 'Payment of ₹500 received for consultation with Raj Kumar.',
        type: NotificationType.paymentReceived,
        status: NotificationStatus.unread,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: '3',
        title: 'Review Received',
        body: 'Anita Desai left you a 5-star review: "Excellent astrologer! Very accurate predictions."',
        type: NotificationType.reviewReceived,
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: '4',
        title: 'Upcoming Consultation',
        body: 'Reminder: You have a consultation with Vikram Singh in 30 minutes.',
        type: NotificationType.reminder,
        status: NotificationStatus.read,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 3)),
        isActionable: true,
        actionText: 'Prepare',
        actionUrl: '/consultations/upcoming',
      ),
      NotificationModel(
        id: '5',
        title: 'Profile Update',
        body: 'Your profile has been successfully updated and is now live.',
        type: NotificationType.systemUpdate,
        status: NotificationStatus.read,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: '6',
        title: 'New Message',
        body: 'Meera Patel sent you a message regarding her horoscope analysis.',
        type: NotificationType.messageReceived,
        status: NotificationStatus.unread,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 4)),
        isActionable: true,
        actionText: 'Reply',
        actionUrl: '/communication',
      ),
      NotificationModel(
        id: '7',
        title: 'Consultation Completed',
        body: 'Your consultation with Rohit Verma has been marked as completed. Payment of ₹800 will be processed.',
        type: NotificationType.consultationCompleted,
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: '8',
        title: 'Weekly Earnings Summary',
        body: 'Your earnings for this week: ₹12,500 from 25 consultations. Great job!',
        type: NotificationType.paymentReceived,
        status: NotificationStatus.read,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<NotificationModel> getNotificationById(String id) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final notifications = _getDummyNotifications();
      return notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => throw Exception('Notification not found'),
      );
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      // Mock success - in real app, this would update backend
      print('Notification $id marked as read (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> markAllAsRead() async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      print('All notifications marked as read (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      print('Notification $id deleted (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteAllNotifications() async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      print('All notifications deleted (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> archiveNotification(String id) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      print('Notification $id archived (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<NotificationStats> getNotificationStats() async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Return dummy stats based on dummy notifications
      final notifications = _getDummyNotifications();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      return NotificationStats(
        total: notifications.length,
        unread: notifications.where((n) => n.status == NotificationStatus.unread).length,
        read: notifications.where((n) => n.status == NotificationStatus.read).length,
        archived: 0,
        urgent: notifications.where((n) => n.priority == NotificationPriority.high).length,
        today: notifications.where((n) => n.createdAt.isAfter(todayStart)).length,
      );
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<int> getUnreadCount() async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final notifications = _getDummyNotifications();
      return notifications.where((n) => n.status == NotificationStatus.unread).length;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> markMultipleAsRead(List<String> ids) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      print('Notifications ${ids.join(", ")} marked as read (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteMultiple(List<String> ids) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      print('Notifications ${ids.join(", ")} deleted (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> archiveMultiple(List<String> ids) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      print('Notifications ${ids.join(", ")} archived (mock)');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<NotificationModel>> filterNotifications({
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      var notifications = _getDummyNotifications();
      
      // Apply filters
      if (type != null) {
        notifications = notifications.where((n) => n.type == type).toList();
      }
      if (priority != null) {
        notifications = notifications.where((n) => n.priority == priority).toList();
      }
      if (startDate != null) {
        notifications = notifications.where((n) => n.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        notifications = notifications.where((n) => n.createdAt.isBefore(endDate)).toList();
      }
      
      return notifications;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

}

