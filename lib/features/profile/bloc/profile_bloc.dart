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
    // Keep current data visible during update
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      emit(ProfileUpdating('profile', currentState.astrologer));
    } else {
      emit(const ProfileLoading());
    }
    
    try {
      AstrologerModel updatedAstrologer;
      
      // Handle both profileData (Map) and astrologer (Model) updates
      if (event.profileData != null) {
        print('📝 [ProfileBloc] Updating profile with data: ${event.profileData!.keys}');
        updatedAstrologer = await repository.updateProfileWithData(event.profileData!);
      } else {
        print('📝 [ProfileBloc] Updating profile with model');
        updatedAstrologer = await repository.updateProfile(event.astrologer!);
      }
      
      print('✅ [ProfileBloc] Profile updated successfully');
      
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile updated successfully',
      ));
    } catch (e) {
      print('❌ [ProfileBloc] Error updating profile: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImageEvent event, Emitter<ProfileState> emit) async {
    // Keep current data visible during image upload
    if (state is ProfileLoadedState) {
      final currentState = state as ProfileLoadedState;
      emit(ProfileUpdating('image', currentState.astrologer));
    } else {
      emit(const ProfileLoading());
    }
    
    try {
      final imageUrl = await repository.uploadProfileImage(event.imagePath);
      print('✅ [ProfileBloc] Profile image uploaded: $imageUrl');
      
      // Reload profile to get complete astrologer data with new image
      final updatedAstrologer = await repository.loadProfile();
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile image uploaded successfully',
      ));
    } catch (e) {
      print('❌ [ProfileBloc] Error uploading image: $e');
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
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
}
