import 'package:equatable/equatable.dart';

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Load astrologers with optional filters
class LoadAstrologersEvent extends DiscoveryEvent {
  final String? specialization;
  final String? language;
  final double? minRating;
  final bool? onlineOnly;
  final String? sortBy; // 'rating', 'experience', 'consultations'

  const LoadAstrologersEvent({
    this.specialization,
    this.language,
    this.minRating,
    this.onlineOnly,
    this.sortBy,
  });

  @override
  List<Object?> get props => [specialization, language, minRating, onlineOnly, sortBy];
}

/// Refresh astrologers list
class RefreshAstrologersEvent extends DiscoveryEvent {
  const RefreshAstrologersEvent();
}

/// Search astrologers by name or keyword
class SearchAstrologersEvent extends DiscoveryEvent {
  final String query;

  const SearchAstrologersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clear search and filters
class ClearFiltersEvent extends DiscoveryEvent {
  const ClearFiltersEvent();
}

/// Load similar astrologers based on current astrologer's profile
class LoadSimilarAstrologersEvent extends DiscoveryEvent {
  final String currentAstrologerId;
  final List<String> specializations;
  
  const LoadSimilarAstrologersEvent({
    required this.currentAstrologerId,
    required this.specializations,
  });
  
  @override
  List<Object?> get props => [currentAstrologerId, specializations];
}

