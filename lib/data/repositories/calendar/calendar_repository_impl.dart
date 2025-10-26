import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/calendar/models/availability_model.dart';
import '../../../features/calendar/models/time_slot_model.dart';
import '../../../features/calendar/models/holiday_model.dart';
import '../../../features/consultations/models/consultation_model.dart';
import '../base_repository.dart';
import 'calendar_repository.dart';

/// Implementation of CalendarRepository
/// Handles calendar, availability, and holiday data operations
class CalendarRepositoryImpl extends BaseRepository implements CalendarRepository {
  final ApiService apiService;
  final StorageService storageService;

  CalendarRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // CONSULTATION QUERIES
  // ============================================================================

  @override
  Future<List<ConsultationModel>> getConsultationsForDate(DateTime date) async {
    try {
      // Try cache first for today
      if (_isToday(date)) {
        final cached = await getCachedConsultations();
        if (cached != null && cached.isNotEmpty) {
          return cached.where((c) => _isSameDay(c.scheduledTime, date)).toList();
        }
      }

      // Fetch from API
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/consultation/$astrologerId',
        queryParameters: {
          'startDate': DateTime(date.year, date.month, date.day).toIso8601String(),
          'endDate': DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String(),
        },
      );

      if (response.data['success'] == true) {
        final consultationsData = response.data['data']['consultations'] as List;
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        
        // Cache if today
        if (_isToday(date)) {
          await cacheConsultations(consultations);
        }
        
        return consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } catch (e) {
      // Fallback to cache on error
      final cached = await getCachedConsultations();
      if (cached != null) {
        return cached.where((c) => _isSameDay(c.scheduledTime, date)).toList();
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<ConsultationModel>> getConsultationsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/consultation/$astrologerId',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.data['success'] == true) {
        final consultationsData = response.data['data']['consultations'] as List;
        return consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // AVAILABILITY MANAGEMENT
  // ============================================================================

  @override
  Future<List<AvailabilityModel>> getAvailability(String astrologerId) async {
    try {
      final response = await apiService.get('/api/calendar/availability/$astrologerId');
      
      if (response.data['success'] == true) {
        final List<dynamic> items = response.data['data'] ?? [];
        return items.map((json) => AvailabilityModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load availability');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AvailabilityModel> createAvailability(AvailabilityModel availability) async {
    try {
      final response = await apiService.post(
        '/api/calendar/availability',
        data: availability.toJson(),
      );
      
      if (response.data['success'] == true) {
        return AvailabilityModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to create availability');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AvailabilityModel> updateAvailability(
    String id,
    AvailabilityModel availability,
  ) async {
    try {
      final response = await apiService.put(
        '/api/calendar/availability/$id',
        data: availability.toJson(),
      );
      
      if (response.data['success'] == true) {
        return AvailabilityModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update availability');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteAvailability(String id) async {
    try {
      final response = await apiService.delete('/api/calendar/availability/$id');
      
      if (response.data['success'] != true) {
        throw Exception('Failed to delete availability');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // HOLIDAY MANAGEMENT
  // ============================================================================

  @override
  Future<List<HolidayModel>> getHolidays(String astrologerId) async {
    try {
      final response = await apiService.get('/api/calendar/holidays/$astrologerId');
      
      if (response.data['success'] == true) {
        final List<dynamic> items = response.data['data'] ?? [];
        return items.map((json) => HolidayModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load holidays');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<HolidayModel> createHoliday(HolidayModel holiday) async {
    try {
      final response = await apiService.post(
        '/api/calendar/holidays',
        data: holiday.toJson(),
      );
      
      if (response.data['success'] == true) {
        return HolidayModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to create holiday');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<HolidayModel> updateHoliday(String id, HolidayModel holiday) async {
    try {
      final response = await apiService.put(
        '/api/calendar/holidays/$id',
        data: holiday.toJson(),
      );
      
      if (response.data['success'] == true) {
        return HolidayModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update holiday');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    try {
      final response = await apiService.delete('/api/calendar/holidays/$id');
      
      if (response.data['success'] != true) {
        throw Exception('Failed to delete holiday');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // TIME SLOT MANAGEMENT
  // ============================================================================

  @override
  Future<List<TimeSlotModel>> getAvailableTimeSlots(DateTime date) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/calendar/timeslots/$astrologerId',
        queryParameters: {
          'date': date.toIso8601String(),
        },
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> items = response.data['data'] ?? [];
        return items.map((json) => TimeSlotModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load time slots');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<TimeSlotModel> bookTimeSlot(String slotId) async {
    try {
      final response = await apiService.post(
        '/api/calendar/timeslots/$slotId/book',
      );
      
      if (response.data['success'] == true) {
        return TimeSlotModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to book time slot');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> cancelTimeSlot(String slotId) async {
    try {
      final response = await apiService.post(
        '/api/calendar/timeslots/$slotId/cancel',
      );
      
      if (response.data['success'] != true) {
        throw Exception('Failed to cancel time slot');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  @override
  Future<void> cacheConsultations(List<ConsultationModel> consultations) async {
    try {
      final jsonString = jsonEncode(
        consultations.map((c) => c.toJson()).toList(),
      );
      await storageService.setString('calendar_consultations_cache', jsonString);
      await storageService.setString(
        'calendar_cache_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error caching consultations: $e');
    }
  }

  @override
  Future<List<ConsultationModel>?> getCachedConsultations() async {
    try {
      final jsonString = await storageService.getString('calendar_consultations_cache');
      final timestamp = await storageService.getString('calendar_cache_timestamp');
      
      if (jsonString != null && timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        // Cache valid for 5 minutes
        if (DateTime.now().difference(cacheTime).inMinutes < 5) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          return jsonList.map((json) => ConsultationModel.fromJson(json)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error getting cached consultations: $e');
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('calendar_consultations_cache');
      await storageService.remove('calendar_cache_timestamp');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<String> _getAstrologerId() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('Astrologer ID not found');
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}


