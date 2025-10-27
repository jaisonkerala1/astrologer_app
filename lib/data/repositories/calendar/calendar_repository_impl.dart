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
      print('📅 [CalendarRepo] Fetching consultations for date: ${date.toIso8601String()}');
      
      // Fetch from API FIRST (not cache first!)
      final astrologerId = await _getAstrologerId();
      print('🔑 [CalendarRepo] Using astrologer ID: $astrologerId');
      
      final startDate = DateTime(date.year, date.month, date.day).toIso8601String();
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      
      print('📡 [CalendarRepo] Calling API: /api/consultation/$astrologerId');
      print('📡 [CalendarRepo] Query params: startDate=$startDate, endDate=$endDate');
      
      final response = await apiService.get(
        '/api/consultation/$astrologerId',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      print('✅ [CalendarRepo] API Response received: ${response.statusCode}');

      if (response.data['success'] == true) {
        final consultationsData = response.data['data']['consultations'] as List;
        print('✅ [CalendarRepo] Found ${consultationsData.length} consultations from API');
        
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        
        // Cache the fresh data from API for offline use
        if (_isToday(date)) {
          await cacheConsultations(consultations);
          print('💾 [CalendarRepo] Cached ${consultations.length} consultations for offline use');
        }
        
        return consultations;
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to fetch consultations';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error fetching consultations from API: $e');
      print('❌ [CalendarRepo] Error type: ${e.runtimeType}');
      
      // Fallback to cache ONLY on error (offline mode)
      final cached = await getCachedConsultations();
      if (cached != null && cached.isNotEmpty) {
        print('💾 [CalendarRepo] Using cached consultations as fallback (${cached.length} total)');
        return cached.where((c) => _isSameDay(c.scheduledTime, date)).toList();
      }
      
      print('❌ [CalendarRepo] No cached data available, throwing error');
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
    // TODO: Implement backend endpoint /api/calendar/availability/:astrologerId
    // For now, return empty list as backend doesn't have this endpoint yet
    try {
      print('📅 [CalendarRepo] getAvailability called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      return [];
    } catch (e) {
      print('❌ [CalendarRepo] Error in getAvailability: $e');
      return [];
    }
  }

  @override
  Future<AvailabilityModel> createAvailability(AvailabilityModel availability) async {
    // TODO: Implement backend endpoint POST /api/calendar/availability
    try {
      print('📅 [CalendarRepo] createAvailability called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return availability; // Return the same object for now
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  @override
  Future<AvailabilityModel> updateAvailability(
    String id,
    AvailabilityModel availability,
  ) async {
    // TODO: Implement backend endpoint PUT /api/calendar/availability/:id
    try {
      print('📅 [CalendarRepo] updateAvailability called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return availability; // Return the same object for now
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  @override
  Future<void> deleteAvailability(String id) async {
    // TODO: Implement backend endpoint DELETE /api/calendar/availability/:id
    try {
      print('📅 [CalendarRepo] deleteAvailability called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      // Success - do nothing
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  // ============================================================================
  // HOLIDAY MANAGEMENT
  // ============================================================================

  @override
  Future<List<HolidayModel>> getHolidays(String astrologerId) async {
    // TODO: Implement backend endpoint /api/calendar/holidays/:astrologerId
    // For now, return empty list as backend doesn't have this endpoint yet
    try {
      print('📅 [CalendarRepo] getHolidays called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return [];
    } catch (e) {
      print('❌ [CalendarRepo] Error in getHolidays: $e');
      return [];
    }
  }

  @override
  Future<HolidayModel> createHoliday(HolidayModel holiday) async {
    // TODO: Implement backend endpoint POST /api/calendar/holidays
    try {
      print('📅 [CalendarRepo] createHoliday called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return holiday; // Return the same object for now
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  @override
  Future<HolidayModel> updateHoliday(String id, HolidayModel holiday) async {
    // TODO: Implement backend endpoint PUT /api/calendar/holidays/:id
    try {
      print('📅 [CalendarRepo] updateHoliday called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return holiday; // Return the same object for now
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    // TODO: Implement backend endpoint DELETE /api/calendar/holidays/:id
    try {
      print('📅 [CalendarRepo] deleteHoliday called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      // Success - do nothing
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  // ============================================================================
  // TIME SLOT MANAGEMENT
  // ============================================================================

  @override
  Future<List<TimeSlotModel>> getAvailableTimeSlots(DateTime date) async {
    // TODO: Implement backend endpoint /api/calendar/timeslots/:astrologerId
    // For now, return empty list as backend doesn't have this endpoint yet
    try {
      print('📅 [CalendarRepo] getAvailableTimeSlots called - Backend not implemented yet');
      await Future.delayed(const Duration(milliseconds: 300));
      return [];
    } catch (e) {
      print('❌ [CalendarRepo] Error in getAvailableTimeSlots: $e');
      return [];
    }
  }

  @override
  Future<TimeSlotModel> bookTimeSlot(String slotId) async {
    // TODO: Implement backend endpoint POST /api/calendar/timeslots/:slotId/book
    try {
      print('📅 [CalendarRepo] bookTimeSlot called - Backend not implemented yet');
      throw Exception('Backend endpoint not implemented yet');
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
    }
  }

  @override
  Future<void> cancelTimeSlot(String slotId) async {
    // TODO: Implement backend endpoint POST /api/calendar/timeslots/:slotId/cancel
    try {
      print('📅 [CalendarRepo] cancelTimeSlot called - Backend not implemented yet');
      throw Exception('Backend endpoint not implemented yet');
    } catch (e) {
      throw Exception('Backend endpoint not implemented yet');
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
      print('🔍 [CalendarRepo] Getting astrologer ID from storage...');
      final userData = await storageService.getUserData();
      
      if (userData != null) {
        print('📦 [CalendarRepo] User data found in storage');
        final userDataMap = jsonDecode(userData);
        print('📦 [CalendarRepo] User data map keys: ${userDataMap.keys.toList()}');
        
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        
        if (astrologerId != null) {
          print('✅ [CalendarRepo] Astrologer ID retrieved: $astrologerId');
          return astrologerId;
        } else {
          print('❌ [CalendarRepo] Astrologer ID is null in user data');
          print('📦 [CalendarRepo] Full user data: $userDataMap');
        }
      } else {
        print('❌ [CalendarRepo] No user data found in storage');
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error getting astrologer ID: $e');
      print('❌ [CalendarRepo] Error type: ${e.runtimeType}');
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


