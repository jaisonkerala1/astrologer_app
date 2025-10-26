import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType {
  credit,
  debit,
}

/// Model representing a financial transaction
class TransactionModel extends Equatable {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? consultationId;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.consultationId,
    this.referenceId,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] == 'credit' || json['type'] == 'CREDIT'
          ? TransactionType.credit
          : TransactionType.debit,
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      consultationId: json['consultationId'],
      referenceId: json['referenceId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type == TransactionType.credit ? 'credit' : 'debit',
      'date': date.toIso8601String(),
      'consultationId': consultationId,
      'referenceId': referenceId,
      'metadata': metadata,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? consultationId,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      consultationId: consultationId ?? this.consultationId,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted amount with sign
  String get formattedAmount {
    final sign = type == TransactionType.credit ? '+' : '-';
    return '$sign₹${amount.toStringAsFixed(0)}';
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      final difference = today.difference(transactionDate).inDays;
      if (difference < 7) {
        return '$difference days ago, ${_formatTime(date)}';
      } else {
        return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
      }
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Check if transaction is credit
  bool get isCredit => type == TransactionType.credit;

  /// Check if transaction is debit
  bool get isDebit => type == TransactionType.debit;

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        type,
        date,
        consultationId,
        referenceId,
        metadata,
      ];
}


