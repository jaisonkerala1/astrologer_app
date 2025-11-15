import 'package:equatable/equatable.dart';
import '../../models/booking_model.dart';
import '../../models/delivery_method_enum.dart';
import '../../models/time_slot_model.dart';
import '../../models/add_on_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize a new booking
class InitializeBookingEvent extends BookingEvent {
  final String serviceId;
  final String astrologerId;
  final String userId;
  final double servicePrice;

  const InitializeBookingEvent({
    required this.serviceId,
    required this.astrologerId,
    required this.userId,
    required this.servicePrice,
  });

  @override
  List<Object?> get props => [serviceId, astrologerId, userId, servicePrice];
}

/// Update delivery method
class UpdateDeliveryMethodEvent extends BookingEvent {
  final DeliveryMethod deliveryMethod;

  const UpdateDeliveryMethodEvent(this.deliveryMethod);

  @override
  List<Object?> get props => [deliveryMethod];
}

/// Update time slot
class UpdateTimeSlotEvent extends BookingEvent {
  final TimeSlotModel timeSlot;

  const UpdateTimeSlotEvent(this.timeSlot);

  @override
  List<Object?> get props => [timeSlot];
}

/// Toggle add-on selection
class ToggleAddOnEvent extends BookingEvent {
  final AddOnModel addOn;

  const ToggleAddOnEvent(this.addOn);

  @override
  List<Object?> get props => [addOn];
}

/// Update user information
class UpdateUserInformationEvent extends BookingEvent {
  final Map<String, dynamic> information;

  const UpdateUserInformationEvent(this.information);

  @override
  List<Object?> get props => [information];
}

/// Update special instructions
class UpdateSpecialInstructionsEvent extends BookingEvent {
  final String instructions;

  const UpdateSpecialInstructionsEvent(this.instructions);

  @override
  List<Object?> get props => [instructions];
}

/// Apply promo code
class ApplyPromoCodeEvent extends BookingEvent {
  final String promoCode;
  final double discount;

  const ApplyPromoCodeEvent({
    required this.promoCode,
    required this.discount,
  });

  @override
  List<Object?> get props => [promoCode, discount];
}

/// Remove promo code
class RemovePromoCodeEvent extends BookingEvent {
  const RemovePromoCodeEvent();
}

/// Create booking (save to backend)
class CreateBookingEvent extends BookingEvent {
  const CreateBookingEvent();
}

/// Update existing booking
class UpdateBookingEvent extends BookingEvent {
  const UpdateBookingEvent();
}

/// Reset booking state
class ResetBookingEvent extends BookingEvent {
  const ResetBookingEvent();
}

