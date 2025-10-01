import 'dart:io';

abstract class AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  
  SendOtpEvent(this.phoneNumber);
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  final String? otpId;
  
  VerifyOtpEvent({
    required this.phoneNumber,
    required this.otp,
    this.otpId,
  });
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class SignupEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  final String? otpId;
  final String name;
  final String email;
  final int experience;
  final List<String> specializations;
  final List<String> languages;
  final String bio;
  final String awards;
  final String certificates;
  final File profilePicture;
  
  SignupEvent({
    required this.phoneNumber,
    required this.otp,
    this.otpId,
    required this.name,
    required this.email,
    required this.experience,
    required this.specializations,
    required this.languages,
    required this.bio,
    required this.awards,
    required this.certificates,
    required this.profilePicture,
  });
}

class RefreshTokenEvent extends AuthEvent {}

class DeleteProfileEvent extends AuthEvent {}

class DeleteAccountEvent extends AuthEvent {}

class AuthUnauthorizedEvent extends AuthEvent {
  final String message;

  AuthUnauthorizedEvent(this.message);
}

class InitializeAuthEvent extends AuthEvent {}









