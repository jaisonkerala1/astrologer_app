import 'package:equatable/equatable.dart';
import 'order_status_enum.dart';
import 'booking_model.dart';

class OrderModel extends Equatable {
  final String id;
  final String orderNumber; // Display number (e.g., #ORD123456)
  final BookingModel booking;
  final OrderStatus status;
  
  // Service & Astrologer info (denormalized for easy display)
  final String serviceName;
  final String astrologerName;
  final String? astrologerPhoto;
  
  // Payment info
  final String? paymentId;
  final String? paymentMethod;
  final bool isPaid;
  final DateTime? paidAt;
  
  // Order lifecycle
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  
  // Cancellation/Refund
  final String? cancellationReason;
  final String? refundId;
  final double? refundAmount;
  
  // Deliverables
  final String? reportUrl; // For report-based services
  final String? sessionLink; // For live consultations
  final String? recordingUrl; // If recording available
  
  // Review
  final bool isReviewed;
  final String? reviewId;
  
  // Metadata
  final Map<String, dynamic>? metadata;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.booking,
    required this.status,
    required this.serviceName,
    required this.astrologerName,
    this.astrologerPhoto,
    this.paymentId,
    this.paymentMethod,
    this.isPaid = false,
    this.paidAt,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.refundedAt,
    this.cancellationReason,
    this.refundId,
    this.refundAmount,
    this.reportUrl,
    this.sessionLink,
    this.recordingUrl,
    this.isReviewed = false,
    this.reviewId,
    this.metadata,
  });

  // Check if order can be refunded (within 7 days)
  bool get canRequestRefund {
    if (status != OrderStatus.completed && status != OrderStatus.confirmed) {
      return false;
    }
    final daysSinceCompletion = DateTime.now().difference(
      completedAt ?? confirmedAt ?? createdAt,
    ).inDays;
    return daysSinceCompletion <= 7;
  }

  // Days remaining for refund
  int get refundDaysRemaining {
    final daysSinceCompletion = DateTime.now().difference(
      completedAt ?? confirmedAt ?? createdAt,
    ).inDays;
    return (7 - daysSinceCompletion).clamp(0, 7);
  }

  // Formatted order creation date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? json['_id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      booking: BookingModel.fromJson(json['booking'] ?? {}),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      serviceName: json['serviceName'] ?? '',
      astrologerName: json['astrologerName'] ?? '',
      astrologerPhoto: json['astrologerPhoto'],
      paymentId: json['paymentId'],
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
      cancellationReason: json['cancellationReason'],
      refundId: json['refundId'],
      refundAmount: json['refundAmount'] != null ? (json['refundAmount'] as num).toDouble() : null,
      reportUrl: json['reportUrl'],
      sessionLink: json['sessionLink'],
      recordingUrl: json['recordingUrl'],
      isReviewed: json['isReviewed'] ?? false,
      reviewId: json['reviewId'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'booking': booking.toJson(),
      'status': status.name,
      'serviceName': serviceName,
      'astrologerName': astrologerName,
      'astrologerPhoto': astrologerPhoto,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'refundId': refundId,
      'refundAmount': refundAmount,
      'reportUrl': reportUrl,
      'sessionLink': sessionLink,
      'recordingUrl': recordingUrl,
      'isReviewed': isReviewed,
      'reviewId': reviewId,
      'metadata': metadata,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    BookingModel? booking,
    OrderStatus? status,
    String? serviceName,
    String? astrologerName,
    String? astrologerPhoto,
    String? paymentId,
    String? paymentMethod,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? refundedAt,
    String? cancellationReason,
    String? refundId,
    double? refundAmount,
    String? reportUrl,
    String? sessionLink,
    String? recordingUrl,
    bool? isReviewed,
    String? reviewId,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      booking: booking ?? this.booking,
      status: status ?? this.status,
      serviceName: serviceName ?? this.serviceName,
      astrologerName: astrologerName ?? this.astrologerName,
      astrologerPhoto: astrologerPhoto ?? this.astrologerPhoto,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundedAt: refundedAt ?? this.refundedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundId: refundId ?? this.refundId,
      refundAmount: refundAmount ?? this.refundAmount,
      reportUrl: reportUrl ?? this.reportUrl,
      sessionLink: sessionLink ?? this.sessionLink,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewId: reviewId ?? this.reviewId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        booking,
        status,
        serviceName,
        astrologerName,
        astrologerPhoto,
        paymentId,
        paymentMethod,
        isPaid,
        paidAt,
        createdAt,
        confirmedAt,
        completedAt,
        cancelledAt,
        refundedAt,
        cancellationReason,
        refundId,
        refundAmount,
        reportUrl,
        sessionLink,
        recordingUrl,
        isReviewed,
        reviewId,
        metadata,
      ];
}

