import '../models/astrologer_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class PhoneCheckedState extends AuthState {
  final bool exists;
  final String message;
  final String phoneNumber;
  
  PhoneCheckedState({
    required this.exists,
    required this.message,
    required this.phoneNumber,
  });
}

class OtpSentState extends AuthState {
  final String message;
  final String? otpId;
  
  OtpSentState({
    required this.message,
    this.otpId,
  });
}

class AuthSuccessState extends AuthState {
  final AstrologerModel astrologer;
  final String token;
  final String? sessionId;
  
  AuthSuccessState({
    required this.astrologer,
    required this.token,
    this.sessionId,
  });
}

class AuthErrorState extends AuthState {
  final String message;
  
  AuthErrorState(this.message);
}

class AuthLoggedOutState extends AuthState {}

class AuthUnauthenticatedState extends AuthState {}

class AccountDeletedState extends AuthState {
  final String message;
  
  AccountDeletedState({required this.message});
}









