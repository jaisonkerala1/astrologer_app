import '../../../features/notifications/models/notification_model.dart';

/// Abstract interface for Notifications operations
abstract class NotificationsRepository {
  // Notifications CRUD
  Future<List<NotificationModel>> getNotifications({
    NotificationStatus? status,
    NotificationType? type,
    int page = 1,
    int limit = 20,
  });
  Future<NotificationModel> getNotificationById(String id);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> deleteAllNotifications();
  Future<void> archiveNotification(String id);
  
  // Notification Stats
  Future<NotificationStats> getNotificationStats();
  Future<int> getUnreadCount();
  
  // Batch Operations
  Future<void> markMultipleAsRead(List<String> ids);
  Future<void> deleteMultiple(List<String> ids);
  Future<void> archiveMultiple(List<String> ids);
  
  // Filtering
  Future<List<NotificationModel>> filterNotifications({
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
  });
}


