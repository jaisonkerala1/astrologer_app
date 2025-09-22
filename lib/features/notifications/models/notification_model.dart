import 'package:equatable/equatable.dart';

enum NotificationType {
  consultationRequest,
  consultationAccepted,
  consultationCancelled,
  consultationCompleted,
  paymentReceived,
  paymentFailed,
  reviewReceived,
  messageReceived,
  callMissed,
  systemUpdate,
  promotional,
  reminder,
  emergency,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  unread,
  read,
  archived,
  deleted,
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? actionText;
  final bool isActionable;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionUrl,
    this.actionText,
    this.isActionable = false,
    this.senderId,
    this.senderName,
    this.senderAvatar,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['actionUrl'] as String?,
      actionText: json['actionText'] as String?,
      isActionable: json['isActionable'] as bool? ?? false,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'isActionable': isActionable,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionText,
    bool? isActionable,
    String? senderId,
    String? senderName,
    String? senderAvatar,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      isActionable: isActionable ?? this.isActionable,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }

  bool get isRead => status == NotificationStatus.read;
  bool get isUnread => status == NotificationStatus.unread;
  bool get isArchived => status == NotificationStatus.archived;
  bool get isDeleted => status == NotificationStatus.deleted;

  Duration get age => DateTime.now().difference(createdAt);
  String get timeAgo {
    final duration = age;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        imageUrl,
        type,
        priority,
        status,
        createdAt,
        readAt,
        data,
        actionUrl,
        actionText,
        isActionable,
        senderId,
        senderName,
        senderAvatar,
      ];
}

class NotificationStats extends Equatable {
  final int total;
  final int unread;
  final int read;
  final int archived;
  final int urgent;
  final int today;

  const NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
    required this.archived,
    required this.urgent,
    required this.today,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int,
      unread: json['unread'] as int,
      read: json['read'] as int,
      archived: json['archived'] as int,
      urgent: json['urgent'] as int,
      today: json['today'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
      'archived': archived,
      'urgent': urgent,
      'today': today,
    };
  }

  @override
  List<Object?> get props => [total, unread, read, archived, urgent, today];
}

