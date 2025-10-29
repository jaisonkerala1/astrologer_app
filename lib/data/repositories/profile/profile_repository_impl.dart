import 'dart:convert';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/auth/models/astrologer_model.dart';
import '../base_repository.dart';
import 'profile_repository.dart';

/// Implementation of ProfileRepository
/// Handles profile data operations using ApiService and StorageService
class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ApiService apiService;
  final StorageService storageService;

  // In-memory cache for instant access
  AstrologerModel? _cachedProfile;

  ProfileRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // INSTANT DATA (Instagram/WhatsApp-style instant load)
  // ============================================================================

  @override
  AstrologerModel? getInstantData() {
    // 1. Check in-memory cache first (fastest)
    if (_cachedProfile != null) {
      print('⚡ [ProfileRepo] Returning profile from memory cache');
      return _cachedProfile;
    }

    // 2. Try to load from persistent storage (still fast, survives restart)
    try {
      final cachedData = storageService.getStringSync('profile_cache');
      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        _cachedProfile = AstrologerModel.fromJson(json);
        print('⚡ [ProfileRepo] Loaded profile from persistent cache (survived restart!)');
        return _cachedProfile;
      }
    } catch (e) {
      print('⚠️ [ProfileRepo] Error loading from persistent cache: $e');
    }

    print('ℹ️ [ProfileRepo] No cached profile available');
    return null;
  }

  // ============================================================================
  // LOAD PROFILE (with persistent caching)
  // ============================================================================

  @override
  Future<AstrologerModel> loadProfile() async {
    try {
      final response = await apiService.get(ApiConstants.profile);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final astrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Cache in memory AND persist to disk
        _cachedProfile = astrologer;
        await cacheProfile(astrologer);
        print('💾 [ProfileRepo] Profile saved to memory + persistent cache');
        
        return astrologer;
      } else {
        throw Exception('Failed to load profile: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Try to return cached data if API fails
      final cachedProfile = await getCachedProfile();
      if (cachedProfile != null) {
        print('ProfileRepository: Using cached profile due to error: $e');
        return cachedProfile;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> updateProfile(AstrologerModel astrologer) async {
    try {
      final response = await apiService.put(
        ApiConstants.profile,
        data: astrologer.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Update cache and local storage
        await cacheProfile(updatedAstrologer);
        await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
        
        return updatedAstrologer;
      } else {
        throw Exception('Failed to update profile: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> updateProfileWithData(Map<String, dynamic> profileData) async {
    try {
      print('📝 [ProfileRepositoryImpl] Updating profile with data: ${profileData.keys}');
      
      final response = await apiService.put(
        ApiConstants.updateProfile,
        data: profileData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Update cache and local storage
        await cacheProfile(updatedAstrologer);
        await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
        
        print('✅ [ProfileRepositoryImpl] Profile updated successfully: ${updatedAstrologer.name}');
        return updatedAstrologer;
      } else {
        throw Exception('Failed to update profile: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ [ProfileRepositoryImpl] Error updating profile: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<String> uploadProfileImage(String imagePath) async {
    try {
      print('📸 [ProfileRepositoryImpl] Uploading image: $imagePath');
      final response = await apiService.postMultipart(
        ApiConstants.uploadProfileImage,
        files: {
          'profilePicture': File(imagePath),
        },
      );

      print('📸 [ProfileRepositoryImpl] Upload response status: ${response.statusCode}');
      print('📸 [ProfileRepositoryImpl] Upload response success: ${response.data['success']}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // The API returns the full user object with 'profilePicture', not 'imageUrl'
        final profilePicture = response.data['data']['profilePicture'] as String?;
        
        if (profilePicture == null) {
          print('⚠️ [ProfileRepositoryImpl] No profilePicture in response, trying imageUrl...');
          final imageUrl = response.data['data']['imageUrl'] as String?;
          if (imageUrl != null) {
            print('✅ [ProfileRepositoryImpl] Image uploaded (imageUrl): $imageUrl');
            return imageUrl;
          }
          throw Exception('Image uploaded but no URL returned from server');
        }
        
        print('✅ [ProfileRepositoryImpl] Image uploaded (profilePicture): $profilePicture');
        
        // Also cache the updated profile since API returns full user object
        try {
          final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
          await cacheProfile(updatedAstrologer);
          await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
          print('✅ [ProfileRepositoryImpl] Cached updated profile with new image');
        } catch (e) {
          print('⚠️ [ProfileRepositoryImpl] Could not cache profile: $e');
          // Don't fail the upload, just log the warning
        }
        
        return profilePicture;
      } else {
        throw Exception('Failed to upload image: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ [ProfileRepositoryImpl] Upload error: $e');
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> updateSpecializations(List<String> specializations) async {
    try {
      final response = await apiService.patch(
        ApiConstants.updateSpecializations,
        data: {'specializations': specializations},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Update cache
        await cacheProfile(updatedAstrologer);
        await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
        
        return updatedAstrologer;
      } else {
        throw Exception('Failed to update specializations: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> updateLanguages(List<String> languages) async {
    try {
      final response = await apiService.patch(
        ApiConstants.updateLanguages,
        data: {'languages': languages},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Update cache
        await cacheProfile(updatedAstrologer);
        await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
        
        return updatedAstrologer;
      } else {
        throw Exception('Failed to update languages: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel> updateRate(double ratePerMinute) async {
    try {
      final response = await apiService.patch(
        ApiConstants.updateRate,
        data: {'ratePerMinute': ratePerMinute},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedAstrologer = AstrologerModel.fromJson(response.data['data']);
        
        // Update cache
        await cacheProfile(updatedAstrologer);
        await storageService.setUserData(jsonEncode(updatedAstrologer.toJson()));
        
        return updatedAstrologer;
      } else {
        throw Exception('Failed to update rate: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<AstrologerModel?> getCachedProfile() async {
    try {
      final cachedData = await storageService.getString('profile_cache');
      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        return AstrologerModel.fromJson(json);
      }
      
      // Fallback to user data from storage
      final userData = await storageService.getUserData();
      if (userData != null) {
        final json = jsonDecode(userData);
        return AstrologerModel.fromJson(json);
      }
      
      return null;
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }

  @override
  Future<void> cacheProfile(AstrologerModel astrologer) async {
    try {
      await storageService.setString('profile_cache', jsonEncode(astrologer.toJson()));
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('profile_cache');
    } catch (e) {
      print('Error clearing profile cache: $e');
    }
  }
}

