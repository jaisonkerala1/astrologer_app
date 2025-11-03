import 'package:equatable/equatable.dart';
import '../models/client_model.dart';

/// Base class for all Clients states
abstract class ClientsState extends Equatable {
  const ClientsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

/// Loading state (only shown on first load if no cache exists)
class ClientsLoading extends ClientsState {
  final bool isInitialLoad;

  const ClientsLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

/// Loaded state with clients data
class ClientsLoaded extends ClientsState {
  final List<ClientModel> allClients; // Original unfiltered data
  final List<ClientModel> displayedClients; // Filtered/searched data
  final String searchQuery;
  final String activeFilter; // 'all', 'recent', 'frequent', 'vip'
  final bool isRefreshing; // Instagram-style background refresh indicator

  const ClientsLoaded({
    required this.allClients,
    required this.displayedClients,
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        allClients,
        displayedClients,
        searchQuery,
        activeFilter,
        isRefreshing,
      ];

  /// Create a copy with updated fields
  ClientsLoaded copyWith({
    List<ClientModel>? allClients,
    List<ClientModel>? displayedClients,
    String? searchQuery,
    String? activeFilter,
    bool? isRefreshing,
  }) {
    return ClientsLoaded(
      allClients: allClients ?? this.allClients,
      displayedClients: displayedClients ?? this.displayedClients,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// Helper getters
  int get totalClients => allClients.length;
  int get displayedCount => displayedClients.length;
  bool get hasFilters => searchQuery.isNotEmpty || activeFilter != 'all';

  // Stats for display
  int get totalSessions =>
      allClients.fold(0, (sum, client) => sum + client.totalConsultations);

  double get totalRevenue =>
      allClients.fold(0.0, (sum, client) => sum + client.totalSpent);

  int get recentClientsCount =>
      allClients.where((c) => c.isRecent).length;

  int get vipClientsCount =>
      allClients.where((c) => c.isVIP).length;
}

/// Error state
class ClientsError extends ClientsState {
  final String message;

  const ClientsError({required this.message});

  @override
  List<Object?> get props => [message];
}

