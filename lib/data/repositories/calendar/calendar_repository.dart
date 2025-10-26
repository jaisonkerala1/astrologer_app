import '../../../features/calendar/models/availability_model.dart';
import '../../../features/calendar/models/time_slot_model.dart';
import '../../../features/calendar/models/holiday_model.dart';
import '../../../features/consultations/models/consultation_model.dart';

/// Abstract interface for Calendar operations
abstract class CalendarRepository {
  // Consultation queries
  Future<List<ConsultationModel>> getConsultationsForDate(DateTime date);
  Future<List<ConsultationModel>> getConsultationsForDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  // Availability Management
  Future<List<AvailabilityModel>> getAvailability(String astrologerId);
  Future<AvailabilityModel> createAvailability(AvailabilityModel availability);
  Future<AvailabilityModel> updateAvailability(String id, AvailabilityModel availability);
  Future<void> deleteAvailability(String id);
  
  // Holiday Management
  Future<List<HolidayModel>> getHolidays(String astrologerId);
  Future<HolidayModel> createHoliday(HolidayModel holiday);
  Future<HolidayModel> updateHoliday(String id, HolidayModel holiday);
  Future<void> deleteHoliday(String id);
  
  // Time Slot Management
  Future<List<TimeSlotModel>> getAvailableTimeSlots(DateTime date);
  Future<TimeSlotModel> bookTimeSlot(String slotId);
  Future<void> cancelTimeSlot(String slotId);
  
  // Cache management
  Future<void> cacheConsultations(List<ConsultationModel> consultations);
  Future<List<ConsultationModel>?> getCachedConsultations();
  Future<void> clearCache();
}


