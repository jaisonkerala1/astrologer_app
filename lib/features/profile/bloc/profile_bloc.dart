import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/models/astrologer_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  ProfileBloc() : super(ProfileInitial()) {
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
      // For MVP, we'll use mock data since backend isn't ready yet
      // In production, this would call the actual API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      final mockAstrologer = AstrologerModel(
        id: '1',
        phone: '+91 9876543210',
        name: 'Dr. Rajesh Kumar',
        email: 'rajesh@astrologer.com',
        profilePicture: null,
        specializations: ['Vedic Astrology', 'Tarot Reading', 'Numerology'],
        languages: ['English', 'Hindi', 'Bengali'],
        experience: 8,
        ratePerMinute: 75.0,
        isOnline: false,
        totalEarnings: 15600.0,
        bio: 'Experienced Vedic astrologer with 8+ years of practice in traditional Indian astrology, tarot reading, and numerology.',
        awards: 'Best Astrologer 2023, Vedic Excellence Award, Client Choice Award',
        certificates: 'Certified Vedic Astrologer, Jyotish Acharya, Advanced Tarot Certification',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      );
      
      emit(ProfileLoadedState(mockAstrologer));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    
    try {
      // For MVP, we'll simulate the API call
      // In production, this would call the actual API
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local storage (persist JSON)
      await _storageService.setUserData(jsonEncode(event.astrologer.toJson()));
      
      emit(ProfileUpdatedState(
        astrologer: event.astrologer,
        message: 'Profile updated successfully',
      ));
    } catch (e) {
      emit(ProfileErrorState('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImageEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    
    try {
      // For MVP, we'll simulate the API call
      // In production, this would call the actual API
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful upload
      final imageUrl = 'https://example.com/profile/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      emit(ImageUploadedState(imageUrl));
    } catch (e) {
      emit(ProfileErrorState('Failed to upload image: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSpecializations(UpdateSpecializationsEvent event, Emitter<ProfileState> emit) async {
    try {
      // Get current profile
      if (state is ProfileLoadedState) {
        final currentAstrologer = (state as ProfileLoadedState).astrologer;
        final updatedAstrologer = currentAstrologer.copyWith(
          specializations: event.specializations,
          updatedAt: DateTime.now(),
        );
        
        add(UpdateProfileEvent(updatedAstrologer));
      }
    } catch (e) {
      emit(ProfileErrorState('Failed to update specializations: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLanguages(UpdateLanguagesEvent event, Emitter<ProfileState> emit) async {
    try {
      // Get current profile
      if (state is ProfileLoadedState) {
        final currentAstrologer = (state as ProfileLoadedState).astrologer;
        final updatedAstrologer = currentAstrologer.copyWith(
          languages: event.languages,
          updatedAt: DateTime.now(),
        );
        
        add(UpdateProfileEvent(updatedAstrologer));
      }
    } catch (e) {
      emit(ProfileErrorState('Failed to update languages: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRate(UpdateRateEvent event, Emitter<ProfileState> emit) async {
    try {
      // Get current profile
      if (state is ProfileLoadedState) {
        final currentAstrologer = (state as ProfileLoadedState).astrologer;
        final updatedAstrologer = currentAstrologer.copyWith(
          ratePerMinute: event.ratePerMinute,
          updatedAt: DateTime.now(),
        );
        
        add(UpdateProfileEvent(updatedAstrologer));
      }
    } catch (e) {
      emit(ProfileErrorState('Failed to update rate: ${e.toString()}'));
    }
  }
}
