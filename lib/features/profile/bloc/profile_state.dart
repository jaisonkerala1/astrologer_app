import '../../auth/models/astrologer_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoadedState extends ProfileState {
  final AstrologerModel astrologer;
  
  ProfileLoadedState(this.astrologer);
}

class ProfileUpdatedState extends ProfileState {
  final AstrologerModel astrologer;
  final String message;
  
  ProfileUpdatedState({
    required this.astrologer,
    required this.message,
  });
}

class ProfileErrorState extends ProfileState {
  final String message;
  
  ProfileErrorState(this.message);
}

class ImageUploadedState extends ProfileState {
  final String imageUrl;
  
  ImageUploadedState(this.imageUrl);
}
