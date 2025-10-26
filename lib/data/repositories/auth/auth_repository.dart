import '../../../features/auth/models/astrologer_model.dart';

/// Authentication Repository Interface
/// Handles all authentication-related data operations
/// 
/// This abstraction allows us to:
/// - Switch between different data sources (API, local, mock)
/// - Test BLoCs without real API calls
/// - Keep business logic separate from data logic
abstract class AuthRepository {
  /// Check if a phone number already exists in the system
  /// Returns a map with 'exists' boolean and 'message' string
  Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber);

  /// Send OTP to the given phone number
  /// Returns a map with 'success' boolean, 'message' string, and optional 'otpId'
  Future<Map<String, dynamic>> sendOtp(String phoneNumber);

  /// Verify OTP for the given phone number
  /// Returns authenticated astrologer, auth token, and session ID
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? otpId,
  });

  /// Sign up a new astrologer
  /// Returns authenticated astrologer, auth token, and session ID
  Future<Map<String, dynamic>> signup({
    required String phoneNumber,
    required String otp,
    String? otpId,
    required String name,
    required String email,
    required int experience,
    required List<String> specializations,
    required List<String> languages,
    required String bio,
    required String awards,
    required String certificates,
    String? profilePicture,
  });

  /// Get current user profile from API
  Future<AstrologerModel> getProfile();

  /// Refresh authentication token
  /// Returns new token if successful
  Future<String?> refreshToken();

  /// Delete user account permanently
  Future<bool> deleteAccount();

  /// Save authentication data to local storage
  Future<void> saveAuthData({
    required String token,
    required String sessionId,
    required AstrologerModel astrologer,
  });

  /// Get saved authentication token
  Future<String?> getAuthToken();

  /// Get saved session ID
  Future<String?> getSessionId();

  /// Get saved user data
  Future<AstrologerModel?> getSavedUserData();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Clear all authentication data
  Future<void> clearAuthData();
}

