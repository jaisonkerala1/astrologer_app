import 'package:equatable/equatable.dart';

/// Notification types enum
enum NotificationType {
  newBookingRequest,
  bookingReminder,
  bookingCancellation,
  consultationStarting,
  newMessage,
  messageReminder,
  paymentReceived,
  dailyEarnings,
  appUpdate,
  maintenance,
}

/// Notification priority levels
enum NotificationPriority {
  high,
  medium,
  low,
}

/// Notification settings model
class NotificationSettings extends Equatable {
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool soundEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool workingHoursOnly;
  final Map<NotificationType, bool> notificationToggles;
  final Map<NotificationType, NotificationPriority> notificationPriorities;

  const NotificationSettings({
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.soundEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.workingHoursOnly = false,
    this.notificationToggles = const {
      NotificationType.newBookingRequest: true,
      NotificationType.bookingReminder: true,
      NotificationType.bookingCancellation: true,
      NotificationType.consultationStarting: true,
      NotificationType.newMessage: true,
      NotificationType.messageReminder: true,
      NotificationType.paymentReceived: true,
      NotificationType.dailyEarnings: true,
      NotificationType.appUpdate: true,
      NotificationType.maintenance: true,
    },
    this.notificationPriorities = const {
      NotificationType.newBookingRequest: NotificationPriority.high,
      NotificationType.bookingReminder: NotificationPriority.high,
      NotificationType.bookingCancellation: NotificationPriority.high,
      NotificationType.consultationStarting: NotificationPriority.high,
      NotificationType.newMessage: NotificationPriority.medium,
      NotificationType.messageReminder: NotificationPriority.medium,
      NotificationType.paymentReceived: NotificationPriority.high,
      NotificationType.dailyEarnings: NotificationPriority.medium,
      NotificationType.appUpdate: NotificationPriority.low,
      NotificationType.maintenance: NotificationPriority.low,
    },
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
      workingHoursOnly: json['workingHoursOnly'] ?? false,
      notificationToggles: Map<NotificationType, bool>.from(
        (json['notificationToggles'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(
                  NotificationType.values.firstWhere(
                    (e) => e.toString() == 'NotificationType.$key',
                    orElse: () => NotificationType.appUpdate,
                  ),
                  value as bool,
                )),
      ),
      notificationPriorities: Map<NotificationType, NotificationPriority>.from(
        (json['notificationPriorities'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(
                  NotificationType.values.firstWhere(
                    (e) => e.toString() == 'NotificationType.$key',
                    orElse: () => NotificationType.appUpdate,
                  ),
                  NotificationPriority.values.firstWhere(
                    (e) => e.toString() == 'NotificationPriority.${value.toString().split('.').last}',
                    orElse: () => NotificationPriority.medium,
                  ),
                )),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'workingHoursOnly': workingHoursOnly,
      'notificationToggles': notificationToggles.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'notificationPriorities': notificationPriorities.map(
        (key, value) => MapEntry(
          key.toString().split('.').last,
          value.toString().split('.').last,
        ),
      ),
    };
  }

  NotificationSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? soundEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? workingHoursOnly,
    Map<NotificationType, bool>? notificationToggles,
    Map<NotificationType, NotificationPriority>? notificationPriorities,
  }) {
    return NotificationSettings(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      workingHoursOnly: workingHoursOnly ?? this.workingHoursOnly,
      notificationToggles: notificationToggles ?? this.notificationToggles,
      notificationPriorities: notificationPriorities ?? this.notificationPriorities,
    );
  }

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        emailNotificationsEnabled,
        soundEnabled,
        quietHoursStart,
        quietHoursEnd,
        workingHoursOnly,
        notificationToggles,
        notificationPriorities,
      ];
}

/// Notification item model
class NotificationItem extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.appUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${json['priority']}',
        orElse: () => NotificationPriority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        priority,
        createdAt,
        isRead,
        data,
      ];
}

/// Extension methods for notification types
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newBookingRequest:
        return 'New Booking Request';
      case NotificationType.bookingReminder:
        return 'Booking Reminder';
      case NotificationType.bookingCancellation:
        return 'Booking Cancellation';
      case NotificationType.consultationStarting:
        return 'Consultation Starting';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.messageReminder:
        return 'Message Reminder';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.dailyEarnings:
        return 'Daily Earnings';
      case NotificationType.appUpdate:
        return 'App Update';
      case NotificationType.maintenance:
        return 'Maintenance';
    }
  }

  String get description {
    switch (this) {
      case NotificationType.newBookingRequest:
        return 'When a client books a consultation';
      case NotificationType.bookingReminder:
        return '30 minutes before consultation starts';
      case NotificationType.bookingCancellation:
        return 'When a client cancels a booking';
      case NotificationType.consultationStarting:
        return 'When it\'s time to start the consultation';
      case NotificationType.newMessage:
        return 'When a client sends a message';
      case NotificationType.messageReminder:
        return 'Unread message after 1 hour';
      case NotificationType.paymentReceived:
        return 'When you receive payment';
      case NotificationType.dailyEarnings:
        return 'Daily earnings summary';
      case NotificationType.appUpdate:
        return 'New features and bug fixes';
      case NotificationType.maintenance:
        return 'App maintenance alerts';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.newBookingRequest:
        return 'calendar_today';
      case NotificationType.bookingReminder:
        return 'schedule';
      case NotificationType.bookingCancellation:
        return 'cancel';
      case NotificationType.consultationStarting:
        return 'play_circle';
      case NotificationType.newMessage:
        return 'message';
      case NotificationType.messageReminder:
        return 'message_outlined';
      case NotificationType.paymentReceived:
        return 'payment';
      case NotificationType.dailyEarnings:
        return 'trending_up';
      case NotificationType.appUpdate:
        return 'system_update';
      case NotificationType.maintenance:
        return 'build';
    }
  }
}

/// Extension methods for notification priority
extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.low:
        return 'Low';
    }
  }

  String get colorName {
    switch (this) {
      case NotificationPriority.high:
        return 'red';
      case NotificationPriority.medium:
        return 'orange';
      case NotificationPriority.low:
        return 'green';
    }
  }
}



