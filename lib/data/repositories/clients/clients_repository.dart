import '../../../features/clients/models/client_model.dart';

/// Repository interface for clients data operations
abstract class ClientsRepository {
  /// Get instant data from cache (synchronous, no await!)
  /// Returns data from memory or persistent storage for instant UI
  List<ClientModel> getInstantData();

  /// Fetch all clients from API (with caching)
  Future<List<ClientModel>> getClients();

  /// Get a specific client by phone
  Future<ClientModel?> getClientByPhone(String phone);

  /// Get cached clients from persistent storage
  Future<List<ClientModel>> getCachedClients();

  /// Cache clients to persistent storage
  Future<void> cacheClients(List<ClientModel> clients);

  /// Clear all cached data
  Future<void> clearCache();
}

