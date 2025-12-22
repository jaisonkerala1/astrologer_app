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
      print('📅 [CalendarBloc] Loading availability from API');
      final availabilities = await repository.getAvailability(event.astrologerId);
      
      print('✅ [CalendarBloc] Loaded ${availabilities.length} availability slots from API');

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
      print('❌ [CalendarBloc] Failed to load availability: $e');
      emit(CalendarErrorState('Failed to load availability: ${e.toString()}'));
    }
  }

  Future<void> _onCreateAvailability(
    CreateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Creating availability via API');
      final createdAvailability = await repository.createAvailability(event.availability);
      
      // Refresh the full list from API after creation
      final availabilities = await repository.getAvailability(createdAvailability.astrologerId);
      
      print('✅ [CalendarBloc] Availability created and list refreshed: ${createdAvailability.dayName}');
      
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(
          availabilities: availabilities,
          successMessage: 'Availability created successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to create availability: $e');
      emit(CalendarErrorState('Failed to create availability: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Updating availability via API');
      final updatedAvailability = await repository.updateAvailability(event.id, event.availability);
      
      // Refresh the full list from API after update
      final availabilities = await repository.getAvailability(updatedAvailability.astrologerId);
      
      print('✅ [CalendarBloc] Availability updated and list refreshed: ${updatedAvailability.dayName}');
      
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(
          availabilities: availabilities,
          successMessage: 'Availability updated successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to update availability: $e');
      emit(CalendarErrorState('Failed to update availability: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAvailability(
    DeleteAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Deleting availability via API');
      await repository.deleteAvailability(event.id);
      
      // Refresh the full list from API after deletion
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final astrologerId = currentState.availabilities.firstWhere((a) => a.id == event.id).astrologerId;
        final availabilities = await repository.getAvailability(astrologerId);
        
        print('✅ [CalendarBloc] Availability deleted and list refreshed');
        
        emit(currentState.copyWith(
          availabilities: availabilities,
          successMessage: 'Availability deleted successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to delete availability: $e');
      emit(CalendarErrorState('Failed to delete availability: ${e.toString()}'));
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
      print('📅 [CalendarBloc] Loading holidays from API');
      final holidays = await repository.getHolidays(event.astrologerId);
      
      print('✅ [CalendarBloc] Loaded ${holidays.length} holidays from API');

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
      print('❌ [CalendarBloc] Failed to load holidays: $e');
      emit(CalendarErrorState('Failed to load holidays: ${e.toString()}'));
    }
  }

  Future<void> _onCreateHoliday(
    CreateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Creating holiday via API');
      final createdHoliday = await repository.createHoliday(event.holiday);
      
      // Refresh the full list from API after creation
      final holidays = await repository.getHolidays(createdHoliday.astrologerId);
      
      print('✅ [CalendarBloc] Holiday created and list refreshed: ${createdHoliday.reason}');
      
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(
          holidays: holidays,
          successMessage: 'Holiday created successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to create holiday: $e');
      emit(CalendarErrorState('Failed to create holiday: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHoliday(
    UpdateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Updating holiday via API');
      final updatedHoliday = await repository.updateHoliday(event.id, event.holiday);
      
      // Refresh the full list from API after update
      final holidays = await repository.getHolidays(updatedHoliday.astrologerId);
      
      print('✅ [CalendarBloc] Holiday updated and list refreshed: ${updatedHoliday.reason}');
      
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(
          holidays: holidays,
          successMessage: 'Holiday updated successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to update holiday: $e');
      emit(CalendarErrorState('Failed to update holiday: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHoliday(
    DeleteHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      print('📅 [CalendarBloc] Deleting holiday via API');
      await repository.deleteHoliday(event.id);
      
      // Refresh the full list from API after deletion
      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final astrologerId = currentState.holidays.firstWhere((h) => h.id == event.id).astrologerId;
        final holidays = await repository.getHolidays(astrologerId);
        
        print('✅ [CalendarBloc] Holiday deleted and list refreshed');
        
        emit(currentState.copyWith(
          holidays: holidays,
          successMessage: 'Holiday deleted successfully',
        ));
      }
    } catch (e) {
      print('❌ [CalendarBloc] Failed to delete holiday: $e');
      emit(CalendarErrorState('Failed to delete holiday: ${e.toString()}'));
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
      print('📅 [CalendarBloc] Loading time slots from API');
      final timeSlots = await repository.getAvailableTimeSlots(event.date);
      
      print('✅ [CalendarBloc] Loaded ${timeSlots.length} time slots from API');

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
      print('❌ [CalendarBloc] Failed to load time slots: $e');
      // For time slots, keep current state but log the error
      // Time slots may fail if availability is not set yet - this is expected
      if (state is! CalendarLoadedState) {
        emit(CalendarErrorState('Failed to load time slots: ${e.toString()}'));
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


