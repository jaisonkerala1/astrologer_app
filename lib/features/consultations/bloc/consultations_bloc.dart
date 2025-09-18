import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/consultation_model.dart';
import '../services/consultations_service.dart';
import 'consultations_event.dart';
import 'consultations_state.dart';

class ConsultationsBloc extends Bloc<ConsultationsEvent, ConsultationsState> {
  final ConsultationsService _consultationsService = ConsultationsService();

  ConsultationsBloc() : super(const ConsultationsInitial()) {
    on<LoadConsultationsEvent>(_onLoadConsultations);
    on<RefreshConsultationsEvent>(_onRefreshConsultations);
    on<UpdateConsultationStatusEvent>(_onUpdateConsultationStatus);
    on<AddConsultationEvent>(_onAddConsultation);
    on<CancelConsultationEvent>(_onCancelConsultation);
    on<StartConsultationEvent>(_onStartConsultation);
    on<CompleteConsultationEvent>(_onCompleteConsultation);
    on<FilterConsultationsEvent>(_onFilterConsultations);
  }

  Future<void> _onLoadConsultations(
    LoadConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(const ConsultationsLoading());
      
      final consultations = await _consultationsService.getConsultations();
      
      emit(_buildLoadedState(consultations));
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshConsultations(
    RefreshConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      final consultations = await _consultationsService.getConsultations();
      
      if (state is ConsultationsLoaded) {
        final currentState = state as ConsultationsLoaded;
        emit(_buildLoadedState(
          consultations,
          activeFilter: currentState.activeFilter,
          dateFilter: currentState.dateFilter,
        ));
      } else {
        emit(_buildLoadedState(consultations));
      }
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateConsultationStatus(
    UpdateConsultationStatusEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      final updatedConsultation = await _consultationsService.updateConsultationStatus(
        event.consultationId,
        event.newStatus,
      );
      
      emit(ConsultationUpdated(consultation: updatedConsultation));
      
      // Reload consultations to get updated state
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onAddConsultation(
    AddConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      await _consultationsService.addConsultation(event.consultation);
      
      // Reload consultations to include the new one
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onCancelConsultation(
    CancelConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      await _consultationsService.updateConsultationStatus(
        event.consultationId,
        ConsultationStatus.cancelled,
      );
      
      // Reload consultations
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onStartConsultation(
    StartConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      await _consultationsService.updateConsultationStatus(
        event.consultationId,
        ConsultationStatus.inProgress,
      );
      
      // Reload consultations
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onCompleteConsultation(
    CompleteConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      await _consultationsService.completeConsultation(
        event.consultationId,
        event.notes,
      );
      
      // Reload consultations
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onFilterConsultations(
    FilterConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    if (state is ConsultationsLoaded) {
      final currentState = state as ConsultationsLoaded;
      
      emit(_buildLoadedState(
        currentState.consultations,
        activeFilter: event.statusFilter,
        dateFilter: event.dateFilter,
      ));
    }
  }

  ConsultationsLoaded _buildLoadedState(
    List<ConsultationModel> allConsultations, {
    ConsultationStatus? activeFilter,
    DateTime? dateFilter,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Filter consultations based on active filter
    List<ConsultationModel> filteredConsultations = allConsultations;
    
    if (activeFilter != null) {
      filteredConsultations = allConsultations
          .where((c) => c.status == activeFilter)
          .toList();
    }
    
    if (dateFilter != null) {
      final filterDay = DateTime(dateFilter.year, dateFilter.month, dateFilter.day);
      final nextDay = filterDay.add(const Duration(days: 1));
      
      filteredConsultations = filteredConsultations
          .where((c) => 
              c.scheduledTime.isAfter(filterDay) && 
              c.scheduledTime.isBefore(nextDay))
          .toList();
    }

    // Categorize consultations
    final todayConsultations = allConsultations
        .where((c) => 
            c.scheduledTime.isAfter(today) && 
            c.scheduledTime.isBefore(tomorrow))
        .toList();

    final upcomingConsultations = allConsultations
        .where((c) => 
            c.scheduledTime.isAfter(now) && 
            (c.status == ConsultationStatus.scheduled || 
             c.status == ConsultationStatus.inProgress))
        .toList();

    final completedConsultations = allConsultations
        .where((c) => c.status == ConsultationStatus.completed)
        .toList();

    // Sort consultations
    filteredConsultations.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    todayConsultations.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    upcomingConsultations.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    completedConsultations.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    return ConsultationsLoaded(
      consultations: filteredConsultations,
      todayConsultations: todayConsultations,
      upcomingConsultations: upcomingConsultations,
      completedConsultations: completedConsultations,
      activeFilter: activeFilter,
      dateFilter: dateFilter,
    );
  }
}
