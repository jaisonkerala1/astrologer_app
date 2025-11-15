import 'package:equatable/equatable.dart';

class TimeSlotModel extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? bookedBy; // Order ID if booked

  const TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.bookedBy,
  });

  // Duration in minutes
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Formatted time display (e.g., "10:00 AM - 11:00 AM")
  String get formattedTime {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }

  // Short format (e.g., "10:00 AM")
  String get shortTime {
    return _formatTime(startTime);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] ?? json['_id'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isAvailable: json['isAvailable'] ?? true,
      bookedBy: json['bookedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAvailable': isAvailable,
      'bookedBy': bookedBy,
    };
  }

  TimeSlotModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? bookedBy,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      bookedBy: bookedBy ?? this.bookedBy,
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime, isAvailable, bookedBy];
}

