class ConsultationModel {
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
    );
  }
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
}
