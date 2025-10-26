import 'package:equatable/equatable.dart';

class HolidayModel extends Equatable {
  final String id;
  final String astrologerId;
  final DateTime date;
  final String reason;
  final bool isRecurring;
  final String? recurringPattern; // "yearly", "monthly", "weekly"
  final DateTime createdAt;

  const HolidayModel({
    required this.id,
    required this.astrologerId,
    required this.date,
    required this.reason,
    required this.isRecurring,
    this.recurringPattern,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    astrologerId,
    date,
    reason,
    isRecurring,
    recurringPattern,
    createdAt,
  ];

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['_id'] ?? json['id'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      reason: json['reason'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerId': astrologerId,
      'date': date.toIso8601String(),
      'reason': reason,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  HolidayModel copyWith({
    String? id,
    String? astrologerId,
    DateTime? date,
    String? reason,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? createdAt,
  }) {
    return HolidayModel(
      id: id ?? this.id,
      astrologerId: astrologerId ?? this.astrologerId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get formatted date
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Get formatted date in Hindi
  String get formattedDateHindi {
    const months = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Check if holiday is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if holiday is in the past
  bool get isPast {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Check if holiday is in the future
  bool get isFuture {
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }
}
