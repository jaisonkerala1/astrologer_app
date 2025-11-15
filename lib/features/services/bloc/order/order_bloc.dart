import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ServiceRepository repository;

  OrderBloc({required this.repository}) : super(const OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<LoadOrderEvent>(_onLoadOrder);
    on<LoadMyOrdersEvent>(_onLoadMyOrders);
    on<CancelOrderEvent>(_onCancelOrder);
    on<RequestRefundEvent>(_onRequestRefund);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<ResetOrderEvent>(_onResetOrder);
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderCreating());
    try {
      final order = await repository.createOrder(
        booking: event.booking,
        paymentId: event.paymentId,
        paymentMethod: event.paymentMethod,
      );
      emit(OrderCreated(order));
    } catch (e) {
      emit(OrderError('Failed to create order: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrder(
    LoadOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final order = await repository.getOrderById(event.orderId);
      emit(OrderLoaded(order));
    } catch (e) {
      emit(OrderError('Failed to load order: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMyOrders(
    LoadMyOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await repository.getMyOrders(
        limit: event.limit,
        offset: event.offset,
        status: event.status,
      );
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final order = await repository.cancelOrder(
        orderId: event.orderId,
        reason: event.reason,
      );
      emit(OrderCancelled(order));
    } catch (e) {
      emit(OrderError('Failed to cancel order: ${e.toString()}'));
    }
  }

  Future<void> _onRequestRefund(
    RequestRefundEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final order = await repository.requestRefund(event.orderId);
      emit(RefundRequested(order));
    } catch (e) {
      emit(OrderError('Failed to request refund: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final order = await repository.updateOrderStatus(
        orderId: event.orderId,
        status: event.status,
        metadata: event.metadata,
      );
      emit(OrderUpdated(
        order: order,
        message: 'Order status updated to ${event.status}',
      ));
    } catch (e) {
      emit(OrderError('Failed to update order status: ${e.toString()}'));
    }
  }

  void _onResetOrder(
    ResetOrderEvent event,
    Emitter<OrderState> emit,
  ) {
    emit(const OrderInitial());
  }
}

