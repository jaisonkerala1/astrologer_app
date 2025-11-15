import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'service_event.dart';
import 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final ServiceRepository repository;

  ServiceBloc({required this.repository}) : super(const ServiceInitial()) {
    on<LoadAstrologerServicesEvent>(_onLoadAstrologerServices);
    on<LoadServiceDetailEvent>(_onLoadServiceDetail);
    on<SearchServicesEvent>(_onSearchServices);
    on<LoadAllServicesEvent>(_onLoadAllServices);
    on<LoadAvailableSlotsEvent>(_onLoadAvailableSlots);
    on<LoadServiceAddOnsEvent>(_onLoadServiceAddOns);
    on<ValidatePromoCodeEvent>(_onValidatePromoCode);
  }

  Future<void> _onLoadAstrologerServices(
    LoadAstrologerServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final services = await repository.getServicesByAstrologer(event.astrologerId);
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError('Failed to load services: ${e.toString()}'));
    }
  }

  Future<void> _onLoadServiceDetail(
    LoadServiceDetailEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final service = await repository.getServiceById(event.serviceId);
      emit(ServiceDetailLoaded(service));
    } catch (e) {
      emit(ServiceError('Failed to load service: ${e.toString()}'));
    }
  }

  Future<void> _onSearchServices(
    SearchServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final services = await repository.searchServices(event.query);
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError('Failed to search services: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAllServices(
    LoadAllServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final services = await repository.getAllServices();
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError('Failed to load services: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAvailableSlots(
    LoadAvailableSlotsEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final slots = await repository.getAvailableSlots(
        astrologerId: event.astrologerId,
        date: event.date,
        durationInMinutes: event.durationInMinutes,
      );
      emit(ServiceSlotsLoaded(slots: slots, date: event.date));
    } catch (e) {
      emit(ServiceError('Failed to load time slots: ${e.toString()}'));
    }
  }

  Future<void> _onLoadServiceAddOns(
    LoadServiceAddOnsEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    try {
      final addOns = await repository.getServiceAddOns(event.serviceId);
      emit(ServiceAddOnsLoaded(addOns));
    } catch (e) {
      emit(ServiceError('Failed to load add-ons: ${e.toString()}'));
    }
  }

  Future<void> _onValidatePromoCode(
    ValidatePromoCodeEvent event,
    Emitter<ServiceState> emit,
  ) async {
    try {
      final result = await repository.validatePromoCode(
        promoCode: event.promoCode,
        orderAmount: event.orderAmount,
      );
      
      emit(PromoCodeValidated(
        isValid: result['valid'] as bool,
        discount: result['discount'] as double,
        message: result['description'] as String,
      ));
    } catch (e) {
      emit(const PromoCodeValidated(
        isValid: false,
        discount: 0,
        message: 'Failed to validate promo code',
      ));
    }
  }
}

