import 'package:equatable/equatable.dart';
import '../models/service_model.dart';
import '../models/service_request_model.dart';

abstract class HealEvent extends Equatable {
  const HealEvent();

  @override
  List<Object?> get props => [];
}

// Services Events
class LoadServicesEvent extends HealEvent {
  final String? category;
  const LoadServicesEvent({this.category});
  @override
  List<Object?> get props => [category];
}

class CreateServiceEvent extends HealEvent {
  final ServiceModel service;
  const CreateServiceEvent(this.service);
  @override
  List<Object?> get props => [service];
}

class UpdateServiceEvent extends HealEvent {
  final String id;
  final ServiceModel service;
  const UpdateServiceEvent(this.id, this.service);
  @override
  List<Object?> get props => [id, service];
}

class DeleteServiceEvent extends HealEvent {
  final String id;
  const DeleteServiceEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleServiceStatusEvent extends HealEvent {
  final String id;
  final bool isActive;
  const ToggleServiceStatusEvent(this.id, this.isActive);
  @override
  List<Object?> get props => [id, isActive];
}

// Service Requests Events
class LoadServiceRequestsEvent extends HealEvent {
  final RequestStatus? status;
  const LoadServiceRequestsEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class CreateServiceRequestEvent extends HealEvent {
  final ServiceRequest request;
  const CreateServiceRequestEvent(this.request);
  @override
  List<Object?> get props => [request];
}

class UpdateRequestStatusEvent extends HealEvent {
  final String id;
  final RequestStatus status;
  const UpdateRequestStatusEvent(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

class AddRequestNotesEvent extends HealEvent {
  final String id;
  final String notes;
  const AddRequestNotesEvent(this.id, this.notes);
  @override
  List<Object?> get props => [id, notes];
}

class CancelRequestEvent extends HealEvent {
  final String id;
  const CancelRequestEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadServiceStatisticsEvent extends HealEvent {
  const LoadServiceStatisticsEvent();
}

class RefreshHealEvent extends HealEvent {
  const RefreshHealEvent();
}


