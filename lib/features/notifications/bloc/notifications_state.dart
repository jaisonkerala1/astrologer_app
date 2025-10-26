import 'package:equatable/equatable.dart';
import '../models/notification_model.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  final bool isInitialLoad;
  const NotificationsLoading({this.isInitialLoad = true});
  @override
  List<Object?> get props => [isInitialLoad];
}

class NotificationsLoadedState extends NotificationsState {
  final List<NotificationModel> notifications;
  final NotificationStats? stats;
  final NotificationModel? selectedNotification;
  final String? successMessage;
  final NotificationStatus? currentFilter;

  const NotificationsLoadedState({
    required this.notifications,
    this.stats,
    this.selectedNotification,
    this.successMessage,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
    notifications,
    stats,
    selectedNotification,
    successMessage,
    currentFilter,
  ];

  NotificationsLoadedState copyWith({
    List<NotificationModel>? notifications,
    NotificationStats? stats,
    NotificationModel? selectedNotification,
    String? successMessage,
    NotificationStatus? currentFilter,
    bool clearSelectedNotification = false,
  }) {
    return NotificationsLoadedState(
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      selectedNotification: clearSelectedNotification 
          ? null 
          : (selectedNotification ?? this.selectedNotification),
      successMessage: successMessage,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  // Helpers
  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => n.isUnread).toList();
  
  List<NotificationModel> get readNotifications =>
      notifications.where((n) => n.isRead).toList();
  
  List<NotificationModel> get archivedNotifications =>
      notifications.where((n) => n.isArchived).toList();
  
  List<NotificationModel> get urgentNotifications =>
      notifications.where((n) => n.priority == NotificationPriority.urgent).toList();
  
  List<NotificationModel> get todayNotifications {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return notifications.where((n) => n.createdAt.isAfter(startOfDay)).toList();
  }
  
  int get unreadCount => unreadNotifications.length;
  int get totalCount => notifications.length;
}

class NotificationsErrorState extends NotificationsState {
  final String message;
  const NotificationsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class NotificationUpdating extends NotificationsState {
  final String notificationId;
  const NotificationUpdating(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class NotificationDeleting extends NotificationsState {
  final String notificationId;
  const NotificationDeleting(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

