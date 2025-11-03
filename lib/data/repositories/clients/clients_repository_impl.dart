import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/clients/models/client_model.dart';
import '../base_repository.dart';
import 'clients_repository.dart';

/// Implementation of ClientsRepository
/// Handles client data operations with two-phase loading pattern
class ClientsRepositoryImpl extends BaseRepository implements ClientsRepository {
  final ApiService apiService;
  final StorageService storageService;

  // In-memory cache for instant access
  List<ClientModel> _cachedClients = [];

  ClientsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // INSTANT DATA (Instagram/WhatsApp-style instant load)
  // ============================================================================

  @override
  List<ClientModel> getInstantData() {
    // 1. Check in-memory cache first (fastest)
    if (_cachedClients.isNotEmpty) {
      print('⚡ [ClientsRepo] Returning ${_cachedClients.length} clients from memory cache');
      return List.from(_cachedClients);
    }

    // 2. Try to load from persistent storage (still fast, survives restart)
    try {
      final cachedData = storageService.getStringSync('clients_cache');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _cachedClients = jsonList
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print(
            '⚡ [ClientsRepo] Loaded ${_cachedClients.length} clients from persistent cache (survived restart!)');
        return List.from(_cachedClients);
      }
    } catch (e) {
      print('⚠️ [ClientsRepo] Error loading from persistent cache: $e');
    }

    // 3. If no persistent cache, use mock data for development
    print('ℹ️ [ClientsRepo] No cached clients, using mock data');
    _cachedClients = MockClientsData.getMockClients();
    return List.from(_cachedClients);
  }

  // ============================================================================
  // LOAD CLIENTS (with persistent caching)
  // ============================================================================

  @override
  Future<List<ClientModel>> getClients() async {
    try {
      final astrologerId = await _getAstrologerId();
      
      print('🌐 [ClientsRepo] Fetching clients for astrologer: $astrologerId');
      
      final response = await apiService.get(
        '/api/consultation/clients/$astrologerId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> clientsData = response.data['data'] ?? [];
        final clients = clientsData
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache in memory AND persist to disk
        _cachedClients = clients;
        await cacheClients(clients);
        print(
            '💾 [ClientsRepo] Saved ${clients.length} clients to memory + persistent cache');

        return clients;
      } else {
        throw Exception(
            'Failed to load clients: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('⚠️ [ClientsRepo] API error, falling back to cached/mock data: $e');
      
      // Try to return cached data if API fails
      final cachedClients = await getCachedClients();
      if (cachedClients.isNotEmpty) {
        print('✅ [ClientsRepo] Using ${cachedClients.length} cached clients');
        return cachedClients;
      }
      
      // Fallback to mock data for development
      print('ℹ️ [ClientsRepo] Using mock data for development');
      final mockClients = MockClientsData.getMockClients();
      
      // Cache mock data so it persists
      _cachedClients = mockClients;
      await cacheClients(mockClients);
      
      return mockClients;
    }
  }

  @override
  Future<ClientModel?> getClientByPhone(String phone) async {
    try {
      final astrologerId = await _getAstrologerId();
      
      final response = await apiService.get(
        '/api/consultation/clients/$astrologerId',
        queryParameters: {'phone': phone},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final clientData = response.data['data'];
        if (clientData != null) {
          return ClientModel.fromJson(clientData as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching client by phone: $e');
      
      // Search in cache
      final client = _cachedClients.firstWhere(
        (c) => c.clientPhone == phone,
        orElse: () => throw Exception('Client not found'),
      );
      return client;
    }
  }

  // ============================================================================
  // CACHING
  // ============================================================================

  @override
  Future<List<ClientModel>> getCachedClients() async {
    try {
      final cachedData = await storageService.getString('clients_cache');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading cached clients: $e');
    }
    return [];
  }

  @override
  Future<void> cacheClients(List<ClientModel> clients) async {
    try {
      final jsonList = clients.map((c) => c.toJson()).toList();
      await storageService.setString('clients_cache', jsonEncode(jsonList));
      print('💾 [ClientsRepo] Cached ${clients.length} clients to persistent storage');
    } catch (e) {
      print('⚠️ [ClientsRepo] Error caching clients: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('clients_cache');
      _cachedClients.clear();
      print('🗑️ [ClientsRepo] Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Future<String> _getAstrologerId() async {
    final userData = await storageService.getString('user_data');
    if (userData != null) {
      final json = jsonDecode(userData);
      return json['_id'] ?? json['id'] ?? '';
    }
    throw Exception('Astrologer ID not found');
  }
}

