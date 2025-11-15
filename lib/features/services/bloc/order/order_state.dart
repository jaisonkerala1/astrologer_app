import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// Creating order
class OrderCreating extends OrderState {
  const OrderCreating();
}

/// Order created successfully
class OrderCreated extends OrderState {
  final OrderModel order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

/// Loading order(s)
class OrderLoading extends OrderState {
  const OrderLoading();
}

/// Single order loaded
class OrderLoaded extends OrderState {
  final OrderModel order;

  const OrderLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

/// Multiple orders loaded
class OrdersLoaded extends OrderState {
  final List<OrderModel> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

/// Order updated (cancelled, refunded, status changed)
class OrderUpdated extends OrderState {
  final OrderModel order;
  final String message;

  const OrderUpdated({
    required this.order,
    required this.message,
  });

  @override
  List<Object?> get props => [order, message];
}

/// Order cancelled successfully
class OrderCancelled extends OrderState {
  final OrderModel order;

  const OrderCancelled(this.order);

  @override
  List<Object?> get props => [order];
}

/// Refund requested successfully
class RefundRequested extends OrderState {
  final OrderModel order;

  const RefundRequested(this.order);

  @override
  List<Object?> get props => [order];
}

/// Order error
class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

