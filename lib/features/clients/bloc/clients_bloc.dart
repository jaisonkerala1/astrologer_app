import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/clients/clients_repository.dart';
import '../models/client_model.dart';
import 'clients_event.dart';
import 'clients_state.dart';

/// BLoC for managing clients state and business logic
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final ClientsRepository repository;

  ClientsBloc({required this.repository}) : super(const ClientsInitial()) {
    on<LoadClientsEvent>(_onLoadClients);
    on<RefreshClientsEvent>(_onRefreshClients);
    on<SearchClientsEvent>(_onSearchClients);
    on<FilterClientsEvent>(_onFilterClients);
    on<SortClientsEvent>(_onSortClients);
  }

  /// Two-phase loading: instant cache + background refresh
  Future<void> _onLoadClients(
    LoadClientsEvent event,
    Emitter<ClientsState> emit,
  ) async {
    // Smart Loading: If data already exists and not forcing refresh, skip
    if (state is ClientsLoaded && !event.forceRefresh) {
      print('✅ [ClientsBloc] Clients already loaded, skipping API call');
      return;
    }

    try {
      print('🔄 [ClientsBloc] Loading clients (two-phase pattern)...');

      // PHASE 1: Instant loading from cache (synchronous)
      try {
        final instantData = repository.getInstantData();
        if (instantData.isNotEmpty) {
          print(
              '⚡ [ClientsBloc] Phase 1: Emitting ${instantData.length} clients from cache (isRefreshing: true)');
          emit(ClientsLoaded(
            allClients: instantData,
            displayedClients: instantData,
            isRefreshing: true,
          ));
        } else {
          print(
              '⚠️ [ClientsBloc] No instant data available, showing loading state');
          emit(const ClientsLoading());
        }
      } catch (e) {
        print(
            '⚠️ [ClientsBloc] Error in Phase 1: $e, showing loading state');
        emit(const ClientsLoading());
      }

      // PHASE 2: Background refresh from API
      print('🌐 [ClientsBloc] Phase 2: Fetching fresh data from API...');
      final clients = await repository.getClients();
      print(
          '✅ [ClientsBloc] Phase 2: Loaded ${clients.length} fresh clients from API');

      emit(ClientsLoaded(
        allClients: clients,
        displayedClients: clients,
        isRefreshing: false,
      ));
      print('✅ [ClientsBloc] Two-phase loading complete!');
    } catch (e) {
      print('❌ [ClientsBloc] Error loading clients: $e');
      
      // If we already showed cached data, just hide refresh indicator
      if (state is ClientsLoaded) {
        final currentState = state as ClientsLoaded;
        print('⚠️ [ClientsBloc] API refresh failed, keeping cached data');
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        // Only show error if no data was shown
        emit(ClientsError(
            message: e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  /// Refresh clients (pull-to-refresh)
  Future<void> _onRefreshClients(
    RefreshClientsEvent event,
    Emitter<ClientsState> emit,
  ) async {
    try {
      print('🔄 [ClientsBloc] Refreshing clients...');
      final clients = await repository.getClients();
      print('✅ [ClientsBloc] Refreshed ${clients.length} clients');

      // Preserve current filters and search
      if (state is ClientsLoaded) {
        final currentState = state as ClientsLoaded;
        final filtered = _applyFilters(
          clients,
          currentState.searchQuery,
          currentState.activeFilter,
        );

        emit(ClientsLoaded(
          allClients: clients,
          displayedClients: filtered,
          searchQuery: currentState.searchQuery,
          activeFilter: currentState.activeFilter,
          isRefreshing: false,
        ));
      } else {
        emit(ClientsLoaded(
          allClients: clients,
          displayedClients: clients,
          isRefreshing: false,
        ));
      }
    } catch (e) {
      print('❌ [ClientsBloc] Error refreshing clients: $e');
      if (state is ClientsLoaded) {
        final currentState = state as ClientsLoaded;
        emit(currentState.copyWith(isRefreshing: false));
      }
    }
  }

  /// Search clients by query
  void _onSearchClients(
    SearchClientsEvent event,
    Emitter<ClientsState> emit,
  ) {
    if (state is! ClientsLoaded) return;

    final currentState = state as ClientsLoaded;
    final query = event.query.toLowerCase();

    print('🔍 [ClientsBloc] Searching clients with query: "$query"');

    final filtered = _applyFilters(
      currentState.allClients,
      query,
      currentState.activeFilter,
    );

    emit(currentState.copyWith(
      searchQuery: query,
      displayedClients: filtered,
    ));

    print(
        '✅ [ClientsBloc] Search complete: ${filtered.length} clients found');
  }

  /// Filter clients by category
  void _onFilterClients(
    FilterClientsEvent event,
    Emitter<ClientsState> emit,
  ) {
    if (state is! ClientsLoaded) return;

    final currentState = state as ClientsLoaded;

    print('🔧 [ClientsBloc] Filtering clients by: ${event.filter}');

    final filtered = _applyFilters(
      currentState.allClients,
      currentState.searchQuery,
      event.filter,
    );

    emit(currentState.copyWith(
      activeFilter: event.filter,
      displayedClients: filtered,
    ));

    print(
        '✅ [ClientsBloc] Filter complete: ${filtered.length} clients match');
  }

  /// Sort clients
  void _onSortClients(
    SortClientsEvent event,
    Emitter<ClientsState> emit,
  ) {
    if (state is! ClientsLoaded) return;

    final currentState = state as ClientsLoaded;
    final sorted = List<ClientModel>.from(currentState.displayedClients);

    print('📊 [ClientsBloc] Sorting clients by: ${event.sortOption}');

    switch (event.sortOption) {
      case ClientSortOption.lastConsultation:
        sorted.sort((a, b) => b.lastConsultation.compareTo(a.lastConsultation));
        break;
      case ClientSortOption.nameAZ:
        sorted.sort((a, b) => a.clientName.compareTo(b.clientName));
        break;
      case ClientSortOption.totalConsultations:
        sorted.sort((a, b) => b.totalConsultations.compareTo(a.totalConsultations));
        break;
      case ClientSortOption.totalSpent:
        sorted.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
    }

    emit(currentState.copyWith(displayedClients: sorted));
    print('✅ [ClientsBloc] Sort complete');
  }

  /// Apply search and filter to clients list
  List<ClientModel> _applyFilters(
    List<ClientModel> clients,
    String searchQuery,
    String filter,
  ) {
    var filtered = clients;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        return client.clientName.toLowerCase().contains(searchQuery) ||
            client.clientPhone.toLowerCase().contains(searchQuery) ||
            (client.clientEmail?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    switch (filter) {
      case 'recent':
        filtered = filtered.where((client) => client.isRecent).toList();
        break;
      case 'frequent':
        filtered = filtered.where((client) => client.isFrequent).toList();
        break;
      case 'vip':
        filtered = filtered.where((client) => client.isVIP).toList();
        break;
      case 'all':
      default:
        break;
    }

    // Default sort by last consultation (most recent first)
    filtered.sort((a, b) => b.lastConsultation.compareTo(a.lastConsultation));

    return filtered;
  }
}

