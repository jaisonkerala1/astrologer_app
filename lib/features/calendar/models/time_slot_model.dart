import 'package:equatable/equatable.dart';

class TimeSlotModel extends Equatable {
  final String id;
  final String astrologerId;
  final DateTime date;
  final String startTime; // "09:00"
  final String endTime; // "09:30"
  final int duration; // in minutes
  final bool isAvailable;
  final bool isBooked;
  final String? consultationId;
  final int bufferTime; // minutes before/after
  final DateTime createdAt;

  const TimeSlotModel({
    required this.id,
    required this.astrologerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isAvailable,
    required this.isBooked,
    this.consultationId,
    required this.bufferTime,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    astrologerId,
    date,
    startTime,
    endTime,
    duration,
    isAvailable,
    isBooked,
    consultationId,
    bufferTime,
    createdAt,
  ];

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['_id'] ?? json['id'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      duration: json['duration'] ?? 30,
      isAvailable: json['isAvailable'] ?? true,
      isBooked: json['isBooked'] ?? false,
      consultationId: json['consultationId'],
      bufferTime: json['bufferTime'] ?? 15,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerId': astrologerId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'isAvailable': isAvailable,
      'isBooked': isBooked,
      'consultationId': consultationId,
      'bufferTime': bufferTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TimeSlotModel copyWith({
    String? id,
    String? astrologerId,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? duration,
    bool? isAvailable,
    bool? isBooked,
    String? consultationId,
    int? bufferTime,
    DateTime? createdAt,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      astrologerId: astrologerId ?? this.astrologerId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isAvailable: isAvailable ?? this.isAvailable,
      isBooked: isBooked ?? this.isBooked,
      consultationId: consultationId ?? this.consultationId,
      bufferTime: bufferTime ?? this.bufferTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get full DateTime for start time
  DateTime get startDateTime {
    final timeParts = startTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Get full DateTime for end time
  DateTime get endDateTime {
    final timeParts = endTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Get formatted time range
  String get timeRange => '$startTime - $endTime';

  /// Get formatted time range in 12-hour format
  String get timeRange12Hour {
    final start = _formatTo12Hour(startTime);
    final end = _formatTo12Hour(endTime);
    return '$start - $end';
  }

  String _formatTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  /// Check if slot is available for booking
  bool get canBook => isAvailable && !isBooked;

  /// Get status text
  String get statusText {
    if (isBooked) return 'Booked';
    if (!isAvailable) return 'Unavailable';
    return 'Available';
  }
}
