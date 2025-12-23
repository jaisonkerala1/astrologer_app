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
  final bool isRefreshing; // Instagram/WhatsApp-style background refresh
  
  const ProfileLoadedState(
    this.astrologer, {
    this.successMessage,
    this.isRefreshing = false,
  });
  
  @override
  List<Object?> get props => [astrologer, successMessage, isRefreshing];
  
  // Helper to create a copy with updated fields
  ProfileLoadedState copyWith({
    AstrologerModel? astrologer,
    String? successMessage,
    bool? isRefreshing,
  }) {
    return ProfileLoadedState(
      astrologer ?? this.astrologer,
      successMessage: successMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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

class VerificationRequestSuccess extends ProfileState {
  final String message;
  final AstrologerModel? updatedAstrologer;
  
  const VerificationRequestSuccess(this.message, {this.updatedAstrologer});
  
  @override
  List<Object?> get props => [message, updatedAstrologer];
}

class VerificationRequirementsNotMet extends ProfileState {
  final String message;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> current;
  
  const VerificationRequirementsNotMet({
    required this.message,
    required this.requirements,
    required this.current,
  });
  
  @override
  List<Object?> get props => [message, requirements, current];
}

class VerificationStatusLoaded extends ProfileState {
  final Map<String, dynamic> statusData;
  
  const VerificationStatusLoaded(this.statusData);
  
  @override
  List<Object?> get props => [statusData];
}
