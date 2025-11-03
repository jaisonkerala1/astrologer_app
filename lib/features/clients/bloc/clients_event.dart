import 'package:equatable/equatable.dart';

/// Base class for all Clients events
abstract class ClientsEvent extends Equatable {
  const ClientsEvent();

  @override
  List<Object?> get props => [];
}

/// Load clients with two-phase pattern (instant cache + background refresh)
class LoadClientsEvent extends ClientsEvent {
  final bool forceRefresh;

  const LoadClientsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Refresh clients (pull-to-refresh)
class RefreshClientsEvent extends ClientsEvent {
  const RefreshClientsEvent();
}

/// Search clients by query
class SearchClientsEvent extends ClientsEvent {
  final String query;

  const SearchClientsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filter clients by category
class FilterClientsEvent extends ClientsEvent {
  final String filter; // 'all', 'recent', 'frequent', 'vip'

  const FilterClientsEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Sort clients
class SortClientsEvent extends ClientsEvent {
  final ClientSortOption sortOption;

  const SortClientsEvent(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

enum ClientSortOption {
  lastConsultation,
  nameAZ,
  totalConsultations,
  totalSpent,
}

