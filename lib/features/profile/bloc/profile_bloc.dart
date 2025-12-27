import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../auth/models/astrologer_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<UpdateSpecializationsEvent>(_onUpdateSpecializations);
    on<UpdateLanguagesEvent>(_onUpdateLanguages);
    on<UpdateRateEvent>(_onUpdateRate);
    on<RequestVerificationEvent>(_onRequestVerification);
    on<GetVerificationStatusEvent>(_onGetVerificationStatus);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    // Smart Loading: If data already exists and not forcing refresh, skip loading
    if (state is ProfileLoadedState && !event.forceRefresh) {
      print('✅ [ProfileBloc] Profile already loaded, skipping API call');
      return; // Keep existing data
    }
    
    // 🚀 PHASE 1: INSTANT LOAD - Show cached data immediately (WhatsApp/Instagram-style)
    try {
      final instantProfile = repository.getInstantData(); // Synchronous, no await!
      
      if (instantProfile != null) {
        // Emit cached data instantly with refreshing flag
        print('⚡ [ProfileBloc] Showing profile from persistent cache (survived restart!)');
        emit(ProfileLoadedState(
          instantProfile,
          isRefreshing: true, // Show subtle refresh indicator
        ));
      } else {
        // Only show full loading spinner if no cache exists
        print('⏳ [ProfileBloc] No cache found, showing loading spinner');
        emit(const ProfileLoading());
      }
    } catch (e) {
      // If instant data fails, show spinner
      print('⚠️ [ProfileBloc] Error loading instant data: $e');
      emit(const ProfileLoading());
    }
    
    // 🔄 PHASE 2: BACKGROUND REFRESH - Fetch fresh data from API
    try {
      final astrologer = await repository.loadProfile();
      print('✅ [ProfileBloc] Profile loaded from API: ${astrologer.name}');
      emit(ProfileLoadedState(
        astrologer,
        isRefreshing: false, // Hide refresh indicator
      ));
    } catch (e) {
      // If refresh fails but we already showed cached data, just hide refresh indicator
      if (state is ProfileLoadedState) {
        final currentState = state as ProfileLoadedState;
        print('⚠️ [ProfileBloc] API refresh failed, keeping cached data');
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        // Only show error if no data was shown
        print('❌ [ProfileBloc] Error loading profile: $e');
        emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    print('\n📝 [ProfileBloc] ========== UPDATE PROFILE STARTED ==========');
    print('   Current time: ${DateTime.now()}');
    print('   Has profileData: ${event.profileData != null}');
    print('   Has astrologer: ${event.astrologer != null}');
    
    // Keep current data visible during update
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      print('   Emitting ProfileUpdating("profile")...');
      emit(ProfileUpdating('profile', currentState.astrologer));
    } else {
      print('   No current profile loaded, emitting ProfileLoading...');
      emit(const ProfileLoading());
    }
    
    try {
      AstrologerModel updatedAstrologer;
      
      // Handle both profileData (Map) and astrologer (Model) updates
      if (event.profileData != null) {
        print('📝 [ProfileBloc] Updating profile with data map');
        print('   Data keys: ${event.profileData!.keys}');
        print('⏳ [ProfileBloc] Calling repository.updateProfileWithData()...');
        updatedAstrologer = await repository.updateProfileWithData(event.profileData!);
      } else {
        print('📝 [ProfileBloc] Updating profile with model');
        print('⏳ [ProfileBloc] Calling repository.updateProfile()...');
        updatedAstrologer = await repository.updateProfile(event.astrologer!);
      }
      
      print('✅ [ProfileBloc] Profile updated successfully!');
      print('   Updated profile name: ${updatedAstrologer.name}');
      print('   Updated profile email: ${updatedAstrologer.email}');
      
      print('📤 [ProfileBloc] Emitting ProfileLoadedState with success message');
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile updated successfully',
      ));
      print('✅ [ProfileBloc] ProfileLoadedState emitted for profile update');
      print('========== UPDATE PROFILE COMPLETED ==========\n');
    } catch (e) {
      print('❌ [ProfileBloc] Error updating profile: $e');
      print('   Stack trace: ${StackTrace.current}');
      print('📤 [ProfileBloc] Emitting ProfileErrorState');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
      print('========== UPDATE PROFILE FAILED ==========\n');
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImageEvent event, Emitter<ProfileState> emit) async {
    print('\n📸 [ProfileBloc] ========== UPLOAD PROFILE IMAGE STARTED ==========');
    print('   Image path: ${event.imagePath}');
    print('   Current time: ${DateTime.now()}');
    
    // Keep current data visible during image upload
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      print('   Emitting ProfileUpdating("image")...');
      emit(ProfileUpdating('image', currentState.astrologer));
    } else {
      print('   No current profile loaded, emitting ProfileLoading...');
      emit(const ProfileLoading());
    }
    
    try {
      print('⏳ [ProfileBloc] Calling repository.uploadProfileImage()...');
      final imageUrl = await repository.uploadProfileImage(event.imagePath);
      print('✅ [ProfileBloc] Image uploaded! URL: $imageUrl');
      
      // Reload profile to get complete astrologer data with new image
      print('⏳ [ProfileBloc] Reloading profile to get updated data...');
      final updatedAstrologer = await repository.loadProfile();
      print('✅ [ProfileBloc] Profile reloaded with new image');
      print('   Profile name: ${updatedAstrologer.name}');
      print('   Profile picture: ${updatedAstrologer.profilePicture}');
      
      print('📤 [ProfileBloc] Emitting ProfileLoadedState with success message');
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile image uploaded successfully',
      ));
      print('✅ [ProfileBloc] ProfileLoadedState emitted for image upload');
      print('========== UPLOAD PROFILE IMAGE COMPLETED ==========\n');
    } catch (e) {
      print('❌ [ProfileBloc] Error uploading image: $e');
      print('   Stack trace: ${StackTrace.current}');
      print('📤 [ProfileBloc] Emitting ProfileErrorState');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
      print('========== UPLOAD PROFILE IMAGE FAILED ==========\n');
    }
  }

  Future<void> _onUpdateSpecializations(UpdateSpecializationsEvent event, Emitter<ProfileState> emit) async {
    // Keep current data visible during update
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      emit(ProfileUpdating('specializations', currentState.astrologer));
    }
    
    try {
      final updatedAstrologer = await repository.updateSpecializations(event.specializations);
      print('✅ [ProfileBloc] Specializations updated');
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Specializations updated successfully',
      ));
    } catch (e) {
      print('❌ [ProfileBloc] Error updating specializations: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateLanguages(UpdateLanguagesEvent event, Emitter<ProfileState> emit) async {
    // Keep current data visible during update
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      emit(ProfileUpdating('languages', currentState.astrologer));
    }
    
    try {
      final updatedAstrologer = await repository.updateLanguages(event.languages);
      print('✅ [ProfileBloc] Languages updated');
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Languages updated successfully',
      ));
    } catch (e) {
      print('❌ [ProfileBloc] Error updating languages: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateRate(UpdateRateEvent event, Emitter<ProfileState> emit) async {
    // Keep current data visible during update
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      emit(ProfileUpdating('rate', currentState.astrologer));
    }
    
    try {
      final updatedAstrologer = await repository.updateRate(event.ratePerMinute);
      print('✅ [ProfileBloc] Rate updated');
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Rate updated successfully',
      ));
    } catch (e) {
      print('❌ [ProfileBloc] Error updating rate: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestVerification(RequestVerificationEvent event, Emitter<ProfileState> emit) async {
    print('\n🔷 [ProfileBloc] ========== REQUEST VERIFICATION STARTED ==========');
    
    // Store current astrologer BEFORE emitting any states
    AstrologerModel? currentAstrologer;
    if (state is ProfileLoadedState) {
      currentAstrologer = (state as ProfileLoadedState).astrologer;
      emit(ProfileUpdating('verification', currentAstrologer));
    } else if (state is ProfileUpdating) {
      currentAstrologer = (state as ProfileUpdating).currentAstrologer;
    } else {
      emit(const ProfileLoading());
    }
    
    try {
      final result = await repository.requestVerification();
      
      if (result['success'] == true) {
        print('✅ [ProfileBloc] Verification requested successfully');
        
        // Reload profile to get updated verification status
        final updatedAstrologer = await repository.loadProfile();
        
        emit(VerificationRequestSuccess(
          result['message'] ?? 'Verification request submitted successfully',
          updatedAstrologer: updatedAstrologer,
        ));
        
        // Then emit loaded state with the updated profile
        emit(ProfileLoadedState(
          updatedAstrologer,
          successMessage: 'Verification request submitted! We\'ll review it within 24-48 hours.',
        ));
      } else {
        // Requirements not met
        print('⚠️ [ProfileBloc] Verification requirements not met');
        emit(VerificationRequirementsNotMet(
          message: result['message'] ?? 'Requirements not met',
          requirements: result['requirements'] ?? {},
          current: result['current'] ?? {},
        ));
        
        // ALWAYS return to loaded state after showing requirements, using stored astrologer
        if (currentAstrologer != null) {
          emit(ProfileLoadedState(currentAstrologer));
        } else {
          // Fallback: reload profile if we somehow lost the astrologer
          final freshProfile = await repository.loadProfile();
          emit(ProfileLoadedState(freshProfile));
        }
      }
      
      print('========== REQUEST VERIFICATION COMPLETED ==========\n');
    } catch (e) {
      print('❌ [ProfileBloc] Error requesting verification: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
      print('========== REQUEST VERIFICATION FAILED ==========\n');
    }
  }

  Future<void> _onGetVerificationStatus(GetVerificationStatusEvent event, Emitter<ProfileState> emit) async {
    print('\n🔷 [ProfileBloc] ========== GET VERIFICATION STATUS STARTED ==========');
    
    try {
      final result = await repository.getVerificationStatus();
      
      if (result['success'] == true) {
        print('✅ [ProfileBloc] Verification status retrieved');
        emit(VerificationStatusLoaded(result['data']));
      } else {
        throw Exception('Failed to get verification status');
      }
      
      print('========== GET VERIFICATION STATUS COMPLETED ==========\n');
    } catch (e) {
      print('❌ [ProfileBloc] Error getting verification status: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
      print('========== GET VERIFICATION STATUS FAILED ==========\n');
    }
  }
}
