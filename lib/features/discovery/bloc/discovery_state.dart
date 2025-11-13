import 'package:equatable/equatable.dart';
import '../models/discovery_astrologer.dart';

abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

/// Loading state
class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// Loaded state with astrologers
class DiscoveryLoaded extends DiscoveryState {
  final List<DiscoveryAstrologer> astrologers;
  final String? activeFilter;
  final String? searchQuery;

  const DiscoveryLoaded({
    required this.astrologers,
    this.activeFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [astrologers, activeFilter, searchQuery];

  DiscoveryLoaded copyWith({
    List<DiscoveryAstrologer>? astrologers,
    String? activeFilter,
    String? searchQuery,
  }) {
    return DiscoveryLoaded(
      astrologers: astrologers ?? this.astrologers,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Error state
class DiscoveryError extends DiscoveryState {
  final String message;

  const DiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}

