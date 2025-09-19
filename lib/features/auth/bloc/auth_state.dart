import '../models/astrologer_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

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
  
  AuthSuccessState({
    required this.astrologer,
    required this.token,
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









