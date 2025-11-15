import '../../domain/repositories/service_repository.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../models/order_model.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';
import '../../models/order_status_enum.dart';
import '../datasources/service_local_datasource.dart';

/// Repository implementation using mock data
/// Switch to ServiceRemoteDataSource when API is ready
class ServiceRepositoryImpl implements ServiceRepository {
  // For now using local data source
  // Later: final ServiceRemoteDataSource remoteDataSource;
  
  // In-memory storage for demo purposes
  final Map<String, BookingModel> _bookings = {};
  final Map<String, OrderModel> _orders = {};
  final Map<String, ServiceModel> _customServices = {}; // Store dynamically added services

  @override
  Future<ServiceModel> getServiceById(String serviceId) async {
    // No delay for instant loading experience
    
    // Check custom services first
    if (_customServices.containsKey(serviceId)) {
      return _customServices[serviceId]!;
    }
    
    // Mock: Get from local data
    final services = ServiceLocalDataSource.getMockServices('mock_astrologer_id');
    return services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw Exception('Service not found'),
    );
  }
  
  /// Add a custom service (for integration with astrologer profile)
  void addService(ServiceModel service) {
    _customServices[service.id] = service;
  }

  @override
  Future<List<ServiceModel>> getServicesByAstrologer(String astrologerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ServiceLocalDataSource.getMockServices(astrologerId);
  }

  @override
  Future<List<ServiceModel>> getAllServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ServiceLocalDataSource.getMockServices('mock_astrologer_id');
  }

  @override
  Future<List<ServiceModel>> searchServices(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allServices = ServiceLocalDataSource.getMockServices('mock_astrologer_id');
    return allServices.where((service) {
      return service.name.toLowerCase().contains(query.toLowerCase()) ||
          service.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String astrologerId,
    required DateTime date,
    int? durationInMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return ServiceLocalDataSource.getMockTimeSlots(
      date: date,
      durationInMinutes: durationInMinutes ?? 60,
    );
  }

  @override
  Future<bool> isSlotAvailable({
    required String astrologerId,
    required String slotId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock: Check if slot is still available
    // In real implementation, check against backend
    return true;
  }

  @override
  Future<List<AddOnModel>> getServiceAddOns(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ServiceLocalDataSource.getMockAddOns(serviceId);
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate booking ID
    final bookingId = 'bkg_${DateTime.now().millisecondsSinceEpoch}';
    final newBooking = booking.copyWith(
      id: bookingId,
      createdAt: DateTime.now(),
    );
    
    // Store in memory
    _bookings[bookingId] = newBooking;
    
    return newBooking;
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (booking.id == null) {
      throw Exception('Booking ID is required for update');
    }
    
    final updatedBooking = booking.copyWith(
      updatedAt: DateTime.now(),
    );
    
    _bookings[booking.id!] = updatedBooking;
    return updatedBooking;
  }

  @override
  Future<Map<String, dynamic>> validatePromoCode({
    required String promoCode,
    required double orderAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock promo code validation
    final validPromoCodes = {
      'FIRST50': {'type': 'flat', 'value': 50.0, 'description': '₹50 off on first booking'},
      'SAVE10': {'type': 'percentage', 'value': 10.0, 'description': '10% off'},
      'SUMMER100': {'type': 'flat', 'value': 100.0, 'description': '₹100 off'},
    };
    
    if (validPromoCodes.containsKey(promoCode.toUpperCase())) {
      final promo = validPromoCodes[promoCode.toUpperCase()]!;
      double discount = 0;
      
      if (promo['type'] == 'flat') {
        discount = promo['value'] as double;
      } else if (promo['type'] == 'percentage') {
        discount = (orderAmount * (promo['value'] as double)) / 100;
      }
      
      return {
        'valid': true,
        'discount': discount,
        'description': promo['description'],
      };
    }
    
    return {
      'valid': false,
      'discount': 0.0,
      'description': 'Invalid promo code',
    };
  }

  @override
  Future<OrderModel> createOrder({
    required BookingModel booking,
    required String paymentId,
    String? paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Generate order ID and number
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final orderNumber = ServiceLocalDataSource.generateOrderNumber();
    
    // Get service details for display
    final service = await getServiceById(booking.serviceId);
    
    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      booking: booking,
      status: OrderStatus.confirmed,
      serviceName: service.name,
      astrologerName: 'Dr. Rajesh Kumar', // Mock
      astrologerPhoto: null,
      paymentId: paymentId,
      paymentMethod: paymentMethod,
      isPaid: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
      confirmedAt: DateTime.now(),
    );
    
    _orders[orderId] = order;
    
    // Send confirmation (mock)
    await sendBookingConfirmation(order);
    
    return order;
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final order = _orders[orderId];
    if (order == null) {
      throw Exception('Order not found');
    }
    return order;
  }

  @override
  Future<List<OrderModel>> getMyOrders({
    int? limit,
    int? offset,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    var orders = _orders.values.toList();
    
    // Filter by status if provided
    if (status != null) {
      orders = orders.where((o) => o.status.name == status).toList();
    }
    
    // Sort by creation date (newest first)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Apply pagination
    if (offset != null && offset > 0) {
      orders = orders.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      orders = orders.take(limit).toList();
    }
    
    return orders;
  }

  @override
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final order = await getOrderById(orderId);
    
    if (!order.status.canCancel) {
      throw Exception('Order cannot be cancelled in current status');
    }
    
    final cancelledOrder = order.copyWith(
      status: OrderStatus.cancelled,
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
    );
    
    _orders[orderId] = cancelledOrder;
    return cancelledOrder;
  }

  @override
  Future<OrderModel> requestRefund(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final order = await getOrderById(orderId);
    
    if (!order.canRequestRefund) {
      throw Exception('Refund period has expired (7 days limit)');
    }
    
    final refundedOrder = order.copyWith(
      status: OrderStatus.refunded,
      refundedAt: DateTime.now(),
      refundId: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      refundAmount: order.booking.totalAmount,
    );
    
    _orders[orderId] = refundedOrder;
    return refundedOrder;
  }

  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final order = await getOrderById(orderId);
    final newStatus = OrderStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => throw Exception('Invalid status'),
    );
    
    var updatedOrder = order.copyWith(
      status: newStatus,
      metadata: metadata ?? order.metadata,
    );
    
    // Update timestamps based on status
    if (newStatus == OrderStatus.confirmed && order.confirmedAt == null) {
      updatedOrder = updatedOrder.copyWith(confirmedAt: DateTime.now());
    } else if (newStatus == OrderStatus.completed && order.completedAt == null) {
      updatedOrder = updatedOrder.copyWith(completedAt: DateTime.now());
    }
    
    _orders[orderId] = updatedOrder;
    return updatedOrder;
  }

  @override
  double calculatePlatformFee(double amount) {
    // Mock: 2.5% platform fee with minimum ₹10 and maximum ₹100
    final fee = amount * 0.025;
    return fee.clamp(10.0, 100.0);
  }

  @override
  double calculateTotalAmount({
    required double servicePrice,
    required double addOnsPrice,
    required double platformFee,
    required double discount,
  }) {
    final subtotal = servicePrice + addOnsPrice;
    final total = subtotal + platformFee - discount;
    return total.clamp(0, double.infinity); // Ensure non-negative
  }

  @override
  Future<void> sendBookingConfirmation(OrderModel order) async {
    // Mock: In real implementation, trigger email and SMS
    await Future.delayed(const Duration(milliseconds: 300));
    
    print('📧 Email sent: Booking confirmation for ${order.orderNumber}');
    print('📱 SMS sent: Your booking is confirmed!');
    
    // When backend is ready:
    // await apiClient.post('/notifications/booking-confirmation', {
    //   'orderId': order.id,
    //   'userId': order.booking.userId,
    // });
  }

  @override
  Future<void> sendConsultationReminder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    print('🔔 Reminder sent: Consultation tomorrow at ${order.booking.timeSlot.shortTime}');
    
    // When backend is ready:
    // await apiClient.post('/notifications/consultation-reminder', {
    //   'orderId': order.id,
    // });
  }
}

