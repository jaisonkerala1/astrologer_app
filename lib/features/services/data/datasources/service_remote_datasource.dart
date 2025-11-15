import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../models/order_model.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';

/// Remote data source interface for API integration
/// Implement this when backend API is ready
abstract class ServiceRemoteDataSource {
  // Services
  Future<ServiceModel> getServiceById(String serviceId);
  Future<List<ServiceModel>> getServicesByAstrologer(String astrologerId);
  Future<List<ServiceModel>> getAllServices();
  Future<List<ServiceModel>> searchServices(String query);
  
  // Availability
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String astrologerId,
    required DateTime date,
    int? durationInMinutes,
  });
  Future<bool> isSlotAvailable({
    required String astrologerId,
    required String slotId,
  });
  
  // Add-ons
  Future<List<AddOnModel>> getServiceAddOns(String serviceId);
  
  // Booking
  Future<BookingModel> createBooking(BookingModel booking);
  Future<BookingModel> updateBooking(BookingModel booking);
  Future<Map<String, dynamic>> validatePromoCode({
    required String promoCode,
    required double orderAmount,
  });
  
  // Orders
  Future<OrderModel> createOrder({
    required BookingModel booking,
    required String paymentId,
    String? paymentMethod,
  });
  Future<OrderModel> getOrderById(String orderId);
  Future<List<OrderModel>> getMyOrders({
    int? limit,
    int? offset,
    String? status,
  });
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  });
  Future<OrderModel> requestRefund(String orderId);
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String status,
    Map<String, dynamic>? metadata,
  });
  
  // Notifications
  Future<void> sendBookingConfirmation(OrderModel order);
  Future<void> sendConsultationReminder(OrderModel order);
}

/// Future API implementation example
/// Uncomment and implement when backend is ready
/*
class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  ServiceRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<ServiceModel> getServiceById(String serviceId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/services/$serviceId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return ServiceModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException();
    }
  }

  // ... implement other methods similarly
}
*/

