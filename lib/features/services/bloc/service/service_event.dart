import 'package:equatable/equatable.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Load services for a specific astrologer
class LoadAstrologerServicesEvent extends ServiceEvent {
  final String astrologerId;

  const LoadAstrologerServicesEvent(this.astrologerId);

  @override
  List<Object?> get props => [astrologerId];
}

/// Load a specific service by ID
class LoadServiceDetailEvent extends ServiceEvent {
  final String serviceId;

  const LoadServiceDetailEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

/// Search services by keyword
class SearchServicesEvent extends ServiceEvent {
  final String query;

  const SearchServicesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Load all available services
class LoadAllServicesEvent extends ServiceEvent {
  const LoadAllServicesEvent();
}

/// Load available time slots for a service
class LoadAvailableSlotsEvent extends ServiceEvent {
  final String astrologerId;
  final DateTime date;
  final int durationInMinutes;

  const LoadAvailableSlotsEvent({
    required this.astrologerId,
    required this.date,
    required this.durationInMinutes,
  });

  @override
  List<Object?> get props => [astrologerId, date, durationInMinutes];
}

/// Load add-ons for a service
class LoadServiceAddOnsEvent extends ServiceEvent {
  final String serviceId;

  const LoadServiceAddOnsEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

/// Validate promo code
class ValidatePromoCodeEvent extends ServiceEvent {
  final String promoCode;
  final double orderAmount;

  const ValidatePromoCodeEvent({
    required this.promoCode,
    required this.orderAmount,
  });

  @override
  List<Object?> get props => [promoCode, orderAmount];
}

