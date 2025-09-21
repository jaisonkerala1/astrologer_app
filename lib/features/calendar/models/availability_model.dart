class AvailabilityModel {
  final String id;
  final String astrologerId;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String startTime; // "09:00"
  final String endTime; // "18:00"
  final bool isActive;
  final List<BreakTime> breaks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AvailabilityModel({
    required this.id,
    required this.astrologerId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.breaks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['_id'] ?? json['id'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '18:00',
      isActive: json['isActive'] ?? true,
      breaks: (json['breaks'] as List<dynamic>?)
          ?.map((breakJson) => BreakTime.fromJson(breakJson))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerId': astrologerId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'breaks': breaks.map((breakTime) => breakTime.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AvailabilityModel copyWith({
    String? id,
    String? astrologerId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
    List<BreakTime>? breaks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      astrologerId: astrologerId ?? this.astrologerId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      breaks: breaks ?? this.breaks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  String get dayNameHindi {
    const days = ['रविवार', 'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार'];
    return days[dayOfWeek];
  }
}

class BreakTime {
  final String startTime;
  final String endTime;
  final String reason;

  const BreakTime({
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory BreakTime.fromJson(Map<String, dynamic> json) {
    return BreakTime(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }
}

