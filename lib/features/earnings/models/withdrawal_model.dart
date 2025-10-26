import 'package:equatable/equatable.dart';

/// Withdrawal status enum
enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Model representing a withdrawal request
class WithdrawalModel extends Equatable {
  final String id;
  final double amount;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? transactionReference;
  final String? rejectionReason;
  final String? notes;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.bankAccountNumber,
    this.ifscCode,
    this.upiId,
    this.transactionReference,
    this.rejectionReason,
    this.notes,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      bankAccountNumber: json['bankAccountNumber'],
      ifscCode: json['ifscCode'],
      upiId: json['upiId'],
      transactionReference: json['transactionReference'],
      rejectionReason: json['rejectionReason'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'transactionReference': transactionReference,
      'rejectionReason': rejectionReason,
      'notes': notes,
    };
  }

  static WithdrawalStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'processing':
        return WithdrawalStatus.processing;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'failed':
        return WithdrawalStatus.failed;
      case 'cancelled':
        return WithdrawalStatus.cancelled;
      default:
        return WithdrawalStatus.pending;
    }
  }

  WithdrawalModel copyWith({
    String? id,
    double? amount,
    WithdrawalStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    String? transactionReference,
    String? rejectionReason,
    String? notes,
  }) {
    return WithdrawalModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      transactionReference: transactionReference ?? this.transactionReference,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }

  /// Get formatted amount
  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';

  /// Get formatted request date
  String get formattedRequestDate {
    return '${requestedAt.day} ${_getMonthName(requestedAt.month)}, ${requestedAt.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'PENDING';
      case WithdrawalStatus.processing:
        return 'PROCESSING';
      case WithdrawalStatus.completed:
        return 'COMPLETED';
      case WithdrawalStatus.failed:
        return 'FAILED';
      case WithdrawalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// Check if withdrawal is pending
  bool get isPending => status == WithdrawalStatus.pending;

  /// Check if withdrawal is processing
  bool get isProcessing => status == WithdrawalStatus.processing;

  /// Check if withdrawal is completed
  bool get isCompleted => status == WithdrawalStatus.completed;

  /// Check if withdrawal is failed
  bool get isFailed => status == WithdrawalStatus.failed;

  /// Check if withdrawal is cancelled
  bool get isCancelled => status == WithdrawalStatus.cancelled;

  @override
  List<Object?> get props => [
        id,
        amount,
        status,
        requestedAt,
        processedAt,
        completedAt,
        bankAccountNumber,
        ifscCode,
        upiId,
        transactionReference,
        rejectionReason,
        notes,
      ];
}


