import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/auth/models/astrologer_model.dart';
import '../../../features/auth/models/auth_response_model.dart';
import '../base_repository.dart';
import 'auth_repository.dart';

/// Custom exception for suspended accounts
class SuspendedAccountException implements Exception {
  final String reason;
  final String? suspendedAt;
  
  SuspendedAccountException({
    required this.reason,
    this.suspendedAt,
  });
  
  @override
  String toString() => reason;
}

/// Implementation of AuthRepository
/// Handles authentication data operations using ApiService and StorageService
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final ApiService apiService;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final response = await apiService.post(
        ApiConstants.checkPhone,
        data: {'phone': phoneNumber.trim()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'exists': data['exists'] ?? false,
          'message': data['message'] ?? '',
        };
      } else {
        throw Exception('Failed to check phone number');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await apiService.post(
        ApiConstants.sendOtp,
        data: {'phone': phoneNumber.trim()},
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success) {
          return {
            'success': true,
            'message': authResponse.message,
            'otpId': authResponse.otpId,
          };
        } else {
          throw Exception(authResponse.message);
        }
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      // Check if it's a suspended account error (403)
      if (e is DioException && e.response?.statusCode == 403) {
        final reason = e.response?.data['reason'] ?? 'Your account has been suspended';
        final suspendedAt = e.response?.data['suspendedAt'];
        throw SuspendedAccountException(reason: reason, suspendedAt: suspendedAt);
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? otpId,
  }) async {
    try {
      final response = await apiService.post(
        ApiConstants.verifyOtp,
        data: {
          'phone': phoneNumber.trim(),
          'otp': otp,
          if (otpId != null) 'otpId': otpId,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        
        if (authResponse.success && 
            authResponse.astrologer != null && 
            authResponse.token != null) {
          
          final astrologer = authResponse.astrologer!;
          final token = authResponse.token!;
          final sessionId = authResponse.sessionId ?? astrologer.sessionId;

          // Save auth data to local storage
          await saveAuthData(
            token: token,
            sessionId: sessionId,
            astrologer: astrologer,
          );

          // Set token for API service
          apiService.setAuthToken(token);

          return {
            'success': true,
            'astrologer': astrologer,
            'token': token,
            'sessionId': sessionId,
          };
        } else {
          throw Exception(authResponse.message);
        }
      } else if (response.statusCode == 404) {
        throw Exception('Account not found. Please sign up first.');
      } else {
        throw Exception('Failed to verify OTP');
      }
    } catch (e) {
      // Check if it's a suspended account error (403)
      if (e is DioException && e.response?.statusCode == 403) {
        final reason = e.response?.data['reason'] ?? 'Your account has been suspended';
        final suspendedAt = e.response?.data['suspendedAt'];
        throw SuspendedAccountException(reason: reason, suspendedAt: suspendedAt);
      }
      if (e.toString().contains('404')) {
        throw Exception('Account not found. Please sign up first.');
      }
      throw Exception(handleError(e));
    }
  }

  @override
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
  }) async {
    try {
      final response = await apiService.postMultipart(
        ApiConstants.signup,
        data: {
          'phone': phoneNumber.trim(),
          'otp': otp,
          if (otpId != null) 'otpId': otpId,
          'name': name,
          'email': email,
          'experience': experience,
          'specializations': specializations,
          'languages': languages,
          'bio': bio,
          'awards': awards,
          'certificates': certificates,
        },
        files: {
          if (profilePicture != null) 'profilePicture': File(profilePicture),
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        
        if (authResponse.success && 
            authResponse.astrologer != null && 
            authResponse.token != null) {
          
          final astrologer = authResponse.astrologer!;
          final token = authResponse.token!;
          final sessionId = authResponse.sessionId ?? astrologer.sessionId;

          // Save auth data to local storage
          await saveAuthData(
            token: token,
            sessionId: sessionId,
            astrologer: astrologer,
          );

          // Set token for API service
          apiService.setAuthToken(token);

          return {
            'success': true,
            'astrologer': astrologer,
            'token': token,
            'sessionId': sessionId,
          };
        } else {
          throw Exception(authResponse.message);
        }
      } else {
        throw Exception('Failed to create account');
      }
    } catch (e) {
      if (e.toString().contains('already exists')) {
        throw Exception('Account with this phone number already exists. Please login instead.');
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> getProfile() async {
    try {
      final response = await apiService.get(ApiConstants.profile);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final serverUserData = response.data['data'];
        return AstrologerModel.fromJson(serverUserData);
      } else if (response.statusCode == 403) {
        // Account suspended - throw SuspendedAccountException
        final reason = response.data['reason'] ?? 'Your account has been suspended';
        final suspendedAt = response.data['suspendedAt'];
        throw SuspendedAccountException(reason: reason, suspendedAt: suspendedAt);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      // Re-throw SuspendedAccountException as-is
      if (e is SuspendedAccountException) {
        rethrow;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<String?> refreshToken() async {
    try {
      final response = await apiService.post(ApiConstants.refreshToken);

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        if (authResponse.success && authResponse.token != null) {
          // Save new token
          await storageService.setAuthToken(authResponse.token!);
          apiService.setAuthToken(authResponse.token!);
          return authResponse.token;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteAccount() async {
    try {
      final response = await apiService.delete(ApiConstants.deleteAccount);
      
      // Always clear local data regardless of API response
      await clearAuthData();
      
      return response.statusCode == 200;
    } catch (e) {
      // Even if API call fails, clear local data
      await clearAuthData();
      return true; // Return true since user is logged out
    }
  }

  @override
  Future<void> saveAuthData({
    required String token,
    required String? sessionId,
    required AstrologerModel astrologer,
  }) async {
    try {
      // Save token
      await storageService.setAuthToken(token);
      
      // Save session ID
      if (sessionId != null) {
        await storageService.setSessionId(sessionId);
      }
      
      // Save user data
      final userData = astrologer.toJson();
      final mutableData = Map<String, dynamic>.from(userData);
      final idValue = mutableData['id'] ?? mutableData['_id'];
      if (idValue != null) {
        mutableData['id'] = idValue;
        mutableData['_id'] = idValue;
      }
      await storageService.setUserData(jsonEncode(mutableData));
      
      // Set logged in flag
      await storageService.setIsLoggedIn(true);
      
      // Save phone number
      await storageService.setPhoneNumber(astrologer.phone);
    } catch (e) {
      print('Error saving auth data: $e');
      throw Exception('Failed to save authentication data');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    return await storageService.getAuthToken();
  }

  @override
  Future<String?> getSessionId() async {
    return await storageService.getSessionId();
  }

  @override
  Future<AstrologerModel?> getSavedUserData() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        final Map<String, dynamic> data = jsonDecode(userData);
        return AstrologerModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting saved user data: $e');
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final loggedIn = await storageService.getIsLoggedIn();
    return loggedIn ?? false;
  }

  @override
  Future<void> clearAuthData() async {
    await storageService.clearAuthData();
    apiService.clearAuthToken();
  }
}

