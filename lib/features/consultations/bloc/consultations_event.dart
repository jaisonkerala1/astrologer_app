import 'package:equatable/equatable.dart';
import '../models/consultation_model.dart';

abstract class ConsultationsEvent extends Equatable {
  const ConsultationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadConsultationsEvent extends ConsultationsEvent {
  const LoadConsultationsEvent();
}

class RefreshConsultationsEvent extends ConsultationsEvent {
  const RefreshConsultationsEvent();
}

class UpdateConsultationStatusEvent extends ConsultationsEvent {
  final String consultationId;
  final ConsultationStatus newStatus;

  const UpdateConsultationStatusEvent({
    required this.consultationId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [consultationId, newStatus];
}

class AddConsultationEvent extends ConsultationsEvent {
  final ConsultationModel consultation;

  const AddConsultationEvent({
    required this.consultation,
  });

  @override
  List<Object?> get props => [consultation];
}

class CancelConsultationEvent extends ConsultationsEvent {
  final String consultationId;

  const CancelConsultationEvent({
    required this.consultationId,
  });

  @override
  List<Object?> get props => [consultationId];
}

class StartConsultationEvent extends ConsultationsEvent {
  final String consultationId;

  const StartConsultationEvent({
    required this.consultationId,
  });

  @override
  List<Object?> get props => [consultationId];
}

class CompleteConsultationEvent extends ConsultationsEvent {
  final String consultationId;
  final String? notes;

  const CompleteConsultationEvent({
    required this.consultationId,
    this.notes,
  });

  @override
  List<Object?> get props => [consultationId, notes];
}

class FilterConsultationsEvent extends ConsultationsEvent {
  final ConsultationStatus? statusFilter;
  final DateTime? dateFilter;

  const FilterConsultationsEvent({
    this.statusFilter,
    this.dateFilter,
  });

  @override
  List<Object?> get props => [statusFilter, dateFilter];
}
