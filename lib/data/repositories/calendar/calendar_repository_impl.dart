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
    try {
      print('📅 [CalendarRepo] Fetching availability for astrologer: $astrologerId');
      
      final response = await apiService.get(
        '/api/calendar/availability/$astrologerId',
      );

      print('✅ [CalendarRepo] Availability API response: ${response.statusCode}');

      if (response.data['success'] == true) {
        final availabilityData = response.data['data'] as List;
        print('✅ [CalendarRepo] Found ${availabilityData.length} availability slots');
        
        return availabilityData
            .map((json) => AvailabilityModel.fromJson(json))
            .toList();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to fetch availability';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error fetching availability: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AvailabilityModel> createAvailability(AvailabilityModel availability) async {
    try {
      print('📅 [CalendarRepo] Creating availability');
      
      final response = await apiService.post(
        '/api/calendar/availability',
        data: availability.toJson(),
      );

      print('✅ [CalendarRepo] Create availability response: ${response.statusCode}');

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Availability created successfully');
        return AvailabilityModel.fromJson(response.data['data']);
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to create availability';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error creating availability: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AvailabilityModel> updateAvailability(
    String id,
    AvailabilityModel availability,
  ) async {
    try {
      print('📅 [CalendarRepo] Updating availability: $id');
      
      final response = await apiService.put(
        '/api/calendar/availability/$id',
        data: availability.toJson(),
      );

      print('✅ [CalendarRepo] Update availability response: ${response.statusCode}');

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Availability updated successfully');
        return AvailabilityModel.fromJson(response.data['data']);
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to update availability';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error updating availability: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteAvailability(String id) async {
    try {
      print('📅 [CalendarRepo] Deleting availability: $id');
      
      final response = await apiService.delete(
        '/api/calendar/availability/$id',
      );

      print('✅ [CalendarRepo] Delete availability response: ${response.statusCode}');

      if (response.data['success'] != true) {
        final errorMsg = response.data['message'] ?? 'Failed to delete availability';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
      
      print('✅ [CalendarRepo] Availability deleted successfully');
    } catch (e) {
      print('❌ [CalendarRepo] Error deleting availability: $e');
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // HOLIDAY MANAGEMENT
  // ============================================================================

  @override
  Future<List<HolidayModel>> getHolidays(String astrologerId) async {
    try {
      print('📅 [CalendarRepo] Fetching holidays for astrologer: $astrologerId');
      
      final response = await apiService.get(
        '/api/calendar/holidays/$astrologerId',
      );

      print('✅ [CalendarRepo] Holidays API response: ${response.statusCode}');

      if (response.data['success'] == true) {
        final holidaysData = response.data['data'] as List;
        print('✅ [CalendarRepo] Found ${holidaysData.length} holidays');
        
        return holidaysData
            .map((json) => HolidayModel.fromJson(json))
            .toList();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to fetch holidays';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error fetching holidays: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<HolidayModel> createHoliday(HolidayModel holiday) async {
    try {
      print('📅 [CalendarRepo] Creating holiday');
      
      final response = await apiService.post(
        '/api/calendar/holidays',
        data: holiday.toJson(),
      );

      print('✅ [CalendarRepo] Create holiday response: ${response.statusCode}');

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Holiday created successfully');
        return HolidayModel.fromJson(response.data['data']);
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to create holiday';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error creating holiday: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<HolidayModel> updateHoliday(String id, HolidayModel holiday) async {
    try {
      print('📅 [CalendarRepo] Updating holiday: $id');
      
      final response = await apiService.put(
        '/api/calendar/holidays/$id',
        data: holiday.toJson(),
      );

      print('✅ [CalendarRepo] Update holiday response: ${response.statusCode}');

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Holiday updated successfully');
        return HolidayModel.fromJson(response.data['data']);
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to update holiday';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error updating holiday: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    try {
      print('📅 [CalendarRepo] Deleting holiday: $id');
      
      final response = await apiService.delete(
        '/api/calendar/holidays/$id',
      );

      print('✅ [CalendarRepo] Delete holiday response: ${response.statusCode}');

      if (response.data['success'] != true) {
        final errorMsg = response.data['message'] ?? 'Failed to delete holiday';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
      
      print('✅ [CalendarRepo] Holiday deleted successfully');
    } catch (e) {
      print('❌ [CalendarRepo] Error deleting holiday: $e');
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
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('📅 [CalendarRepo] Fetching time slots for $dateStr');
      
      final response = await apiService.get(
        '/api/calendar/time-slots/$astrologerId/$dateStr',
      );

      print('✅ [CalendarRepo] Time slots API response: ${response.statusCode}');

      if (response.data['success'] == true) {
        final slotsData = response.data['data'] as List;
        print('✅ [CalendarRepo] Found ${slotsData.length} time slots');
        
        // If no slots exist, generate them
        if (slotsData.isEmpty) {
          print('📅 [CalendarRepo] No slots found, generating time slots');
          await _generateTimeSlots(astrologerId, dateStr);
          
          // Re-fetch after generation
          final retryResponse = await apiService.get(
            '/api/calendar/time-slots/$astrologerId/$dateStr',
          );
          
          if (retryResponse.data['success'] == true) {
            final retryData = retryResponse.data['data'] as List;
            print('✅ [CalendarRepo] Generated ${retryData.length} time slots');
            return retryData
                .map((json) => TimeSlotModel.fromJson(json))
                .toList();
          }
        }
        
        return slotsData
            .map((json) => TimeSlotModel.fromJson(json))
            .toList();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to fetch time slots';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error fetching time slots: $e');
      throw Exception(handleError(e));
    }
  }

  Future<void> _generateTimeSlots(String astrologerId, String date) async {
    try {
      print('📅 [CalendarRepo] Generating time slots for $date');
      
      final response = await apiService.post(
        '/api/calendar/generate-time-slots',
        data: {
          'astrologerId': astrologerId,
          'date': date,
        },
      );

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Time slots generated successfully');
      } else {
        print('⚠️ [CalendarRepo] Time slot generation returned success=false');
      }
    } catch (e) {
      print('⚠️ [CalendarRepo] Error generating time slots: $e');
      // Don't throw - generation might fail if availability not set
    }
  }

  @override
  Future<TimeSlotModel> bookTimeSlot(String slotId) async {
    try {
      print('📅 [CalendarRepo] Booking time slot: $slotId');
      
      final response = await apiService.post(
        '/api/calendar/book-slot',
        data: {'slotId': slotId},
      );

      print('✅ [CalendarRepo] Book slot response: ${response.statusCode}');

      if (response.data['success'] == true) {
        print('✅ [CalendarRepo] Slot booked successfully');
        return TimeSlotModel.fromJson(response.data['data']);
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to book slot';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [CalendarRepo] Error booking slot: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> cancelTimeSlot(String slotId) async {
    try {
      print('📅 [CalendarRepo] Cancelling time slot: $slotId');
      
      final response = await apiService.post(
        '/api/calendar/cancel-booking',
        data: {'slotId': slotId},
      );

      print('✅ [CalendarRepo] Cancel booking response: ${response.statusCode}');

      if (response.data['success'] != true) {
        final errorMsg = response.data['message'] ?? 'Failed to cancel booking';
        print('❌ [CalendarRepo] API returned success=false: $errorMsg');
        throw Exception(errorMsg);
      }
      
      print('✅ [CalendarRepo] Booking cancelled successfully');
    } catch (e) {
      print('❌ [CalendarRepo] Error cancelling booking: $e');
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
    // Retry up to 3 times with delay to handle race conditions
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('🔍 [CalendarRepo] Getting astrologer ID from storage (attempt $attempt/3)...');
        final userData = await storageService.getUserData();
        
        if (userData != null) {
          print('📦 [CalendarRepo] User data found in storage');
          final userDataMap = jsonDecode(userData);
          print('📦 [CalendarRepo] User data map keys: ${userDataMap.keys.toList()}');
          
          final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
          
          if (astrologerId != null && astrologerId.isNotEmpty) {
            print('✅ [CalendarRepo] Astrologer ID retrieved: $astrologerId');
            return astrologerId;
          } else {
            print('❌ [CalendarRepo] Astrologer ID is null or empty in user data');
            print('📦 [CalendarRepo] Full user data: $userDataMap');
          }
        } else {
          print('❌ [CalendarRepo] No user data found in storage');
        }
      } catch (e) {
        print('❌ [CalendarRepo] Error getting astrologer ID: $e');
        print('❌ [CalendarRepo] Error type: ${e.runtimeType}');
      }
      
      // Wait before retry (except on last attempt)
      if (attempt < 3) {
        print('⏳ [CalendarRepo] Retrying after 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    throw Exception('Astrologer ID not found. Please ensure you are logged in.');
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


