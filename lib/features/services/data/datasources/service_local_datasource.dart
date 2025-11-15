import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../models/service_type_enum.dart';
import '../../models/delivery_method_enum.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';

/// Mock data source for services
/// This will be replaced with API calls when backend is ready
class ServiceLocalDataSource {
  // Sample services for mock astrologer
  static List<ServiceModel> getMockServices(String astrologerId) {
    return [
      ServiceModel(
        id: 'srv_001',
        name: 'Kundali Analysis',
        description:
            'Complete horoscope reading with life predictions and planetary analysis. Get detailed insights into your past, present, and future based on Vedic astrology principles.',
        price: 1500,
        durationInMinutes: 60,
        serviceType: ServiceType.live,
        availableDeliveryMethods: [
          DeliveryMethod.videoCall,
          DeliveryMethod.audioCall,
          DeliveryMethod.report,
        ],
        iconName: 'auto_awesome',
        astrologerId: astrologerId,
        isPopular: true,
        whatsIncluded: [
          'Complete birth chart analysis',
          'Planetary positions and their effects',
          'Dasha and transit predictions',
          'Life predictions for next 5 years',
          'Personalized remedies and suggestions',
          'Follow-up consultation (15 mins)',
        ],
        howItWorks: [
          'Share your birth details (date, time, place)',
          'Schedule a consultation at your preferred time',
          'Join via video/audio call or receive detailed report',
          'Get personalized analysis and remedies',
        ],
        totalBookings: 156,
        averageRating: 4.8,
        reviewCount: 124,
      ),
      ServiceModel(
        id: 'srv_002',
        name: 'Career Guidance',
        description:
            'Career path analysis, job changes, and business decisions. Expert advice on professional growth and timing for career moves.',
        price: 800,
        durationInMinutes: 45,
        serviceType: ServiceType.live,
        availableDeliveryMethods: [
          DeliveryMethod.videoCall,
          DeliveryMethod.audioCall,
          DeliveryMethod.chat,
        ],
        iconName: 'work_outline',
        astrologerId: astrologerId,
        isPopular: true,
        whatsIncluded: [
          'Career horoscope analysis',
          'Best career path recommendations',
          'Job change timing prediction',
          'Business opportunity analysis',
          'Remedies for career growth',
        ],
        howItWorks: [
          'Share your current career situation',
          'Provide birth details for analysis',
          'Schedule consultation',
          'Get actionable career guidance',
        ],
        totalBookings: 203,
        averageRating: 4.7,
        reviewCount: 178,
      ),
      ServiceModel(
        id: 'srv_003',
        name: 'Marriage Matching',
        description:
            'Kundali matching for marriage compatibility and timing. Comprehensive analysis of compatibility factors and marriage predictions.',
        price: 1200,
        durationInMinutes: 60,
        serviceType: ServiceType.report,
        availableDeliveryMethods: [
          DeliveryMethod.report,
          DeliveryMethod.videoCall,
        ],
        iconName: 'favorite_border',
        astrologerId: astrologerId,
        whatsIncluded: [
          'Guna Milan (36 points matching)',
          'Manglik Dosha analysis',
          'Compatibility report',
          'Marriage timing prediction',
          'Remedies for happy married life',
          'Detailed PDF report',
        ],
        howItWorks: [
          'Share both partners birth details',
          'Analysis completed within 24 hours',
          'Receive comprehensive PDF report',
          'Optional video consultation for queries',
        ],
        totalBookings: 89,
        averageRating: 4.9,
        reviewCount: 76,
      ),
      ServiceModel(
        id: 'srv_004',
        name: 'Gemstone Consultation',
        description:
            'Personalized gemstone recommendations based on birth chart. Expert guidance on suitable gemstones for your specific needs.',
        price: 600,
        durationInMinutes: 30,
        serviceType: ServiceType.live,
        availableDeliveryMethods: [
          DeliveryMethod.videoCall,
          DeliveryMethod.audioCall,
        ],
        iconName: 'diamond_outlined',
        astrologerId: astrologerId,
        whatsIncluded: [
          'Birth chart gemstone analysis',
          'Recommended gemstone(s)',
          'Wearing instructions',
          'Purity and authenticity tips',
          'Alternative gemstones',
        ],
        howItWorks: [
          'Share birth details and current concerns',
          'Schedule consultation',
          'Get personalized gemstone recommendations',
          'Receive wearing guidelines',
        ],
        totalBookings: 142,
        averageRating: 4.6,
        reviewCount: 98,
      ),
    ];
  }

  // Sample add-ons
  static List<AddOnModel> getMockAddOns(String serviceId) {
    return [
      const AddOnModel(
        id: 'addon_001',
        name: 'Express Delivery',
        description: 'Get your report within 12 hours instead of 24 hours',
        price: 200,
        icon: '⚡',
        isPopular: true,
      ),
      const AddOnModel(
        id: 'addon_002',
        name: 'Follow-up Session',
        description: 'Additional 15-minute consultation session',
        price: 500,
        icon: '🔄',
        isPopular: true,
      ),
      const AddOnModel(
        id: 'addon_003',
        name: 'Written Report',
        description: 'Detailed PDF report of the consultation',
        price: 300,
        icon: '📄',
      ),
      const AddOnModel(
        id: 'addon_004',
        name: 'Recorded Session',
        description: 'Get video/audio recording of your consultation',
        price: 400,
        icon: '🎥',
      ),
    ];
  }

  // Generate mock time slots for a given date
  static List<TimeSlotModel> getMockTimeSlots({
    required DateTime date,
    int durationInMinutes = 60,
  }) {
    final List<TimeSlotModel> slots = [];
    
    // Morning slots: 9 AM - 12 PM
    for (int hour = 9; hour < 12; hour++) {
      final startTime = DateTime(date.year, date.month, date.day, hour, 0);
      final endTime = startTime.add(Duration(minutes: durationInMinutes));
      
      slots.add(TimeSlotModel(
        id: 'slot_${date.day}_${hour}_00',
        startTime: startTime,
        endTime: endTime,
        isAvailable: _isSlotAvailable(hour),
      ));
    }
    
    // Afternoon slots: 2 PM - 5 PM
    for (int hour = 14; hour < 17; hour++) {
      final startTime = DateTime(date.year, date.month, date.day, hour, 0);
      final endTime = startTime.add(Duration(minutes: durationInMinutes));
      
      slots.add(TimeSlotModel(
        id: 'slot_${date.day}_${hour}_00',
        startTime: startTime,
        endTime: endTime,
        isAvailable: _isSlotAvailable(hour),
      ));
    }
    
    // Evening slots: 6 PM - 9 PM
    for (int hour = 18; hour < 21; hour++) {
      final startTime = DateTime(date.year, date.month, date.day, hour, 0);
      final endTime = startTime.add(Duration(minutes: durationInMinutes));
      
      slots.add(TimeSlotModel(
        id: 'slot_${date.day}_${hour}_00',
        startTime: startTime,
        endTime: endTime,
        isAvailable: _isSlotAvailable(hour),
      ));
    }
    
    return slots;
  }

  // Simulate some slots being unavailable
  static bool _isSlotAvailable(int hour) {
    // Make some slots unavailable for realistic simulation
    if (hour == 11 || hour == 15 || hour == 19) {
      return false; // These slots are "booked"
    }
    return true;
  }

  // Generate order number
  static String generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD${timestamp.toString().substring(7)}';
  }
}

