import 'package:equatable/equatable.dart';
import '../../models/booking_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state (no booking in progress)
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Booking in progress (user is filling details)
class BookingInProgress extends BookingState {
  final BookingModel booking;
  final bool isValid; // Can proceed to checkout?

  const BookingInProgress({
    required this.booking,
    this.isValid = false,
  });

  @override
  List<Object?> get props => [booking, isValid];
}

/// Creating booking (saving to backend)
class BookingCreating extends BookingState {
  final BookingModel booking;

  const BookingCreating(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Booking created successfully
class BookingCreated extends BookingState {
  final BookingModel booking;

  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Booking updated successfully
class BookingUpdated extends BookingState {
  final BookingModel booking;

  const BookingUpdated(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Booking error
class BookingError extends BookingState {
  final String message;
  final BookingModel? booking; // Keep current booking on error

  const BookingError({
    required this.message,
    this.booking,
  });

  @override
  List<Object?> get props => [message, booking];
}

