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
  
  const ProfileLoadedState(this.astrologer, {this.successMessage});
  
  @override
  List<Object?> get props => [astrologer, successMessage];
  
  // Helper to create a copy with updated fields
  ProfileLoadedState copyWith({
    AstrologerModel? astrologer,
    String? successMessage,
  }) {
    return ProfileLoadedState(
      astrologer ?? this.astrologer,
      successMessage: successMessage,
    );
  }
}

class ProfileUpdating extends ProfileState {
  final String field; // "profile", "image", "specializations", "languages", "rate"
  final AstrologerModel currentAstrologer; // Keep current data visible
  
  const ProfileUpdating(this.field, this.currentAstrologer);
  
  @override
  List<Object?> get props => [field, currentAstrologer];
}

class ProfileErrorState extends ProfileState {
  final String message;
  
  const ProfileErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}
