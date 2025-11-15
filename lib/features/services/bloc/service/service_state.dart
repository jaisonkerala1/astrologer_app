import 'package:equatable/equatable.dart';
import '../../models/service_model.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

/// Loading state
class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

/// Services loaded successfully
class ServicesLoaded extends ServiceState {
  final List<ServiceModel> services;

  const ServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

/// Single service detail loaded
class ServiceDetailLoaded extends ServiceState {
  final ServiceModel service;

  const ServiceDetailLoaded(this.service);

  @override
  List<Object?> get props => [service];
}

/// Time slots loaded
class ServiceSlotsLoaded extends ServiceState {
  final List<TimeSlotModel> slots;
  final DateTime date;

  const ServiceSlotsLoaded({
    required this.slots,
    required this.date,
  });

  @override
  List<Object?> get props => [slots, date];
}

/// Add-ons loaded
class ServiceAddOnsLoaded extends ServiceState {
  final List<AddOnModel> addOns;

  const ServiceAddOnsLoaded(this.addOns);

  @override
  List<Object?> get props => [addOns];
}

/// Promo code validated
class PromoCodeValidated extends ServiceState {
  final bool isValid;
  final double discount;
  final String message;

  const PromoCodeValidated({
    required this.isValid,
    required this.discount,
    required this.message,
  });

  @override
  List<Object?> get props => [isValid, discount, message];
}

/// Error state
class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}

