import 'package:equatable/equatable.dart';
import '../models/astrologer_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class PhoneCheckedState extends AuthState {
  final bool exists;
  final String message;
  final String phoneNumber;
  
  const PhoneCheckedState({
    required this.exists,
    required this.message,
    required this.phoneNumber,
  });
  
  @override
  List<Object?> get props => [exists, message, phoneNumber];
}

class OtpSentState extends AuthState {
  final String message;
  final String? otpId;
  
  const OtpSentState({
    required this.message,
    this.otpId,
  });
  
  @override
  List<Object?> get props => [message, otpId];
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
  
  @override
  List<Object?> get props => [astrologer, token, sessionId];
}

class AuthErrorState extends AuthState {
  final String message;
  
  const AuthErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthLoggedOutState extends AuthState {
  const AuthLoggedOutState();
}

class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}

class AccountDeletedState extends AuthState {
  final String message;
  
  const AccountDeletedState({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class AuthWaitingForApproval extends AuthState {
  final AstrologerModel astrologer;
  final String token;
  final String? sessionId;
  
  const AuthWaitingForApproval({
    required this.astrologer,
    required this.token,
    this.sessionId,
  });
  
  @override
  List<Object?> get props => [astrologer, token, sessionId];
}

class AuthSuspendedState extends AuthState {
  final String reason;
  final DateTime? suspendedAt;
  
  const AuthSuspendedState({
    required this.reason,
    this.suspendedAt,
  });
  
  @override
  List<Object?> get props => [reason, suspendedAt];
}









