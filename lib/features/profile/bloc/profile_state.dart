import 'package:equatable/equatable.dart';
import '../../auth/models/astrologer_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoadedState extends ProfileState {
  final AstrologerModel astrologer;
  final String? successMessage; // Optional success message after updates
  
  ProfileLoadedState(this.astrologer, {this.successMessage});
  
  @override
  List<Object?> get props => [astrologer, successMessage];
}

class ProfileErrorState extends ProfileState {
  final String message;
  
  const ProfileErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// ProfileUpdatedState removed - use ProfileLoadedState with successMessage instead
// ImageUploadedState removed - use ProfileLoadedState with updated astrologer instead
