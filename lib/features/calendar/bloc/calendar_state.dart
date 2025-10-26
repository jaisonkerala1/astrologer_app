import 'package:equatable/equatable.dart';
import '../models/availability_model.dart';
import '../models/holiday_model.dart';
import '../models/time_slot_model.dart';
import '../../consultations/models/consultation_model.dart';

/// Abstract base class for all Calendar states
abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the calendar is first loaded
class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

/// State when calendar data is being loaded
class CalendarLoading extends CalendarState {
  final bool isInitialLoad;

  const CalendarLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

/// State when calendar data is successfully loaded
class CalendarLoadedState extends CalendarState {
  final DateTime selectedDate;
  final List<ConsultationModel> consultations;
  final List<AvailabilityModel> availabilities;
  final List<HolidayModel> holidays;
  final List<TimeSlotModel> timeSlots;
  final String? successMessage;

  CalendarLoadedState({
    required this.selectedDate,
    required this.consultations,
    required this.availabilities,
    required this.holidays,
    required this.timeSlots,
    this.successMessage,
  });

  @override
  List<Object?> get props => [
        selectedDate,
        consultations,
        availabilities,
        holidays,
        timeSlots,
        successMessage,
      ];

  /// Copy with method for easy state updates
  CalendarLoadedState copyWith({
    DateTime? selectedDate,
    List<ConsultationModel>? consultations,
    List<AvailabilityModel>? availabilities,
    List<HolidayModel>? holidays,
    List<TimeSlotModel>? timeSlots,
    String? successMessage,
  }) {
    return CalendarLoadedState(
      selectedDate: selectedDate ?? this.selectedDate,
      consultations: consultations ?? this.consultations,
      availabilities: availabilities ?? this.availabilities,
      holidays: holidays ?? this.holidays,
      timeSlots: timeSlots ?? this.timeSlots,
      successMessage: successMessage,
    );
  }

  /// Helper: Get consultations for the selected date
  List<ConsultationModel> get consultationsForSelectedDate {
    return consultations.where((c) {
      return c.scheduledTime.year == selectedDate.year &&
          c.scheduledTime.month == selectedDate.month &&
          c.scheduledTime.day == selectedDate.day;
    }).toList();
  }

  /// Helper: Check if selected date has consultations
  bool get hasConsultationsOnSelectedDate {
    return consultationsForSelectedDate.isNotEmpty;
  }

  /// Helper: Get holidays for the selected date
  List<HolidayModel> get holidaysForSelectedDate {
    return holidays.where((h) {
      return h.date.year == selectedDate.year &&
          h.date.month == selectedDate.month &&
          h.date.day == selectedDate.day;
    }).toList();
  }

  /// Helper: Check if selected date is a holiday
  bool get isSelectedDateHoliday {
    return holidaysForSelectedDate.isNotEmpty;
  }

  /// Helper: Get availability for selected date's day of week
  List<AvailabilityModel> get availabilitiesForSelectedDate {
    final dayOfWeek = selectedDate.weekday % 7; // Convert to 0=Sunday format
    return availabilities.where((a) => a.dayOfWeek == dayOfWeek && a.isActive).toList();
  }

  /// Helper: Check if selected date is available
  bool get isSelectedDateAvailable {
    return availabilitiesForSelectedDate.isNotEmpty && !isSelectedDateHoliday;
  }

  /// Helper: Get available time slots
  List<TimeSlotModel> get availableTimeSlots {
    return timeSlots.where((slot) => slot.canBook).toList();
  }

  /// Helper: Get booked time slots
  List<TimeSlotModel> get bookedTimeSlots {
    return timeSlots.where((slot) => slot.isBooked).toList();
  }
}

/// State when there's an error loading calendar data
class CalendarErrorState extends CalendarState {
  final String message;

  const CalendarErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when availability is being updated
class AvailabilityUpdating extends CalendarState {
  final String availabilityId;

  const AvailabilityUpdating(this.availabilityId);

  @override
  List<Object?> get props => [availabilityId];
}

/// State when holiday is being updated
class HolidayUpdating extends CalendarState {
  final String holidayId;

  const HolidayUpdating(this.holidayId);

  @override
  List<Object?> get props => [holidayId];
}

/// State when time slot is being booked/cancelled
class TimeSlotUpdating extends CalendarState {
  final String slotId;

  const TimeSlotUpdating(this.slotId);

  @override
  List<Object?> get props => [slotId];
}


