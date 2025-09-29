import '../../auth/models/astrologer_model.dart';

abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final AstrologerModel astrologer;
  
  UpdateProfileEvent(this.astrologer);
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

class UpdateBioEvent extends ProfileEvent {
  final String bio;
  
  UpdateBioEvent(this.bio);
}
