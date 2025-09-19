import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/astrologer_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthBloc() : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SignupEvent>(_onSignup);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<DeleteAccountEvent>(_onDeleteAccount);
    
    // Initialize storage service
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storageService.initialize();
    _apiService.initialize();
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      // Try API call first
      final response = await _apiService.post(
        ApiConstants.sendOtp,
        data: {'phone': event.phoneNumber.replaceAll(' ', '')},
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success) {
          emit(OtpSentState(
            message: authResponse.message,
            otpId: authResponse.otpId,
          ));
        } else {
          emit(AuthErrorState(authResponse.message));
        }
      } else {
        emit(AuthErrorState('Failed to send OTP. Please try again.'));
      }
    } catch (e) {
      print('Send OTP API Error: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('Connection refused')) {
        emit(AuthErrorState('Cannot connect to server. Make sure backend is running on http://192.168.29.99:7566'));
      } else if (e.toString().contains('timeout')) {
        emit(AuthErrorState('Request timeout. Please check your internet connection.'));
      } else {
        emit(AuthErrorState('Failed to send OTP: ${e.toString()}'));
      }
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      // Try API call first
      final response = await _apiService.post(
        ApiConstants.verifyOtp,
        data: {
          'phone': event.phoneNumber.replaceAll(' ', ''),
          'otp': event.otp,
          if (event.otpId != null) 'otpId': event.otpId,
        },
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success && authResponse.astrologer != null && authResponse.token != null) {
          // Save auth data
          await _storageService.setAuthToken(authResponse.token!);
          await _storageService.setUserData(jsonEncode(authResponse.astrologer!.toJson()));
          await _storageService.setIsLoggedIn(true);
          await _storageService.setPhoneNumber(event.phoneNumber.replaceAll(' ', ''));
          
          // Set auth token for API calls
          _apiService.setAuthToken(authResponse.token!);
          
          emit(AuthSuccessState(
            astrologer: authResponse.astrologer!,
            token: authResponse.token!,
          ));
        } else {
          emit(AuthErrorState(authResponse.message));
        }
      } else if (response.statusCode == 404) {
        // Handle account not found - user needs to sign up first
        final authResponse = AuthResponseModel.fromJson(response.data);
        emit(AuthErrorState(authResponse.message));
      } else {
        emit(AuthErrorState('Failed to verify OTP. Please try again.'));
      }
    } catch (e) {
      print('Verify OTP API Error: $e');
      emit(AuthErrorState('Failed to verify OTP. Please check your internet connection and try again.'));
    }
  }

  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.post(
        ApiConstants.signup,
        data: {
          'phone': event.phoneNumber.replaceAll(' ', ''),
          'otp': event.otp,
          if (event.otpId != null) 'otpId': event.otpId,
          'name': event.name,
          'email': event.email,
          'experience': event.experience,
          'specializations': event.specializations,
          'languages': event.languages,
        },
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success && authResponse.astrologer != null && authResponse.token != null) {
          // Save auth data
          await _storageService.setAuthToken(authResponse.token!);
          await _storageService.setUserData(jsonEncode(authResponse.astrologer!.toJson()));
          await _storageService.setIsLoggedIn(true);
          await _storageService.setPhoneNumber(event.phoneNumber.replaceAll(' ', ''));
          
          // Set auth token for API calls
          _apiService.setAuthToken(authResponse.token!);
          
          emit(AuthSuccessState(
            astrologer: authResponse.astrologer!,
            token: authResponse.token!,
          ));
        } else {
          emit(AuthErrorState(authResponse.message));
        }
      } else {
        emit(AuthErrorState('Failed to create account. Please try again.'));
      }
    } catch (e) {
      print('Signup API Error: $e');
      if (e.toString().contains('already exists')) {
        emit(AuthErrorState('Account with this phone number already exists. Please login instead.'));
      } else {
        emit(AuthErrorState('Failed to create account. Please check your internet connection and try again.'));
      }
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      // Clear local storage
      await _storageService.clearAuthData();
      
      // Clear API token
      _apiService.clearAuthToken();
      
      emit(AuthLoggedOutState());
    } catch (e) {
      // Even if there's an error, we should still log out locally
      await _storageService.clearAuthData();
      _apiService.clearAuthToken();
      emit(AuthLoggedOutState());
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    print('AuthBloc: Checking auth status...');
    try {
      final isLoggedIn = await _storageService.getIsLoggedIn();
      final token = await _storageService.getAuthToken();
      final userData = await _storageService.getUserData();
      
      print('AuthBloc: isLoggedIn=$isLoggedIn, hasToken=${token != null}, hasUserData=${userData != null}');
      
      if (isLoggedIn == true && token != null && userData != null) {
        // Set auth token for API calls
        _apiService.setAuthToken(token);
        
        // Parse user data from storage
        try {
          final userDataMap = jsonDecode(userData);
          final astrologer = AstrologerModel.fromJson(userDataMap);
          
          print('AuthBloc: Emitting AuthSuccessState');
          emit(AuthSuccessState(
            astrologer: astrologer,
            token: token,
          ));
        } catch (e) {
          print('AuthBloc: Error parsing user data: $e');
          // If parsing fails, emit unauthenticated state
          emit(AuthUnauthenticatedState());
        }
      } else {
        print('AuthBloc: User not authenticated, emitting AuthUnauthenticatedState');
        emit(AuthUnauthenticatedState());
      }
    } catch (e) {
      print('AuthBloc: Error checking auth status: $e');
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onRefreshToken(RefreshTokenEvent event, Emitter<AuthState> emit) async {
    try {
      final response = await _apiService.post(ApiConstants.refreshToken);
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success && authResponse.token != null) {
          await _storageService.setAuthToken(authResponse.token!);
          _apiService.setAuthToken(authResponse.token!);
        }
      }
    } catch (e) {
      // If refresh fails, logout user
      add(LogoutEvent());
    }
  }

  Future<void> _onDeleteProfile(DeleteProfileEvent event, Emitter<AuthState> emit) async {
    try {
      // Clear local storage
      await _storageService.clearAuthData();
      
      // Clear API token
      _apiService.clearAuthToken();
      
      emit(AuthLoggedOutState());
    } catch (e) {
      // Even if there's an error, we should still clear local data
      await _storageService.clearAuthData();
      _apiService.clearAuthToken();
      emit(AuthLoggedOutState());
    }
  }

  Future<void> _onDeleteAccount(DeleteAccountEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      print('DeleteAccount: Starting account deletion...');
      
      // Get current auth token
      final token = await _storageService.getAuthToken();
      print('DeleteAccount: Auth token: ${token != null ? "Present" : "Missing"}');
      
      if (token == null) {
        emit(AuthErrorState('You must be logged in to delete your account.'));
        return;
      }
      
      // Set auth token for API calls
      _apiService.setAuthToken(token);
      
      // Call the delete account API
      print('DeleteAccount: Calling API endpoint: ${ApiConstants.deleteAccount}');
      final response = await _apiService.delete(ApiConstants.deleteAccount);
      print('DeleteAccount: API response status: ${response.statusCode}');
      print('DeleteAccount: API response data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Clear local storage
        await _storageService.clearAuthData();
        
        // Clear API token
        _apiService.clearAuthToken();
        
        print('DeleteAccount: Account deleted successfully');
        emit(AccountDeletedState(message: 'Account has been permanently deleted'));
      } else {
        print('DeleteAccount: API returned error status: ${response.statusCode}');
        emit(AuthErrorState('Failed to delete account. Please try again.'));
      }
    } catch (e) {
      print('Delete account API Error: $e');
      emit(AuthErrorState('Failed to delete account. Please check your internet connection and try again.'));
    }
  }
}
