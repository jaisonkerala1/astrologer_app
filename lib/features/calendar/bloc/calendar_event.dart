import 'package:equatable/equatable.dart';
import '../models/availability_model.dart';
import '../models/holiday_model.dart';

/// Abstract base class for all Calendar events
abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// CALENDAR NAVIGATION EVENTS
// ============================================================================

/// Event to load consultations for a specific date
class LoadConsultationsForDateEvent extends CalendarEvent {
  final DateTime date;

  const LoadConsultationsForDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to load consultations for a date range
class LoadConsultationsForDateRangeEvent extends CalendarEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadConsultationsForDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to change the selected date
class ChangeSelectedDateEvent extends CalendarEvent {
  final DateTime date;

  const ChangeSelectedDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to navigate to today
class NavigateToTodayEvent extends CalendarEvent {
  const NavigateToTodayEvent();
}

// ============================================================================
// AVAILABILITY EVENTS
// ============================================================================

/// Event to load availability
class LoadAvailabilityEvent extends CalendarEvent {
  final String astrologerId;

  const LoadAvailabilityEvent(this.astrologerId);

  @override
  List<Object?> get props => [astrologerId];
}

/// Event to create new availability
class CreateAvailabilityEvent extends CalendarEvent {
  final AvailabilityModel availability;

  const CreateAvailabilityEvent(this.availability);

  @override
  List<Object?> get props => [availability];
}

/// Event to update existing availability
class UpdateAvailabilityEvent extends CalendarEvent {
  final String id;
  final AvailabilityModel availability;

  const UpdateAvailabilityEvent({
    required this.id,
    required this.availability,
  });

  @override
  List<Object?> get props => [id, availability];
}

/// Event to delete availability
class DeleteAvailabilityEvent extends CalendarEvent {
  final String id;

  const DeleteAvailabilityEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// ============================================================================
// HOLIDAY EVENTS
// ============================================================================

/// Event to load holidays
class LoadHolidaysEvent extends CalendarEvent {
  final String astrologerId;

  const LoadHolidaysEvent(this.astrologerId);

  @override
  List<Object?> get props => [astrologerId];
}

/// Event to create new holiday
class CreateHolidayEvent extends CalendarEvent {
  final HolidayModel holiday;

  const CreateHolidayEvent(this.holiday);

  @override
  List<Object?> get props => [holiday];
}

/// Event to update existing holiday
class UpdateHolidayEvent extends CalendarEvent {
  final String id;
  final HolidayModel holiday;

  const UpdateHolidayEvent({
    required this.id,
    required this.holiday,
  });

  @override
  List<Object?> get props => [id, holiday];
}

/// Event to delete holiday
class DeleteHolidayEvent extends CalendarEvent {
  final String id;

  const DeleteHolidayEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// ============================================================================
// TIME SLOT EVENTS
// ============================================================================

/// Event to load available time slots for a date
class LoadTimeSlotsEvent extends CalendarEvent {
  final DateTime date;

  const LoadTimeSlotsEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to book a time slot
class BookTimeSlotEvent extends CalendarEvent {
  final String slotId;

  const BookTimeSlotEvent(this.slotId);

  @override
  List<Object?> get props => [slotId];
}

/// Event to cancel a booked time slot
class CancelTimeSlotEvent extends CalendarEvent {
  final String slotId;

  const CancelTimeSlotEvent(this.slotId);

  @override
  List<Object?> get props => [slotId];
}

// ============================================================================
// REFRESH & CACHE EVENTS
// ============================================================================

/// Event to refresh calendar data
class RefreshCalendarEvent extends CalendarEvent {
  const RefreshCalendarEvent();
}

/// Event to clear cache
class ClearCalendarCacheEvent extends CalendarEvent {
  const ClearCalendarCacheEvent();
}


