import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/heal/heal_repository.dart';
import '../models/service_model.dart';
import '../models/service_request_model.dart';
import 'heal_event.dart';
import 'heal_state.dart';

class HealBloc extends Bloc<HealEvent, HealState> {
  final HealRepository repository;

  HealBloc({required this.repository}) : super(const HealInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<ToggleServiceStatusEvent>(_onToggleServiceStatus);
    on<LoadServiceRequestsEvent>(_onLoadServiceRequests);
    on<UpdateRequestStatusEvent>(_onUpdateRequestStatus);
    on<AddRequestNotesEvent>(_onAddRequestNotes);
    on<CancelRequestEvent>(_onCancelRequest);
    on<LoadServiceStatisticsEvent>(_onLoadStatistics);
    on<RefreshHealEvent>(_onRefresh);
  }

  Future<void> _onLoadServices(LoadServicesEvent event, Emitter<HealState> emit) async {
    // 🚀 PHASE 1: INSTANT LOAD - Show data immediately (no spinner!)
    // This makes the app feel instant like WhatsApp/Instagram
    try {
      final instantData = repository.getInstantData(); // Synchronous, no await!
      final instantServices = (instantData['services'] as List).cast<ServiceModel>();
      final instantRequests = (instantData['requests'] as List).cast<ServiceRequest>();
      
      if (instantServices.isNotEmpty) {
        // Emit data instantly with refreshing flag
        emit(HealLoadedState(
          services: instantServices,
          serviceRequests: instantRequests,
          isRefreshing: true, // Show subtle refresh indicator
        ));
      } else {
        // Only show full loading spinner if absolutely no data exists
        emit(const HealLoading());
      }
    } catch (e) {
      // If instant data fails (shouldn't happen), show spinner
      emit(const HealLoading());
    }

    // 🔄 PHASE 2: BACKGROUND REFRESH - Silently fetch fresh data
    try {
      final services = await repository.getServices(category: event.category);
      final requests = await repository.getServiceRequests();
      
      emit(HealLoadedState(
        services: services,
        serviceRequests: requests,
        isRefreshing: false, // Hide refresh indicator
      ));
    } catch (e) {
      // If refresh fails but we already showed data, just hide refresh indicator
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        // Only show error if no data was shown
        emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  Future<void> _onCreateService(CreateServiceEvent event, Emitter<HealState> emit) async {
    emit(const ServiceUpdating(''));
    try {
      final newService = await repository.createService(event.service);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        final updatedServices = List.of(currentState.services)..add(newService);
        emit(currentState.copyWith(
          services: updatedServices,
          successMessage: 'Service created successfully',
        ));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateService(UpdateServiceEvent event, Emitter<HealState> emit) async {
    emit(ServiceUpdating(event.id));
    try {
      final updated = await repository.updateService(event.id, event.service);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        final updatedServices = currentState.services.map((s) => 
          s.id == event.id ? updated : s
        ).toList();
        emit(currentState.copyWith(
          services: updatedServices,
          successMessage: 'Service updated successfully',
        ));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteService(DeleteServiceEvent event, Emitter<HealState> emit) async {
    emit(ServiceUpdating(event.id));
    try {
      await repository.deleteService(event.id);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        final updatedServices = currentState.services.where((s) => s.id != event.id).toList();
        emit(currentState.copyWith(
          services: updatedServices,
          successMessage: 'Service deleted successfully',
        ));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleServiceStatus(ToggleServiceStatusEvent event, Emitter<HealState> emit) async {
    emit(ServiceUpdating(event.id));
    try {
      final updated = await repository.toggleServiceStatus(event.id, event.isActive);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        final updatedServices = currentState.services.map((s) => 
          s.id == event.id ? updated : s
        ).toList();
        emit(currentState.copyWith(
          services: updatedServices,
          successMessage: 'Service status updated',
        ));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadServiceRequests(LoadServiceRequestsEvent event, Emitter<HealState> emit) async {
    try {
      final requests = await repository.getServiceRequests(status: event.status);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(serviceRequests: requests));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateRequestStatus(UpdateRequestStatusEvent event, Emitter<HealState> emit) async {
    print('📘 [HealBloc] Updating request status: ${event.id} to ${event.status.name}');
    
    // Don't emit RequestUpdating to avoid screen flicker
    // Just update silently in the background
    final previousState = state is HealLoadedState ? state as HealLoadedState : null;
    
    if (previousState == null) {
      print('⚠️ [HealBloc] Cannot update request - no loaded state');
      return;
    }
    
    try {
      final updated = await repository.updateRequestStatus(event.id, event.status);
      
      final updatedRequests = previousState.serviceRequests.map((r) => 
        r.id == event.id ? updated : r
      ).toList();
      
      print('📘 [HealBloc] Emitting updated state with ${updatedRequests.length} requests');
      
      emit(previousState.copyWith(
        serviceRequests: updatedRequests,
        successMessage: 'Request status updated',
      ));
    } catch (e) {
      print('❌ [HealBloc] Error updating request status: $e');
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddRequestNotes(AddRequestNotesEvent event, Emitter<HealState> emit) async {
    emit(RequestUpdating(event.id));
    try {
      final updated = await repository.addRequestNotes(event.id, event.notes);
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        final updatedRequests = currentState.serviceRequests.map((r) => 
          r.id == event.id ? updated : r
        ).toList();
        emit(currentState.copyWith(
          serviceRequests: updatedRequests,
          successMessage: 'Notes added successfully',
        ));
      }
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelRequest(CancelRequestEvent event, Emitter<HealState> emit) async {
    emit(RequestUpdating(event.id));
    try {
      await repository.cancelRequest(event.id);
      add(const LoadServiceRequestsEvent());
    } catch (e) {
      emit(HealErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadStatistics(LoadServiceStatisticsEvent event, Emitter<HealState> emit) async {
    try {
      final stats = await repository.getServiceStatistics();
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(statistics: stats));
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _onRefresh(RefreshHealEvent event, Emitter<HealState> emit) async {
    add(const LoadServicesEvent());
  }
}


