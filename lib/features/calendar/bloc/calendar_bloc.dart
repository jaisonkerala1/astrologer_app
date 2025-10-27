import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/calendar/calendar_repository.dart';
import '../models/availability_model.dart';
import '../models/holiday_model.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

/// BLoC for managing calendar, availability, and holiday states
/// Follows clean architecture principles with repository pattern
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository repository;

  CalendarBloc({required this.repository}) : super(const CalendarInitial()) {
    on<LoadConsultationsForDateEvent>(_onLoadConsultationsForDate);
    on<LoadConsultationsForDateRangeEvent>(_onLoadConsultationsForDateRange);
    on<ChangeSelectedDateEvent>(_onChangeSelectedDate);
    on<NavigateToTodayEvent>(_onNavigateToToday);
    on<LoadAvailabilityEvent>(_onLoadAvailability);
    on<CreateAvailabilityEvent>(_onCreateAvailability);
    on<UpdateAvailabilityEvent>(_onUpdateAvailability);
    on<DeleteAvailabilityEvent>(_onDeleteAvailability);
    on<LoadHolidaysEvent>(_onLoadHolidays);
    on<CreateHolidayEvent>(_onCreateHoliday);
    on<UpdateHolidayEvent>(_onUpdateHoliday);
    on<DeleteHolidayEvent>(_onDeleteHoliday);
    on<LoadTimeSlotsEvent>(_onLoadTimeSlots);
    on<BookTimeSlotEvent>(_onBookTimeSlot);
    on<CancelTimeSlotEvent>(_onCancelTimeSlot);
    on<RefreshCalendarEvent>(_onRefreshCalendar);
    on<ClearCalendarCacheEvent>(_onClearCache);
  }

  // ============================================================================
  // CONSULTATION LOADING
  // ============================================================================

  Future<void> _onLoadConsultationsForDate(
    LoadConsultationsForDateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // Only show loading state if we don't already have data
    // This prevents flickering and empty states during refresh
    if (state is! CalendarLoadedState) {
      emit(const CalendarLoading(isInitialLoad: true));
    }

    try {
      final consultations = await repository.getConsultationsForDate(event.date);

      // If we have a loaded state, preserve other data
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(
          selectedDate: event.date,
          consultations: consultations,
        ));
      } else {
        // Initial load - create new state
        emit(CalendarLoadedState(
          selectedDate: event.date,
          consultations: consultations,
          availabilities: [],
          holidays: [],
          timeSlots: [],
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadConsultationsForDateRange(
    LoadConsultationsForDateRangeEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // Only show loading state if we don't already have data
    if (state is! CalendarLoadedState) {
      emit(const CalendarLoading(isInitialLoad: true));
    }

    try {
      final consultations = await repository.getConsultationsForDateRange(
        event.startDate,
        event.endDate,
      );

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(consultations: consultations));
      } else {
        // Initial load - select today's date
        final now = DateTime.now();
        emit(CalendarLoadedState(
          selectedDate: DateTime(now.year, now.month, now.day),
          consultations: consultations,
          availabilities: [],
          holidays: [],
          timeSlots: [],
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // NAVIGATION EVENTS
  // ============================================================================

  Future<void> _onChangeSelectedDate(
    ChangeSelectedDateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;

      // Update selected date
      emit(currentState.copyWith(selectedDate: event.date));

      // Load consultations for the entire month (not just the selected date)
      // This ensures calendar dots show for all dates with consultations
      final firstDayOfMonth = DateTime(event.date.year, event.date.month, 1);
      final lastDayOfMonth = DateTime(event.date.year, event.date.month + 1, 0, 23, 59, 59);
      add(LoadConsultationsForDateRangeEvent(
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      ));
      add(LoadTimeSlotsEvent(event.date));
    } else {
      // If not loaded yet, trigger initial load for the month
      final firstDayOfMonth = DateTime(event.date.year, event.date.month, 1);
      final lastDayOfMonth = DateTime(event.date.year, event.date.month + 1, 0, 23, 59, 59);
      add(LoadConsultationsForDateRangeEvent(
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      ));
    }
  }

  Future<void> _onNavigateToToday(
    NavigateToTodayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    final today = DateTime.now();
    add(ChangeSelectedDateEvent(today));
  }

  // ============================================================================
  // AVAILABILITY MANAGEMENT
  // ============================================================================

  Future<void> _onLoadAvailability(
    LoadAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      var availabilities = await repository.getAvailability(event.astrologerId);
      
      // TODO: Remove this when backend is ready - Generate sample data for demo
      if (availabilities.isEmpty) {
        print('📅 [CalendarBloc] Generating sample availability (backend not ready)');
        availabilities = _generateSampleAvailability(event.astrologerId);
      }

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(availabilities: availabilities));
      } else {
        emit(CalendarLoadedState(
          selectedDate: DateTime.now(),
          consultations: [],
          availabilities: availabilities,
          holidays: [],
          timeSlots: [],
        ));
      }
    } catch (e) {
      // Don't emit error state if availability fails - backend not implemented yet
      // Just log the error and generate sample data
      print('⚠️ [CalendarBloc] Failed to load availability (backend not implemented): $e');
      
      // Generate sample data
      final sampleAvailabilities = _generateSampleAvailability(event.astrologerId);
      
      if (state is! CalendarLoadedState) {
        emit(CalendarLoadedState(
          selectedDate: DateTime.now(),
          consultations: [],
          availabilities: sampleAvailabilities,
          holidays: [],
          timeSlots: [],
        ));
      }
    }
  }
  
  List<AvailabilityModel> _generateSampleAvailability(String astrologerId) {
    // Generate sample availability for Monday to Friday
    final availability = <AvailabilityModel>[];
    for (int day = 1; day <= 5; day++) {
      availability.add(AvailabilityModel(
        id: 'local_avail_$day',
        astrologerId: astrologerId,
        dayOfWeek: day,
        startTime: '09:00',
        endTime: '18:00',
        isActive: true,
        breaks: [
          BreakTime(
            startTime: '13:00',
            endTime: '14:00',
            reason: 'Lunch Break',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    return availability;
  }

  Future<void> _onCreateAvailability(
    CreateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented
    
    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedAvailabilities = List.of(currentState.availabilities)
        ..add(event.availability);

      emit(currentState.copyWith(
        availabilities: updatedAvailabilities,
        successMessage: 'Availability created successfully',
      ));
      
      print('✅ [CalendarBloc] Availability created locally (backend not ready): ${event.availability.dayName}');
    }
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented

    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedAvailabilities = currentState.availabilities.map((a) {
        return a.id == event.id ? event.availability : a;
      }).toList();

      emit(currentState.copyWith(
        availabilities: updatedAvailabilities,
        successMessage: 'Availability updated successfully',
      ));
      
      print('✅ [CalendarBloc] Availability updated locally (backend not ready): ${event.availability.dayName}');
    }
  }

  Future<void> _onDeleteAvailability(
    DeleteAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented

    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedAvailabilities = currentState.availabilities
          .where((a) => a.id != event.id)
          .toList();

      emit(currentState.copyWith(
        availabilities: updatedAvailabilities,
        successMessage: 'Availability deleted successfully',
      ));
      
      print('✅ [CalendarBloc] Availability deleted locally (backend not ready): ${event.id}');
    }
  }

  // ============================================================================
  // HOLIDAY MANAGEMENT
  // ============================================================================

  Future<void> _onLoadHolidays(
    LoadHolidaysEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      var holidays = await repository.getHolidays(event.astrologerId);
      
      // TODO: Remove this when backend is ready - Generate sample data for demo
      if (holidays.isEmpty) {
        print('📅 [CalendarBloc] Generating sample holidays (backend not ready)');
        holidays = _generateSampleHolidays(event.astrologerId);
      }

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(holidays: holidays));
      } else {
        emit(CalendarLoadedState(
          selectedDate: DateTime.now(),
          consultations: [],
          availabilities: [],
          holidays: holidays,
          timeSlots: [],
        ));
      }
    } catch (e) {
      // Don't emit error state if holidays fail - backend not implemented yet
      // Just log the error and generate sample data
      print('⚠️ [CalendarBloc] Failed to load holidays (backend not implemented): $e');
      
      // Generate sample data
      final sampleHolidays = _generateSampleHolidays(event.astrologerId);
      
      if (state is! CalendarLoadedState) {
        emit(CalendarLoadedState(
          selectedDate: DateTime.now(),
          consultations: [],
          availabilities: [],
          holidays: sampleHolidays,
          timeSlots: [],
        ));
      }
    }
  }
  
  List<HolidayModel> _generateSampleHolidays(String astrologerId) {
    // Generate sample holidays
    final holidays = <HolidayModel>[];
    holidays.addAll([
      HolidayModel(
        id: 'local_holiday_1',
        astrologerId: astrologerId,
        date: DateTime(2025, 1, 26), // Republic Day
        reason: 'Republic Day',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
      HolidayModel(
        id: 'local_holiday_2',
        astrologerId: astrologerId,
        date: DateTime(2025, 3, 8), // Holi
        reason: 'Holi',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
      HolidayModel(
        id: 'local_holiday_3',
        astrologerId: astrologerId,
        date: DateTime(2025, 8, 15), // Independence Day
        reason: 'Independence Day',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
      HolidayModel(
        id: 'local_holiday_4',
        astrologerId: astrologerId,
        date: DateTime(2025, 10, 2), // Gandhi Jayanti
        reason: 'Gandhi Jayanti',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
    ]);
    return holidays;
  }

  Future<void> _onCreateHoliday(
    CreateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented
    
    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedHolidays = List.of(currentState.holidays)
        ..add(event.holiday);

      emit(currentState.copyWith(
        holidays: updatedHolidays,
        successMessage: 'Holiday created successfully',
      ));
      
      print('✅ [CalendarBloc] Holiday created locally (backend not ready): ${event.holiday.reason}');
    }
  }

  Future<void> _onUpdateHoliday(
    UpdateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented

    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedHolidays = currentState.holidays.map((h) {
        return h.id == event.id ? event.holiday : h;
      }).toList();

      emit(currentState.copyWith(
        holidays: updatedHolidays,
        successMessage: 'Holiday updated successfully',
      ));
      
      print('✅ [CalendarBloc] Holiday updated locally (backend not ready): ${event.holiday.reason}');
    }
  }

  Future<void> _onDeleteHoliday(
    DeleteHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // TODO: Call repository when backend is ready
    // For now, do optimistic local update since backend not implemented

    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      final updatedHolidays =
          currentState.holidays.where((h) => h.id != event.id).toList();

      emit(currentState.copyWith(
        holidays: updatedHolidays,
        successMessage: 'Holiday deleted successfully',
      ));
      
      print('✅ [CalendarBloc] Holiday deleted locally (backend not ready): ${event.id}');
    }
  }

  // ============================================================================
  // TIME SLOT MANAGEMENT
  // ============================================================================

  Future<void> _onLoadTimeSlots(
    LoadTimeSlotsEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final timeSlots = await repository.getAvailableTimeSlots(event.date);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(timeSlots: timeSlots));
      } else {
        emit(CalendarLoadedState(
          selectedDate: event.date,
          consultations: [],
          availabilities: [],
          holidays: [],
          timeSlots: timeSlots,
        ));
      }
    } catch (e) {
      // Don't emit error state if timeslots fail - backend not implemented yet
      // Just log the error and keep the current state
      print('⚠️ [CalendarBloc] Failed to load time slots (backend not implemented): $e');
      
      // Keep current state if we have one
      if (state is CalendarLoadedState) {
        // State is already loaded, just skip updating time slots
        return;
      }
    }
  }

  Future<void> _onBookTimeSlot(
    BookTimeSlotEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(TimeSlotUpdating(event.slotId));

    try {
      final bookedSlot = await repository.bookTimeSlot(event.slotId);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedTimeSlots = currentState.timeSlots.map((slot) {
          return slot.id == event.slotId ? bookedSlot : slot;
        }).toList();

        emit(currentState.copyWith(
          timeSlots: updatedTimeSlots,
          successMessage: 'Time slot booked successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelTimeSlot(
    CancelTimeSlotEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(TimeSlotUpdating(event.slotId));

    try {
      await repository.cancelTimeSlot(event.slotId);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        // Reload time slots for the current date
        add(LoadTimeSlotsEvent(currentState.selectedDate));

        emit(currentState.copyWith(
          successMessage: 'Time slot cancelled successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // REFRESH & CACHE
  // ============================================================================

  Future<void> _onRefreshCalendar(
    RefreshCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoadedState) {
      final currentState = state as CalendarLoadedState;
      
      // Reload entire month (not just selected date) to show all dots
      final selectedDate = currentState.selectedDate;
      final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
      
      add(LoadConsultationsForDateRangeEvent(
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      ));
      add(LoadTimeSlotsEvent(currentState.selectedDate));
    }
  }

  Future<void> _onClearCache(
    ClearCalendarCacheEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await repository.clearCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}


