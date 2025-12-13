import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../core/services/api_service.dart';
import '../models/astrologer_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:async';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final ApiService _apiService = ApiService(); // Still needed for unauthorized stream
  StreamSubscription<String>? _unauthorizedSubscription;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<CheckPhoneExistsEvent>(_onCheckPhoneExists);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SignupEvent>(_onSignup);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<InitializeAuthEvent>(_onInitializeAuth);
    on<AuthUnauthorizedEvent>(_onUnauthorized);
    
    // Initialize storage service
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    _apiService.initialize();
    add(InitializeAuthEvent());
  }

  Future<void> _onInitializeAuth(InitializeAuthEvent event, Emitter<AuthState> emit) async {
    _unauthorizedSubscription?.cancel();
    _unauthorizedSubscription = _apiService.unauthorizedStream.listen((message) {
      add(AuthUnauthorizedEvent(message));
    });
  }

  Future<void> _onUnauthorized(AuthUnauthorizedEvent event, Emitter<AuthState> emit) async {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║      🔐 AUTH BLOC: UNAUTHORIZED EVENT                ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Reason: ${event.message}');
    print('║ Timestamp: ${DateTime.now()}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    await repository.clearAuthData();
    print('⚠️ [AUTH_BLOC] EMITTING: AuthUnauthenticatedState (from unauthorized event)');
    emit(AuthUnauthenticatedState());
  }

  Future<void> _onCheckPhoneExists(CheckPhoneExistsEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await repository.checkPhoneExists(event.phoneNumber);
      
      emit(PhoneCheckedState(
        exists: result['exists'],
        message: result['message'],
        phoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      print('Check phone exists error: $e');
      emit(AuthErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await repository.sendOtp(event.phoneNumber);
      
      emit(OtpSentState(
        message: result['message'],
        otpId: result['otpId'],
      ));
    } catch (e) {
      print('Send OTP API Error: $e');
      emit(AuthErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await repository.verifyOtp(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
        otpId: event.otpId,
      );
      
      final astrologer = result['astrologer'] as AstrologerModel;
      final token = result['token'] as String;
      final sessionId = result['sessionId'] as String;
      
      print('');
      print('╔═══════════════════════════════════════════════════════╗');
      print('║      ✅ AUTH BLOC: OTP VERIFICATION SUCCESS          ║');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ User: ${astrologer.name}');
      print('║ Phone: ${event.phoneNumber}');
      print('║ Timestamp: ${DateTime.now()}');
      print('╚═══════════════════════════════════════════════════════╝');
      print('');
      print('✅ [AUTH_BLOC] EMITTING: AuthSuccessState (from OTP verification)');
      
      emit(AuthSuccessState(
        astrologer: astrologer,
        token: token,
        sessionId: sessionId,
      ));
    } catch (e) {
      print('Verify OTP API Error: $e');
      emit(AuthErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await repository.signup(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
        otpId: event.otpId,
        name: event.name,
        email: event.email,
        experience: event.experience,
        specializations: event.specializations,
        languages: event.languages,
        bio: event.bio,
        awards: event.awards,
        certificates: event.certificates,
        profilePicture: event.profilePicture.path,
      );
      
      final astrologer = result['astrologer'] as AstrologerModel;
      final token = result['token'] as String;
      final sessionId = result['sessionId'] as String;
      
      print('');
      print('╔═══════════════════════════════════════════════════════╗');
      print('║      ✅ AUTH BLOC: SIGNUP SUCCESS                    ║');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ User: ${astrologer.name}');
      print('║ Phone: ${event.phoneNumber}');
      print('║ Timestamp: ${DateTime.now()}');
      print('╚═══════════════════════════════════════════════════════╝');
      print('');
      print('✅ [AUTH_BLOC] EMITTING: AuthSuccessState (from signup)');
      
      emit(AuthSuccessState(
        astrologer: astrologer,
        token: token,
        sessionId: sessionId,
      ));
    } catch (e) {
      print('Signup API Error: $e');
      emit(AuthErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║      🚪 AUTH BLOC: LOGOUT EVENT                      ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Timestamp: ${DateTime.now()}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    
    try {
      // End any active live streams before logout
      try {
        final userData = await repository.getSavedUserData();
        if (userData != null) {
          final astrologerId = userData.id;
          if (astrologerId.isNotEmpty) {
            print('📺 [AUTH_BLOC] Ending active streams for astrologer: $astrologerId');
            // Call cleanup endpoint to end all active streams
            await _apiService.post('/api/live/cleanup/$astrologerId');
            print('✅ [AUTH_BLOC] Active streams ended');
          }
        }
      } catch (e) {
        print('⚠️ [AUTH_BLOC] Failed to end active streams on logout: $e');
        // Continue with logout even if this fails
      }
      
      await repository.clearAuthData();
      add(InitializeAuthEvent());
      
      print('✅ [AUTH_BLOC] EMITTING: AuthLoggedOutState');
      emit(AuthLoggedOutState());
    } catch (e) {
      print('❌ [AUTH_BLOC] Logout error: $e');
      await repository.clearAuthData();
      add(InitializeAuthEvent());
      print('✅ [AUTH_BLOC] EMITTING: AuthLoggedOutState (after error)');
      emit(AuthLoggedOutState());
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║      🔍 AUTH BLOC: CHECKING AUTH STATUS              ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Timestamp: ${DateTime.now()}');
    print('╚═══════════════════════════════════════════════════════╝');
    print('');
    
    try {
      final isLoggedIn = await repository.isLoggedIn();
      final token = await repository.getAuthToken();
      final sessionId = await repository.getSessionId();
      final savedUser = await repository.getSavedUserData();
      
      print('');
      print('╔═══════════════════════════════════════════════════════╗');
      print('║        AUTH STATUS CHECK RESULTS                      ║');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ isLoggedIn: $isLoggedIn');
      print('║ hasToken: ${token != null}');
      print('║ hasUserData: ${savedUser != null}');
      print('║ hasSessionId: ${sessionId != null}');
      print('╚═══════════════════════════════════════════════════════╝');
      print('');
      
      // If no valid auth data, clear everything and go to login
      if (!isLoggedIn || token == null || savedUser == null || sessionId == null) {
        print('⚠️ [AUTH_BLOC] No valid auth data found, clearing all data');
        await repository.clearAuthData();
        print('❌ [AUTH_BLOC] EMITTING: AuthUnauthenticatedState (no valid auth data)');
        emit(AuthUnauthenticatedState());
        return;
      }
      
      // Set auth token for API calls
      _apiService.setAuthToken(token);
      
      // Validate token with server
      try {
        print('🔐 [AUTH_BLOC] Validating token with server...');
        final astrologer = await repository.getProfile();
        
        print('✅ [AUTH_BLOC] Token valid, user authenticated');
        print('👤 [AUTH_BLOC] User: ${astrologer.name}');
        print('✅ [AUTH_BLOC] EMITTING: AuthSuccessState (token validated)');
        emit(AuthSuccessState(
          astrologer: astrologer,
          token: token,
          sessionId: sessionId,
        ));
      } catch (e) {
        print('❌ [AUTH_BLOC] Token validation failed: $e');
        await repository.clearAuthData();
        print('❌ [AUTH_BLOC] EMITTING: AuthUnauthenticatedState (token validation failed)');
        emit(AuthUnauthenticatedState());
      }
    } catch (e) {
      print('❌ [AUTH_BLOC] Error checking auth status: $e');
      print('Stack trace: ${StackTrace.current}');
      print('❌ [AUTH_BLOC] EMITTING: AuthUnauthenticatedState (error occurred)');
      emit(AuthUnauthenticatedState());
    }
  }


  Future<void> _onRefreshToken(RefreshTokenEvent event, Emitter<AuthState> emit) async {
    try {
      final newToken = await repository.refreshToken();
      if (newToken != null) {
        _apiService.setAuthToken(newToken);
      } else {
        // If refresh fails, logout user
        add(LogoutEvent());
      }
    } catch (e) {
      // If refresh fails, logout user
      add(LogoutEvent());
    }
  }

  Future<void> _onDeleteProfile(DeleteProfileEvent event, Emitter<AuthState> emit) async {
    try {
      await repository.clearAuthData();
      emit(AuthLoggedOutState());
    } catch (e) {
      await repository.clearAuthData();
      emit(AuthLoggedOutState());
    }
  }

  Future<void> _onDeleteAccount(DeleteAccountEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      print('DeleteAccount: Starting account deletion...');
      
      final success = await repository.deleteAccount();
      
      if (success) {
        print('DeleteAccount: Account deleted successfully');
        emit(AccountDeletedState(message: 'Account has been permanently deleted'));
      } else {
        emit(AccountDeletedState(message: 'Account deletion requested. You have been logged out.'));
      }
    } catch (e) {
      print('Delete account API Error: $e');
      emit(AccountDeletedState(message: 'Account deletion requested. You have been logged out.'));
    }
  }

  @override
  Future<void> close() {
    _unauthorizedSubscription?.cancel();
    return super.close();
  }
}
