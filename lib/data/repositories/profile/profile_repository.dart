import '../../../features/auth/models/astrologer_model.dart';

/// Profile Repository Interface
/// Handles all profile-related data operations
/// 
/// This abstraction allows us to:
/// - Switch between different data sources (API, cache, mock)
/// - Test ProfileBloc without real API calls
/// - Keep business logic separate from data logic
abstract class ProfileRepository {
  /// Get instant data from persistent cache (WhatsApp/Instagram-style)
  /// Returns cached profile immediately (synchronously) or null
  AstrologerModel? getInstantData();
  
  /// Load astrologer profile from API
  Future<AstrologerModel> loadProfile();

  /// Update astrologer profile
  Future<AstrologerModel> updateProfile(AstrologerModel astrologer);

  /// Update astrologer profile with raw data (Map)
  Future<AstrologerModel> updateProfileWithData(Map<String, dynamic> profileData);

  /// Upload profile picture
  /// Returns the uploaded image URL
  Future<String> uploadProfileImage(String imagePath);

  /// Update specializations
  Future<AstrologerModel> updateSpecializations(List<String> specializations);

  /// Update languages
  Future<AstrologerModel> updateLanguages(List<String> languages);

  /// Update rate per minute
  Future<AstrologerModel> updateRate(double ratePerMinute);

  /// Get cached profile (for offline access)
  Future<AstrologerModel?> getCachedProfile();

  /// Cache profile for offline access
  Future<void> cacheProfile(AstrologerModel astrologer);

  /// Clear profile cache
  Future<void> clearCache();
  
  /// Request verification badge
  Future<Map<String, dynamic>> requestVerification();
  
  /// Get verification status
  Future<Map<String, dynamic>> getVerificationStatus();
}


