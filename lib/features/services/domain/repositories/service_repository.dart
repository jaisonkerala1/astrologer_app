import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../models/order_model.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';

/// Abstract repository interface for service operations
/// This interface allows easy switching between mock and real API implementations
abstract class ServiceRepository {
  // ==================== Service Operations ====================
  
  /// Get service by ID
  Future<ServiceModel> getServiceById(String serviceId);
  
  /// Get all services for a specific astrologer
  Future<List<ServiceModel>> getServicesByAstrologer(String astrologerId);
  
  /// Get all available services (for browsing)
  Future<List<ServiceModel>> getAllServices();
  
  /// Search services by keyword
  Future<List<ServiceModel>> searchServices(String query);
  
  // ==================== Availability Operations ====================
  
  /// Get available time slots for a specific astrologer on a given date
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String astrologerId,
    required DateTime date,
    int? durationInMinutes,
  });
  
  /// Check if a specific time slot is still available
  Future<bool> isSlotAvailable({
    required String astrologerId,
    required String slotId,
  });
  
  // ==================== Add-ons Operations ====================
  
  /// Get available add-ons for a service
  Future<List<AddOnModel>> getServiceAddOns(String serviceId);
  
  // ==================== Booking Operations ====================
  
  /// Create a new booking
  Future<BookingModel> createBooking(BookingModel booking);
  
  /// Update an existing booking
  Future<BookingModel> updateBooking(BookingModel booking);
  
  /// Validate promo code
  Future<Map<String, dynamic>> validatePromoCode({
    required String promoCode,
    required double orderAmount,
  });
  
  // ==================== Order Operations ====================
  
  /// Create order from booking (after payment)
  Future<OrderModel> createOrder({
    required BookingModel booking,
    required String paymentId,
    String? paymentMethod,
  });
  
  /// Get order by ID
  Future<OrderModel> getOrderById(String orderId);
  
  /// Get all orders for current user
  Future<List<OrderModel>> getMyOrders({
    int? limit,
    int? offset,
    String? status,
  });
  
  /// Cancel an order
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  });
  
  /// Request refund for an order
  Future<OrderModel> requestRefund(String orderId);
  
  /// Update order status (typically called by backend/admin)
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String status,
    Map<String, dynamic>? metadata,
  });
  
  // ==================== Payment Operations ====================
  
  /// Calculate platform fee based on order amount
  double calculatePlatformFee(double amount);
  
  /// Calculate total amount including fees and discounts
  double calculateTotalAmount({
    required double servicePrice,
    required double addOnsPrice,
    required double platformFee,
    required double discount,
  });
  
  // ==================== Notification Operations ====================
  
  /// Send booking confirmation (email + SMS)
  Future<void> sendBookingConfirmation(OrderModel order);
  
  /// Send reminder before consultation
  Future<void> sendConsultationReminder(OrderModel order);
}

