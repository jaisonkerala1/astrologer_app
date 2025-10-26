import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/calendar/calendar_repository.dart';
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
    emit(const CalendarLoading());

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
    emit(const CalendarLoading(isInitialLoad: false));

    try {
      final consultations = await repository.getConsultationsForDateRange(
        event.startDate,
        event.endDate,
      );

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        emit(currentState.copyWith(consultations: consultations));
      } else {
        emit(CalendarLoadedState(
          selectedDate: event.startDate,
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

      // Update selected date and load data for that date
      emit(currentState.copyWith(selectedDate: event.date));

      // Load consultations and time slots for the new date
      add(LoadConsultationsForDateEvent(event.date));
      add(LoadTimeSlotsEvent(event.date));
    } else {
      // If not loaded yet, trigger initial load
      add(LoadConsultationsForDateEvent(event.date));
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
      final availabilities = await repository.getAvailability(event.astrologerId);

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
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateAvailability(
    CreateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const AvailabilityUpdating(''));

    try {
      final newAvailability = await repository.createAvailability(event.availability);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedAvailabilities = List.of(currentState.availabilities)
          ..add(newAvailability);

        emit(currentState.copyWith(
          availabilities: updatedAvailabilities,
          successMessage: 'Availability created successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(AvailabilityUpdating(event.id));

    try {
      final updatedAvailability = await repository.updateAvailability(
        event.id,
        event.availability,
      );

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedAvailabilities = currentState.availabilities.map((a) {
          return a.id == event.id ? updatedAvailability : a;
        }).toList();

        emit(currentState.copyWith(
          availabilities: updatedAvailabilities,
          successMessage: 'Availability updated successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAvailability(
    DeleteAvailabilityEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(AvailabilityUpdating(event.id));

    try {
      await repository.deleteAvailability(event.id);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedAvailabilities = currentState.availabilities
            .where((a) => a.id != event.id)
            .toList();

        emit(currentState.copyWith(
          availabilities: updatedAvailabilities,
          successMessage: 'Availability deleted successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
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
      final holidays = await repository.getHolidays(event.astrologerId);

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
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateHoliday(
    CreateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const HolidayUpdating(''));

    try {
      final newHoliday = await repository.createHoliday(event.holiday);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedHolidays = List.of(currentState.holidays)..add(newHoliday);

        emit(currentState.copyWith(
          holidays: updatedHolidays,
          successMessage: 'Holiday created successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateHoliday(
    UpdateHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(HolidayUpdating(event.id));

    try {
      final updatedHoliday = await repository.updateHoliday(event.id, event.holiday);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedHolidays = currentState.holidays.map((h) {
          return h.id == event.id ? updatedHoliday : h;
        }).toList();

        emit(currentState.copyWith(
          holidays: updatedHolidays,
          successMessage: 'Holiday updated successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteHoliday(
    DeleteHolidayEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(HolidayUpdating(event.id));

    try {
      await repository.deleteHoliday(event.id);

      if (state is CalendarLoadedState) {
        final currentState = state as CalendarLoadedState;
        final updatedHolidays =
            currentState.holidays.where((h) => h.id != event.id).toList();

        emit(currentState.copyWith(
          holidays: updatedHolidays,
          successMessage: 'Holiday deleted successfully',
        ));
      }
    } catch (e) {
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
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
      emit(CalendarErrorState(e.toString().replaceAll('Exception: ', '')));
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
      
      // Reload all data
      add(LoadConsultationsForDateEvent(currentState.selectedDate));
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


