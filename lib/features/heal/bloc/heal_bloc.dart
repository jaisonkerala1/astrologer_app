import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/heal/heal_repository.dart';
import '../../../core/services/socket_service.dart';
import '../models/service_model.dart';
import '../models/service_request_model.dart';
import 'heal_event.dart';
import 'heal_state.dart';

class HealBloc extends Bloc<HealEvent, HealState> {
  final HealRepository repository;
  final SocketService _socketService;
  
  // Socket stream subscriptions
  StreamSubscription? _serviceRequestNewSubscription;
  StreamSubscription? _serviceRequestStatusSubscription;
  StreamSubscription? _serviceRequestNotesSubscription;
  StreamSubscription? _serviceRequestDeleteSubscription;
  StreamSubscription? _serviceRequestUpdateSubscription;

  HealBloc({
    required this.repository,
    SocketService? socketService,
  })  : _socketService = socketService ?? SocketService(),
        super(const HealInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<ToggleServiceStatusEvent>(_onToggleServiceStatus);
    on<LoadServiceRequestsEvent>(_onLoadServiceRequests);
    on<CreateServiceRequestEvent>(_onCreateServiceRequest);
    on<UpdateRequestStatusEvent>(_onUpdateRequestStatus);
    on<AddRequestNotesEvent>(_onAddRequestNotes);
    on<CancelRequestEvent>(_onCancelRequest);
    on<LoadServiceStatisticsEvent>(_onLoadStatistics);
    on<RefreshHealEvent>(_onRefresh);
    
    // Subscribe to socket events for real-time updates
    _subscribeToSocketEvents();
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

  Future<void> _onCreateServiceRequest(CreateServiceRequestEvent event, Emitter<HealState> emit) async {
    print('📘 [HealBloc] Creating service request for: ${event.request.customerName}');
    
    final previousState = state is HealLoadedState ? state as HealLoadedState : null;
    
    if (previousState == null) {
      print('⚠️ [HealBloc] Cannot create request - no loaded state');
      return;
    }
    
    try {
      final newRequest = await repository.createServiceRequest(event.request);
      
      final updatedRequests = [newRequest, ...previousState.serviceRequests];
      
      print('✅ [HealBloc] Service request created: ${newRequest.id}');
      
      emit(previousState.copyWith(
        serviceRequests: updatedRequests,
        successMessage: 'Service request created successfully',
      ));
    } catch (e) {
      print('❌ [HealBloc] Error creating service request: $e');
      emit(previousState.copyWith(
        errorMessage: 'Failed to create service request. Please try again.',
      ));
    }
  }

  Future<void> _onUpdateRequestStatus(UpdateRequestStatusEvent event, Emitter<HealState> emit) async {
    print('📘 [HealBloc] Optimistic update: ${event.id} to ${event.status.name}');
    
    final previousState = state is HealLoadedState ? state as HealLoadedState : null;
    
    if (previousState == null) {
      print('⚠️ [HealBloc] Cannot update request - no loaded state');
      return;
    }
    
    // Find the request being updated
    final originalRequest = previousState.serviceRequests.firstWhere(
      (r) => r.id == event.id,
      orElse: () => previousState.serviceRequests.first,
    );
    
    // ⚡ STEP 1: UPDATE UI IMMEDIATELY (Optimistic)
    final optimisticRequests = previousState.serviceRequests.map((r) {
      if (r.id == event.id) {
        return r.copyWith(
          status: event.status,
          startedAt: event.status == RequestStatus.inProgress 
              ? (r.startedAt ?? DateTime.now())
              : r.startedAt,
        );
      }
      return r;
    }).toList();
    
    print('⚡ [HealBloc] UI updated instantly (optimistic)');
    
    emit(previousState.copyWith(
      serviceRequests: optimisticRequests,
    ));
    
    // 🌐 STEP 2: SEND TO SERVER IN BACKGROUND
    try {
      final updated = await repository.updateRequestStatus(event.id, event.status);
      
      // ✅ STEP 3: CONFIRM WITH SERVER DATA
      final confirmedRequests = previousState.serviceRequests.map((r) => 
        r.id == event.id ? updated : r
      ).toList();
      
      print('✅ [HealBloc] Server confirmed update');
      
      // No success message needed - optimistic UI already showed the change!
      emit(previousState.copyWith(
        serviceRequests: confirmedRequests,
      ));
    } catch (e) {
      // ❌ STEP 4: REVERT ON ERROR
      print('❌ [HealBloc] Server failed, reverting optimistic update: $e');
      
      // Restore original state
      final revertedRequests = previousState.serviceRequests.map((r) => 
        r.id == event.id ? originalRequest : r
      ).toList();
      
      emit(previousState.copyWith(
        serviceRequests: revertedRequests,
        errorMessage: 'Failed to update request. Please try again.',
      ));
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
    try {
      print('🔄 [HealBloc] Refreshing service requests...');
      
      // If we have loaded data, emit with isRefreshing: true (keeps cards visible)
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(
          isRefreshing: true,
          errorMessage: null,
          successMessage: null,
        ));
      }
      
      // Fetch fresh data in background
      final requests = await repository.getServiceRequests();
      print('✅ [HealBloc] Refreshed ${requests.length} service requests');
      
      // Emit loaded state with fresh data and isRefreshing: false
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(
          serviceRequests: requests,
          isRefreshing: false,
          errorMessage: null,
          successMessage: null,
        ));
      } else {
        // Fallback: if not in loaded state, just emit new loaded state
        emit(HealLoadedState(
          services: [],
          serviceRequests: requests,
          isRefreshing: false,
        ));
      }
    } catch (e) {
      print('❌ [HealBloc] Error refreshing: $e');
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        emit(currentState.copyWith(
          isRefreshing: false,
          errorMessage: 'Failed to refresh. Please try again.',
        ));
      }
    }
  }

  // ============================================================================
  // REAL-TIME SOCKET SUBSCRIPTIONS
  // ============================================================================

  void _subscribeToSocketEvents() {
    print('🔌 [HealBloc] Subscribing to service request socket events');

    // Listen for new service requests
    _serviceRequestNewSubscription = _socketService.serviceRequestNewStream.listen((data) {
      print('🆕 [HealBloc] Real-time: New service request received: ${data['requestId']}');
      
      if (state is HealLoadedState) {
        // Refresh the list to show the new request
        add(const LoadServiceRequestsEvent());
      }
    });

    // Listen for status updates
    _serviceRequestStatusSubscription = _socketService.serviceRequestStatusStream.listen((data) {
      print('🔄 [HealBloc] Real-time: Status update for ${data['requestId']}: ${data['status']}');
      
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        
        // Find and update the specific request
        final updatedRequests = currentState.serviceRequests.map((request) {
          if (request.id == data['requestId']) {
            // Parse status from string to enum
            RequestStatus? newStatus;
            try {
              final statusStr = data['status'] as String;
              newStatus = RequestStatus.values.firstWhere(
                (e) => e.name == statusStr,
                orElse: () => request.status,
              );
            } catch (e) {
              newStatus = request.status;
            }
            
            return request.copyWith(
              status: newStatus,
              startedAt: data['startedAt'] != null ? DateTime.parse(data['startedAt']) : request.startedAt,
              completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : request.completedAt,
              cancelledAt: data['cancelledAt'] != null ? DateTime.parse(data['cancelledAt']) : request.cancelledAt,
              confirmedAt: data['confirmedAt'] != null ? DateTime.parse(data['confirmedAt']) : request.confirmedAt,
            );
          }
          return request;
        }).toList();
        
        emit(currentState.copyWith(serviceRequests: updatedRequests));
        print('✅ [HealBloc] Real-time: Request status updated in state');
      }
    });

    // Listen for notes updates
    _serviceRequestNotesSubscription = _socketService.serviceRequestNotesStream.listen((data) {
      print('📝 [HealBloc] Real-time: Notes update for ${data['requestId']}');
      
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        
        final updatedRequests = currentState.serviceRequests.map((request) {
          if (request.id == data['requestId']) {
            return request.copyWith(notes: data['notes'] as String?);
          }
          return request;
        }).toList();
        
        emit(currentState.copyWith(serviceRequests: updatedRequests));
      }
    });

    // Listen for deletions
    _serviceRequestDeleteSubscription = _socketService.serviceRequestDeleteStream.listen((data) {
      print('🗑️ [HealBloc] Real-time: Request deleted: ${data['requestId']}');
      
      if (state is HealLoadedState) {
        final currentState = state as HealLoadedState;
        
        final updatedRequests = currentState.serviceRequests
            .where((request) => request.id != data['requestId'])
            .toList();
        
        emit(currentState.copyWith(serviceRequests: updatedRequests));
      }
    });

    // Listen for general updates
    _serviceRequestUpdateSubscription = _socketService.serviceRequestUpdateStream.listen((data) {
      print('🔄 [HealBloc] Real-time: General update for ${data['requestId']}');
      
      // For general updates, we could refresh the entire list or update specific fields
      // For now, just refresh the list
      if (state is HealLoadedState) {
        add(const LoadServiceRequestsEvent());
      }
    });
  }

  @override
  Future<void> close() {
    // Cancel all socket subscriptions
    _serviceRequestNewSubscription?.cancel();
    _serviceRequestStatusSubscription?.cancel();
    _serviceRequestNotesSubscription?.cancel();
    _serviceRequestDeleteSubscription?.cancel();
    _serviceRequestUpdateSubscription?.cancel();
    
    print('🔌 [HealBloc] Unsubscribed from service request socket events');
    
    return super.close();
  }
}


