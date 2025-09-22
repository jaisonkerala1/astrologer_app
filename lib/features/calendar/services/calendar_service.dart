import '../../../core/services/api_service.dart';
import '../models/availability_model.dart';
import '../models/time_slot_model.dart';
import '../models/holiday_model.dart';

class CalendarService {
  final ApiService _apiService = ApiService();

  // Availability Management
  Future<List<AvailabilityModel>> getAvailability(String astrologerId) async {
    try {
      final response = await _apiService.get('/api/calendar/availability/$astrologerId');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => AvailabilityModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load availability');
    } catch (e) {
      print('Error loading availability: $e');
      rethrow;
    }
  }

  Future<AvailabilityModel> createAvailability(AvailabilityModel availability) async {
    try {
      final response = await _apiService.post(
        '/api/calendar/availability',
        data: availability.toJson(),
      );
      if (response['success'] == true) {
        return AvailabilityModel.fromJson(response['data']);
      }
      throw Exception('Failed to create availability');
    } catch (e) {
      print('Error creating availability: $e');
      rethrow;
    }
  }

  Future<AvailabilityModel> updateAvailability(String id, AvailabilityModel availability) async {
    try {
      final response = await _apiService.put(
        '/api/calendar/availability/$id',
        data: availability.toJson(),
      );
      if (response['success'] == true) {
        return AvailabilityModel.fromJson(response['data']);
      }
      throw Exception('Failed to update availability');
    } catch (e) {
      print('Error updating availability: $e');
      rethrow;
    }
  }

  Future<void> deleteAvailability(String id) async {
    try {
      final response = await _apiService.delete('/api/calendar/availability/$id');
      if (response['success'] != true) {
        throw Exception('Failed to delete availability');
      }
    } catch (e) {
      print('Error deleting availability: $e');
      rethrow;
    }
  }

  // Time Slots Management
  Future<List<TimeSlotModel>> getTimeSlots(String astrologerId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiService.get('/api/calendar/time-slots/$astrologerId/$dateStr');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => TimeSlotModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load time slots');
    } catch (e) {
      print('Error loading time slots: $e');
      rethrow;
    }
  }

  Future<List<TimeSlotModel>> generateTimeSlots(String astrologerId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiService.post(
        '/api/calendar/generate-time-slots',
        data: {
          'astrologerId': astrologerId,
          'date': dateStr,
        },
      );
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => TimeSlotModel.fromJson(json)).toList();
      }
      throw Exception('Failed to generate time slots');
    } catch (e) {
      print('Error generating time slots: $e');
      rethrow;
    }
  }

  Future<TimeSlotModel> bookTimeSlot(String slotId, String consultationId) async {
    try {
      final response = await _apiService.post(
        '/api/calendar/book-slot',
        data: {
          'slotId': slotId,
          'consultationId': consultationId,
        },
      );
      if (response['success'] == true) {
        return TimeSlotModel.fromJson(response['data']);
      }
      throw Exception('Failed to book time slot');
    } catch (e) {
      print('Error booking time slot: $e');
      rethrow;
    }
  }

  Future<void> cancelBooking(String slotId) async {
    try {
      final response = await _apiService.post(
        '/api/calendar/cancel-booking',
        data: {'slotId': slotId},
      );
      if (response['success'] != true) {
        throw Exception('Failed to cancel booking');
      }
    } catch (e) {
      print('Error canceling booking: $e');
      rethrow;
    }
  }

  // Holidays Management
  Future<List<HolidayModel>> getHolidays(String astrologerId) async {
    try {
      final response = await _apiService.get('/api/calendar/holidays/$astrologerId');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => HolidayModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load holidays');
    } catch (e) {
      print('Error loading holidays: $e');
      rethrow;
    }
  }

  Future<HolidayModel> createHoliday(HolidayModel holiday) async {
    try {
      final response = await _apiService.post(
        '/api/calendar/holidays',
        data: holiday.toJson(),
      );
      if (response['success'] == true) {
        return HolidayModel.fromJson(response['data']);
      }
      throw Exception('Failed to create holiday');
    } catch (e) {
      print('Error creating holiday: $e');
      rethrow;
    }
  }

  Future<void> deleteHoliday(String id) async {
    try {
      final response = await _apiService.delete('/api/calendar/holidays/$id');
      if (response['success'] != true) {
        throw Exception('Failed to delete holiday');
      }
    } catch (e) {
      print('Error deleting holiday: $e');
      rethrow;
    }
  }

  // Utility Methods
  Future<List<TimeSlotModel>> getAvailableSlots(String astrologerId, DateTime date) async {
    try {
      final slots = await getTimeSlots(astrologerId, date);
      return slots.where((slot) => slot.canBook).toList();
    } catch (e) {
      print('Error getting available slots: $e');
      return [];
    }
  }

  Future<bool> isDateAvailable(String astrologerId, DateTime date) async {
    try {
      final slots = await getAvailableSlots(astrologerId, date);
      return slots.isNotEmpty;
    } catch (e) {
      print('Error checking date availability: $e');
      return false;
    }
  }
}
