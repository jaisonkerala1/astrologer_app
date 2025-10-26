import 'package:equatable/equatable.dart';
import '../models/service_model.dart';
import '../models/service_request_model.dart';

abstract class HealState extends Equatable {
  const HealState();
  
  @override
  List<Object?> get props => [];
}

class HealInitial extends HealState {
  const HealInitial();
}

class HealLoading extends HealState {
  final bool isInitialLoad;
  const HealLoading({this.isInitialLoad = true});
  @override
  List<Object?> get props => [isInitialLoad];
}

class HealLoadedState extends HealState {
  final List<ServiceModel> services;
  final List<ServiceRequest> serviceRequests;
  final Map<String, dynamic>? statistics;
  final String? successMessage;

  HealLoadedState({
    required this.services,
    required this.serviceRequests,
    this.statistics,
    this.successMessage,
  });

  @override
  List<Object?> get props => [services, serviceRequests, statistics, successMessage];

  HealLoadedState copyWith({
    List<ServiceModel>? services,
    List<ServiceRequest>? serviceRequests,
    Map<String, dynamic>? statistics,
    String? successMessage,
  }) {
    return HealLoadedState(
      services: services ?? this.services,
      serviceRequests: serviceRequests ?? this.serviceRequests,
      statistics: statistics ?? this.statistics,
      successMessage: successMessage,
    );
  }

  // Helpers
  List<ServiceModel> get activeServices =>
      services.where((s) => s.isActive).toList();
  
  List<ServiceRequest> get pendingRequests =>
      serviceRequests.where((r) => r.status == RequestStatus.pending).toList();
  
  List<ServiceRequest> get activeRequests =>
      serviceRequests.where((r) => 
        r.status == RequestStatus.confirmed || 
        r.status == RequestStatus.inProgress
      ).toList();
  
  int get totalServices => services.length;
  int get totalRequests => serviceRequests.length;
}

class HealErrorState extends HealState {
  final String message;
  const HealErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class ServiceUpdating extends HealState {
  final String serviceId;
  const ServiceUpdating(this.serviceId);
  @override
  List<Object?> get props => [serviceId];
}

class RequestUpdating extends HealState {
  final String requestId;
  const RequestUpdating(this.requestId);
  @override
  List<Object?> get props => [requestId];
}


