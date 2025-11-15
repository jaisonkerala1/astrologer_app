import 'package:equatable/equatable.dart';
import '../../models/booking_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Create order from booking (after payment)
class CreateOrderEvent extends OrderEvent {
  final BookingModel booking;
  final String paymentId;
  final String? paymentMethod;

  const CreateOrderEvent({
    required this.booking,
    required this.paymentId,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [booking, paymentId, paymentMethod];
}

/// Load order by ID
class LoadOrderEvent extends OrderEvent {
  final String orderId;

  const LoadOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Load all orders for current user
class LoadMyOrdersEvent extends OrderEvent {
  final int? limit;
  final int? offset;
  final String? status; // Filter by status

  const LoadMyOrdersEvent({
    this.limit,
    this.offset,
    this.status,
  });

  @override
  List<Object?> get props => [limit, offset, status];
}

/// Cancel an order
class CancelOrderEvent extends OrderEvent {
  final String orderId;
  final String reason;

  const CancelOrderEvent({
    required this.orderId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}

/// Request refund for an order
class RequestRefundEvent extends OrderEvent {
  final String orderId;

  const RequestRefundEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Update order status (typically backend-triggered)
class UpdateOrderStatusEvent extends OrderEvent {
  final String orderId;
  final String status;
  final Map<String, dynamic>? metadata;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.status,
    this.metadata,
  });

  @override
  List<Object?> get props => [orderId, status, metadata];
}

/// Reset order state
class ResetOrderEvent extends OrderEvent {
  const ResetOrderEvent();
}

