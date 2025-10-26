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
    emit(ProfileLoading());
    
    try {
      final astrologer = await repository.loadProfile();
      emit(ProfileLoadedState(astrologer));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    
    try {
      final updatedAstrologer = await repository.updateProfile(event.astrologer);
      
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile updated successfully',
      ));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImageEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    
    try {
      final imageUrl = await repository.uploadProfileImage(event.imagePath);
      // Reload profile to get complete astrologer data with new image
      final updatedAstrologer = await repository.loadProfile();
      emit(ProfileLoadedState(
        updatedAstrologer,
        successMessage: 'Profile image uploaded successfully',
      ));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSpecializations(UpdateSpecializationsEvent event, Emitter<ProfileState> emit) async {
    try {
      final updatedAstrologer = await repository.updateSpecializations(event.specializations);
      emit(ProfileLoadedState(updatedAstrologer));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateLanguages(UpdateLanguagesEvent event, Emitter<ProfileState> emit) async {
    try {
      final updatedAstrologer = await repository.updateLanguages(event.languages);
      emit(ProfileLoadedState(updatedAstrologer));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateRate(UpdateRateEvent event, Emitter<ProfileState> emit) async {
    try {
      final updatedAstrologer = await repository.updateRate(event.ratePerMinute);
      emit(ProfileLoadedState(updatedAstrologer));
    } catch (e) {
      emit(ProfileErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
