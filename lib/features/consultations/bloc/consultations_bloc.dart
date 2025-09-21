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
    on<UpdateConsultationEvent>(_onUpdateConsultation);
    on<DeleteConsultationEvent>(_onDeleteConsultation);
    on<CancelConsultationEvent>(_onCancelConsultation);
    on<StartConsultationEvent>(_onStartConsultation);
    on<CompleteConsultationEvent>(_onCompleteConsultation);
    on<FilterConsultationsEvent>(_onFilterConsultations);
    on<AddConsultationNotesEvent>(_onAddConsultationNotes);
    on<AddConsultationRatingEvent>(_onAddConsultationRating);
  }

  Future<void> _onLoadConsultations(
    LoadConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      print('Loading consultations...');
      emit(const ConsultationsLoading());
      
      final consultations = await _consultationsService.getConsultations();
      print('Loaded ${consultations.length} consultations');
      
      for (var consultation in consultations) {
        print('Consultation ${consultation.id}: ${consultation.clientName} - ${consultation.status.displayName}');
      }
      
      emit(_buildLoadedState(consultations));
    } catch (e) {
      print('Error loading consultations: $e');
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshConsultations(
    RefreshConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      print('Refreshing consultations...');
      final consultations = await _consultationsService.getConsultations();
      print('Refreshed ${consultations.length} consultations');
      
      // Log server response for debugging
      for (var consultation in consultations) {
        if (consultation.status == ConsultationStatus.inProgress) {
          print('Server returned inProgress consultation ${consultation.id}: startedAt = ${consultation.startedAt}');
        }
      }
      
      for (var consultation in consultations) {
        print('Refreshed consultation ${consultation.id}: ${consultation.clientName} - ${consultation.status.displayName}');
        if (consultation.status == ConsultationStatus.inProgress) {
          print('  - In Progress consultation startedAt: ${consultation.startedAt}');
        }
      }
      
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
      print('Error refreshing consultations: $e');
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
        notes: event.notes,
        cancelledBy: event.cancelledBy,
        cancellationReason: event.cancellationReason,
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
    // Optimistic update: immediately update UI
    final currentState = state;
    if (currentState is ConsultationsLoaded) {
      final consultations = List<ConsultationModel>.from(currentState.allConsultations);
      final newConsultation = event.consultation.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );
      consultations.add(newConsultation);
      
      // Emit updated state immediately
      emit(_buildLoadedState(
        consultations,
        activeFilter: currentState.activeFilter,
        dateFilter: currentState.dateFilter,
      ));
      
      print('Optimistically added consultation: ${newConsultation.clientName}');
    }
    
    try {
      print('Adding consultation: ${event.consultation.clientName}');
      final createdConsultation = await _consultationsService.addConsultation(event.consultation);
      print('Consultation added successfully: ${createdConsultation.clientName}');
      
      // Update the optimistic consultation with the real one from server
      if (currentState is ConsultationsLoaded) {
        final consultations = List<ConsultationModel>.from(currentState.allConsultations);
        final consultationIndex = consultations.indexWhere(
          (c) => c.id == event.consultation.id || c.clientName == event.consultation.clientName,
        );
        
        if (consultationIndex != -1) {
          consultations[consultationIndex] = createdConsultation;
        } else {
          consultations.add(createdConsultation);
        }
        
        emit(_buildLoadedState(
          consultations,
          activeFilter: currentState.activeFilter,
          dateFilter: currentState.dateFilter,
        ));
      }
    } catch (e) {
      print('Error adding consultation: $e');
      // Revert optimistic update on error
      if (currentState is ConsultationsLoaded) {
        add(const RefreshConsultationsEvent());
      }
      emit(ConsultationsError(message: 'Failed to add consultation: ${e.toString()}'));
    }
  }

  Future<void> _onCancelConsultation(
    CancelConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    // Optimistic update: immediately update UI
    final currentState = state;
    if (currentState is ConsultationsLoaded) {
      final consultations = List<ConsultationModel>.from(currentState.consultations);
      final consultationIndex = consultations.indexWhere((c) => c.id == event.consultationId);
      
      if (consultationIndex != -1) {
        // Update consultation optimistically
        consultations[consultationIndex] = consultations[consultationIndex].copyWith(
          status: ConsultationStatus.cancelled,
          cancelledAt: DateTime.now(),
        );
        
        // Emit updated state immediately
        emit(currentState.copyWith(
          consultations: consultations,
          allConsultations: consultations,
        ));
        
        print('Optimistically updated consultation to Cancelled');
      }
    }
    
    try {
      print('Cancelling consultation API call: ${event.consultationId}');
      
      await _consultationsService.updateConsultationStatus(
        event.consultationId,
        ConsultationStatus.cancelled,
      );
      
      print('Consultation cancelled successfully, refreshing data...');
      // Reload consultations to sync with server
      add(const RefreshConsultationsEvent());
    } catch (e) {
      print('Error cancelling consultation: $e');
      // Revert optimistic update on error
      add(const RefreshConsultationsEvent());
      emit(ConsultationsError(message: 'Failed to cancel consultation: ${e.toString()}'));
    }
  }

  Future<void> _onStartConsultation(
    StartConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    // Optimistic update: immediately update UI
    final currentState = state;
    if (currentState is ConsultationsLoaded) {
      final consultations = List<ConsultationModel>.from(currentState.consultations);
      final consultationIndex = consultations.indexWhere((c) => c.id == event.consultationId);
      
      if (consultationIndex != -1) {
        // Update consultation optimistically and store the optimistic startedAt
        final optimisticStartTime = DateTime.now();
        print('Setting optimistic startedAt to: $optimisticStartTime');
        
        consultations[consultationIndex] = consultations[consultationIndex].copyWith(
          status: ConsultationStatus.inProgress,
          startedAt: optimisticStartTime,
        );
        
        // Emit updated state immediately
        emit(currentState.copyWith(
          consultations: consultations,
          allConsultations: consultations,
        ));
        
        print('Optimistically updated consultation to In Progress with startedAt: ${consultations[consultationIndex].startedAt}');
      }
    }
    
    try {
      print('Starting consultation API call: ${event.consultationId}');
      
      await _consultationsService.updateConsultationStatus(
        event.consultationId,
        ConsultationStatus.inProgress,
      );
      
      print('Consultation started successfully, refreshing data...');
      // Reload consultations to sync with server
      add(const RefreshConsultationsEvent());
    } catch (e) {
      print('Error starting consultation: $e');
      // Revert optimistic update on error
      add(const RefreshConsultationsEvent());
      emit(ConsultationsError(message: 'Failed to start consultation: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteConsultation(
    CompleteConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    // Optimistic update: immediately update UI
    final currentState = state;
    if (currentState is ConsultationsLoaded) {
      final consultations = List<ConsultationModel>.from(currentState.consultations);
      final consultationIndex = consultations.indexWhere((c) => c.id == event.consultationId);
      
      if (consultationIndex != -1) {
        // Update consultation optimistically
        consultations[consultationIndex] = consultations[consultationIndex].copyWith(
          status: ConsultationStatus.completed,
          completedAt: DateTime.now(),
          notes: event.notes,
        );
        
        // Emit updated state immediately
        emit(currentState.copyWith(
          consultations: consultations,
          allConsultations: consultations,
        ));
        
        print('Optimistically updated consultation to Completed');
      }
    }
    
    try {
      print('Completing consultation API call: ${event.consultationId}');
      
      await _consultationsService.completeConsultation(
        event.consultationId,
        event.notes,
      );
      
      print('Consultation completed successfully, refreshing data...');
      // Reload consultations to sync with server
      add(const RefreshConsultationsEvent());
    } catch (e) {
      print('Error completing consultation: $e');
      // Revert optimistic update on error
      add(const RefreshConsultationsEvent());
      emit(ConsultationsError(message: 'Failed to complete consultation: ${e.toString()}'));
    }
  }

  Future<void> _onFilterConsultations(
    FilterConsultationsEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    if (state is ConsultationsLoaded) {
      final currentState = state as ConsultationsLoaded;
      
      emit(_buildLoadedState(
        currentState.allConsultations, // Use original data for filtering
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
      allConsultations: allConsultations, // Store original data
      consultations: filteredConsultations, // Filtered data for display
      todayConsultations: todayConsultations,
      upcomingConsultations: upcomingConsultations,
      completedConsultations: completedConsultations,
      activeFilter: activeFilter,
      dateFilter: dateFilter,
    );
  }

  Future<void> _onUpdateConsultation(
    UpdateConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultation.id));
      
      final updatedConsultation = await _consultationsService.updateConsultation(
        event.consultation,
      );
      
      emit(ConsultationUpdated(consultation: updatedConsultation));
      
      // Reload consultations to get updated state
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteConsultation(
    DeleteConsultationEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      await _consultationsService.deleteConsultation(event.consultationId);
      
      emit(const ConsultationDeleted());
      
      // Reload consultations to get updated state
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onAddConsultationNotes(
    AddConsultationNotesEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      final updatedConsultation = await _consultationsService.addConsultationNotes(
        event.consultationId,
        event.notes,
      );
      
      emit(ConsultationUpdated(consultation: updatedConsultation));
      
      // Reload consultations to get updated state
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }

  Future<void> _onAddConsultationRating(
    AddConsultationRatingEvent event,
    Emitter<ConsultationsState> emit,
  ) async {
    try {
      emit(ConsultationUpdating(consultationId: event.consultationId));
      
      final updatedConsultation = await _consultationsService.addConsultationRating(
        event.consultationId,
        event.rating,
        event.feedback,
      );
      
      emit(ConsultationUpdated(consultation: updatedConsultation));
      
      // Reload consultations to get updated state
      add(const RefreshConsultationsEvent());
    } catch (e) {
      emit(ConsultationsError(message: e.toString()));
    }
  }
}
