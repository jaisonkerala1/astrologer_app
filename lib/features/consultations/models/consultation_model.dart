import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class StatusHistoryEntry extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? notes;
  final DateTime? scheduledTime;

  const StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.notes,
    this.scheduledTime,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [status, timestamp, notes, scheduledTime];
}

class ConsultationModel extends Equatable {
  final String id;
  final String clientName;
  final String clientPhone;
  final DateTime scheduledTime;
  final int duration; // in minutes
  final double amount;
  final ConsultationStatus status;
  final ConsultationType type;
  final String? notes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  
  // Astrologer rating fields (separate from consultation rating)
  final int? astrologerRating; // 1-5 stars from astrologer
  final String? astrologerFeedback; // Optional feedback from astrologer
  final DateTime? astrologerRatedAt; // When astrologer rated the session
  
  // Share tracking fields
  final int shareCount; // Number of times shared
  final DateTime? lastSharedAt; // Last time it was shared
  
  // Reschedule tracking fields
  final int rescheduleCount; // Number of times rescheduled
  final DateTime? lastRescheduledAt; // Last time it was rescheduled
  final DateTime? originalScheduledTime; // Original scheduled time
  
  // Status history
  final List<StatusHistoryEntry> statusHistory;

  const ConsultationModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.scheduledTime,
    required this.duration,
    required this.amount,
    required this.status,
    required this.type,
    this.notes,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.astrologerRating,
    this.astrologerFeedback,
    this.astrologerRatedAt,
    this.shareCount = 0,
    this.lastSharedAt,
    this.rescheduleCount = 0,
    this.lastRescheduledAt,
    this.originalScheduledTime,
    this.statusHistory = const [],
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    final status = ConsultationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['status'],
      orElse: () => ConsultationStatus.scheduled,
    );
    
    print('ConsultationModel.fromJson: Parsing status "${json['status']}" to ${status.displayName}');
    
    return ConsultationModel(
      id: json['_id'] ?? json['id'] ?? '',
      clientName: json['clientName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime']),
      duration: json['duration'] ?? 30,
      amount: (json['amount'] ?? 0).toDouble(),
      status: status,
      type: ConsultationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ConsultationType.phone,
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt'])
          : null,
      astrologerRating: json['astrologerRating'],
      astrologerFeedback: json['astrologerFeedback'],
      astrologerRatedAt: json['astrologerRatedAt'] != null 
          ? DateTime.parse(json['astrologerRatedAt'])
          : null,
      shareCount: json['shareCount'] ?? 0,
      lastSharedAt: json['lastSharedAt'] != null 
          ? DateTime.parse(json['lastSharedAt'])
          : null,
      rescheduleCount: json['rescheduleCount'] ?? 0,
      lastRescheduledAt: json['lastRescheduledAt'] != null 
          ? DateTime.parse(json['lastRescheduledAt'])
          : null,
      originalScheduledTime: json['originalScheduledTime'] != null 
          ? DateTime.parse(json['originalScheduledTime'])
          : null,
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((entry) => StatusHistoryEntry.fromJson(entry))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'scheduledTime': scheduledTime.toIso8601String(),
      'duration': duration,
      'amount': amount,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'astrologerRating': astrologerRating,
      'astrologerFeedback': astrologerFeedback,
      'astrologerRatedAt': astrologerRatedAt?.toIso8601String(),
      'shareCount': shareCount,
      'lastSharedAt': lastSharedAt?.toIso8601String(),
      'rescheduleCount': rescheduleCount,
      'lastRescheduledAt': lastRescheduledAt?.toIso8601String(),
      'originalScheduledTime': originalScheduledTime?.toIso8601String(),
      'statusHistory': statusHistory.map((entry) => entry.toJson()).toList(),
    };
  }

  ConsultationModel copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    DateTime? scheduledTime,
    int? duration,
    double? amount,
    ConsultationStatus? status,
    ConsultationType? type,
    String? notes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    int? astrologerRating,
    String? astrologerFeedback,
    DateTime? astrologerRatedAt,
    int? shareCount,
    DateTime? lastSharedAt,
    int? rescheduleCount,
    DateTime? lastRescheduledAt,
    DateTime? originalScheduledTime,
    List<StatusHistoryEntry>? statusHistory,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      astrologerRating: astrologerRating ?? this.astrologerRating,
      astrologerFeedback: astrologerFeedback ?? this.astrologerFeedback,
      astrologerRatedAt: astrologerRatedAt ?? this.astrologerRatedAt,
      shareCount: shareCount ?? this.shareCount,
      lastSharedAt: lastSharedAt ?? this.lastSharedAt,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      lastRescheduledAt: lastRescheduledAt ?? this.lastRescheduledAt,
      originalScheduledTime: originalScheduledTime ?? this.originalScheduledTime,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    clientName,
    clientPhone,
    scheduledTime,
    duration,
    amount,
    status,
    type,
    notes,
    createdAt,
    startedAt,
    completedAt,
    cancelledAt,
    astrologerRating,
    astrologerFeedback,
    astrologerRatedAt,
    shareCount,
    lastSharedAt,
    rescheduleCount,
    lastRescheduledAt,
    originalScheduledTime,
    statusHistory,
  ];
}

enum ConsultationStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum ConsultationType {
  phone,
  video,
  inPerson,
  chat,
}

extension ConsultationStatusExtension on ConsultationStatus {
  String get displayName {
    switch (this) {
      case ConsultationStatus.scheduled:
        return 'Scheduled';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
      case ConsultationStatus.noShow:
        return 'No Show';
    }
  }

  String get colorCode {
    switch (this) {
      case ConsultationStatus.scheduled:
        return '#3B82F6'; // Blue
      case ConsultationStatus.inProgress:
        return '#F59E0B'; // Amber/Orange
      case ConsultationStatus.completed:
        return '#10B981'; // Emerald/Green
      case ConsultationStatus.cancelled:
        return '#EF4444'; // Red
      case ConsultationStatus.noShow:
        return '#6B7280'; // Gray
    }
  }
}

extension ConsultationTypeExtension on ConsultationType {
  String get displayName {
    switch (this) {
      case ConsultationType.phone:
        return 'Phone Call';
      case ConsultationType.video:
        return 'Video Call';
      case ConsultationType.inPerson:
        return 'In Person';
      case ConsultationType.chat:
        return 'Chat';
    }
  }

  String get icon {
    switch (this) {
      case ConsultationType.phone:
        return 'phone';
      case ConsultationType.video:
        return 'videocam';
      case ConsultationType.inPerson:
        return 'person';
      case ConsultationType.chat:
        return 'chat';
    }
  }

  IconData get iconData {
    switch (this) {
      case ConsultationType.phone:
        return Icons.phone;
      case ConsultationType.video:
        return Icons.videocam;
      case ConsultationType.inPerson:
        return Icons.person;
      case ConsultationType.chat:
        return Icons.chat;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ConsultationType.phone:
        return const Color(0xFFEFF6FF); // Blue
      case ConsultationType.video:
        return const Color(0xFFFEF3C7); // Amber
      case ConsultationType.inPerson:
        return const Color(0xFFECFDF5); // Green
      case ConsultationType.chat:
        return const Color(0xFFF3E8FF); // Purple
    }
  }

  Color get textColor {
    switch (this) {
      case ConsultationType.phone:
        return const Color(0xFF2563EB); // Blue
      case ConsultationType.video:
        return const Color(0xFFD97706); // Amber
      case ConsultationType.inPerson:
        return const Color(0xFF059669); // Green
      case ConsultationType.chat:
        return const Color(0xFF7C3AED); // Purple
    }
  }
}
