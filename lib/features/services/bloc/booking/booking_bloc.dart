import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import '../../models/booking_model.dart';
import '../../models/delivery_method_enum.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final ServiceRepository repository;
  BookingModel? _currentBooking;

  BookingBloc({required this.repository}) : super(const BookingInitial()) {
    on<InitializeBookingEvent>(_onInitializeBooking);
    on<UpdateDeliveryMethodEvent>(_onUpdateDeliveryMethod);
    on<UpdateTimeSlotEvent>(_onUpdateTimeSlot);
    on<ToggleAddOnEvent>(_onToggleAddOn);
    on<UpdateUserInformationEvent>(_onUpdateUserInformation);
    on<UpdateSpecialInstructionsEvent>(_onUpdateSpecialInstructions);
    on<ApplyPromoCodeEvent>(_onApplyPromoCode);
    on<RemovePromoCodeEvent>(_onRemovePromoCode);
    on<CreateBookingEvent>(_onCreateBooking);
    on<UpdateBookingEvent>(_onUpdateBooking);
    on<ResetBookingEvent>(_onResetBooking);
  }

  void _onInitializeBooking(
    InitializeBookingEvent event,
    Emitter<BookingState> emit,
  ) {
    _currentBooking = BookingModel(
      serviceId: event.serviceId,
      astrologerId: event.astrologerId,
      userId: event.userId,
      deliveryMethod: DeliveryMethod.videoCall, // Default
      timeSlot: TimeSlotModel(
        id: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      ), // Placeholder
      servicePrice: event.servicePrice,
      totalAmount: event.servicePrice,
      createdAt: DateTime.now(),
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: false, // Not valid yet (no time slot)
    ));
  }

  void _onUpdateDeliveryMethod(
    UpdateDeliveryMethodEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    _currentBooking = _currentBooking!.copyWith(
      deliveryMethod: event.deliveryMethod,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onUpdateTimeSlot(
    UpdateTimeSlotEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    _currentBooking = _currentBooking!.copyWith(
      timeSlot: event.timeSlot,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onToggleAddOn(
    ToggleAddOnEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    final currentAddOns = List<AddOnModel>.from(_currentBooking!.selectedAddOns);
    final existingIndex = currentAddOns.indexWhere((a) => a.id == event.addOn.id);

    if (existingIndex >= 0) {
      // Remove add-on
      currentAddOns.removeAt(existingIndex);
    } else {
      // Add add-on
      currentAddOns.add(event.addOn);
    }

    // Recalculate pricing
    final addOnsPrice = currentAddOns.fold<double>(
      0,
      (sum, addon) => sum + addon.price,
    );
    final platformFee = repository.calculatePlatformFee(
      _currentBooking!.servicePrice + addOnsPrice,
    );
    final totalAmount = repository.calculateTotalAmount(
      servicePrice: _currentBooking!.servicePrice,
      addOnsPrice: addOnsPrice,
      platformFee: platformFee,
      discount: _currentBooking!.discount,
    );

    _currentBooking = _currentBooking!.copyWith(
      selectedAddOns: currentAddOns,
      addOnsPrice: addOnsPrice,
      platformFee: platformFee,
      totalAmount: totalAmount,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onUpdateUserInformation(
    UpdateUserInformationEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    _currentBooking = _currentBooking!.copyWith(
      userInformation: event.information,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onUpdateSpecialInstructions(
    UpdateSpecialInstructionsEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    _currentBooking = _currentBooking!.copyWith(
      specialInstructions: event.instructions,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onApplyPromoCode(
    ApplyPromoCodeEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    // Recalculate total with discount
    final totalAmount = repository.calculateTotalAmount(
      servicePrice: _currentBooking!.servicePrice,
      addOnsPrice: _currentBooking!.addOnsPrice,
      platformFee: _currentBooking!.platformFee,
      discount: event.discount,
    );

    _currentBooking = _currentBooking!.copyWith(
      promoCode: event.promoCode,
      discount: event.discount,
      totalAmount: totalAmount,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  void _onRemovePromoCode(
    RemovePromoCodeEvent event,
    Emitter<BookingState> emit,
  ) {
    if (_currentBooking == null) return;

    // Recalculate total without discount
    final totalAmount = repository.calculateTotalAmount(
      servicePrice: _currentBooking!.servicePrice,
      addOnsPrice: _currentBooking!.addOnsPrice,
      platformFee: _currentBooking!.platformFee,
      discount: 0,
    );

    _currentBooking = _currentBooking!.copyWith(
      promoCode: null,
      discount: 0,
      totalAmount: totalAmount,
    );

    emit(BookingInProgress(
      booking: _currentBooking!,
      isValid: _isBookingValid(_currentBooking!),
    ));
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_currentBooking == null) return;

    emit(BookingCreating(_currentBooking!));

    try {
      final booking = await repository.createBooking(_currentBooking!);
      _currentBooking = booking;
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(
        message: 'Failed to create booking: ${e.toString()}',
        booking: _currentBooking,
      ));
    }
  }

  Future<void> _onUpdateBooking(
    UpdateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_currentBooking == null || _currentBooking!.id == null) return;

    try {
      final booking = await repository.updateBooking(_currentBooking!);
      _currentBooking = booking;
      emit(BookingUpdated(booking));
    } catch (e) {
      emit(BookingError(
        message: 'Failed to update booking: ${e.toString()}',
        booking: _currentBooking,
      ));
    }
  }

  void _onResetBooking(
    ResetBookingEvent event,
    Emitter<BookingState> emit,
  ) {
    _currentBooking = null;
    emit(const BookingInitial());
  }

  /// Validate if booking is ready for checkout
  bool _isBookingValid(BookingModel booking) {
    // Must have a valid time slot
    if (booking.timeSlot.id.isEmpty) return false;
    
    // Time slot must be in the future
    if (booking.timeSlot.startTime.isBefore(DateTime.now())) return false;
    
    return true;
  }
}

