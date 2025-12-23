import '../../auth/models/astrologer_model.dart';

abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {
  final bool forceRefresh; // If true, reload even if data exists
  
  LoadProfileEvent({this.forceRefresh = false});
}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic>? profileData; // For partial updates
  final AstrologerModel? astrologer; // For full model updates
  
  UpdateProfileEvent({this.profileData, this.astrologer})
      : assert(profileData != null || astrologer != null,
            'Either profileData or astrologer must be provided');
}

class UploadProfileImageEvent extends ProfileEvent {
  final String imagePath;
  
  UploadProfileImageEvent(this.imagePath);
}

class UpdateSpecializationsEvent extends ProfileEvent {
  final List<String> specializations;
  
  UpdateSpecializationsEvent(this.specializations);
}

class UpdateLanguagesEvent extends ProfileEvent {
  final List<String> languages;
  
  UpdateLanguagesEvent(this.languages);
}

class UpdateRateEvent extends ProfileEvent {
  final double ratePerMinute;
  
  UpdateRateEvent(this.ratePerMinute);
}

class RequestVerificationEvent extends ProfileEvent {}

class GetVerificationStatusEvent extends ProfileEvent {}
