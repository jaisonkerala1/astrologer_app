import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/heal/models/service_model.dart';
import '../../../features/heal/models/service_request_model.dart';
import '../base_repository.dart';
import 'heal_repository.dart';

class HealRepositoryImpl extends BaseRepository implements HealRepository {
  final ApiService apiService;
  final StorageService storageService;

  // In-memory storage for offline persistence
  final List<ServiceModel> _localServices = [];
  final List<ServiceRequest> _localRequests = [];

  HealRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // INSTANT DATA (Instagram/WhatsApp-style instant load)
  // ============================================================================

  @override
  Map<String, dynamic> getInstantData() {
    // 1. Check in-memory cache first (fastest)
    if (_localServices.isNotEmpty || _localRequests.isNotEmpty) {
      print('⚡ [HealRepo] Returning ${_localServices.length} services + ${_localRequests.length} requests from memory');
      return {
        'services': [..._localServices],
        'requests': [..._localRequests],
      };
    }
    
    // 2. Try to load from persistent storage (still fast, survives restart!)
    try {
      final cachedServicesData = storageService.getStringSync('heal_services_cache');
      final cachedRequestsData = storageService.getStringSync('heal_requests_cache');
      
      if (cachedServicesData != null || cachedRequestsData != null) {
        // Load services from disk
        if (cachedServicesData != null) {
          final List<dynamic> jsonList = jsonDecode(cachedServicesData);
          _localServices.addAll(jsonList.map((json) => ServiceModel.fromJson(json)));
          print('⚡ [HealRepo] Loaded ${_localServices.length} services from persistent cache');
        }
        
        // Load requests from disk
        if (cachedRequestsData != null) {
          final List<dynamic> jsonList = jsonDecode(cachedRequestsData);
          _localRequests.addAll(jsonList.map((json) => ServiceRequest.fromJson(json)));
          print('⚡ [HealRepo] Loaded ${_localRequests.length} requests from persistent cache');
        }
        
        print('⚡ [HealRepo] Total from persistent cache (survived restart!)');
        return {
          'services': [..._localServices],
          'requests': [..._localRequests],
        };
      }
    } catch (e) {
      print('⚠️ [HealRepo] Error loading from persistent cache: $e');
    }
    
    // 3. If no persistent cache, generate dummy data
    print('ℹ️ [HealRepo] No cached data, using dummy data');
    return {
      'services': _generateDummyServices(),
      'requests': _generateDummyRequests(),
    };
  }

  // ============================================================================
  // SERVICES MANAGEMENT
  // ============================================================================

  @override
  Future<List<ServiceModel>> getServices({String? category}) async {
    print('🔍 [HealRepo] Loading services, category: ${category ?? "all"}');
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      
      final response = await apiService.get(
        '/api/services',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> servicesList = data['services'] ?? data ?? [];
        final services = servicesList.map((json) => ServiceModel.fromJson(_transformServiceJson(json))).toList();
        
        // Update local cache
        _localServices.clear();
        _localServices.addAll(services);
        
        // Save to persistent storage
        await _cacheServices(services);
        print('✅ [HealRepo] Got ${services.length} services from API + saved to persistent cache');
        return services;
      }
      throw Exception('Failed to load services');
    } catch (e) {
      print('! [HealRepo] API not available, using dummy services + local: ${handleError(e)}');
      
      // Merge local services with dummy data
      print('🔍 [HealRepo] _localServices count: ${_localServices.length}');
      for (int i = 0; i < _localServices.length; i++) {
        print('   📝 Local service $i: ${_localServices[i].id} - ${_localServices[i].name}');
      }
      
      final dummyServices = _generateDummyServices();
      print('🔍 [HealRepo] Generated ${dummyServices.length} dummy services');
      
      final allServices = [..._localServices, ...dummyServices];
      
      // Apply category filter if needed
      if (category != null && category != 'all') {
        final filtered = allServices.where((s) => s.category == category).toList();
        print('✅ [HealRepo] Returning ${filtered.length} filtered services (category: $category)');
        return filtered;
      }
      
      print('✅ [HealRepo] Returning ${allServices.length} total services (${_localServices.length} local + ${dummyServices.length} dummy)');
      return allServices;
    }
  }
  
  /// Transform backend JSON to match frontend model
  Map<String, dynamic> _transformServiceJson(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['_id']?.toString() ?? '',
      'name': json['name'] ?? '',
      'description': json['description'] ?? '',
      'category': json['category'] ?? '',
      'price': json['price'] ?? 0.0,
      'duration': json['duration'] ?? '',
      'requirements': json['requirements'] ?? '',
      'benefits': json['benefits'] ?? [],
      'isActive': json['isActive'] ?? true,
      'imageUrl': json['imageUrl'] ?? '',
      'createdAt': json['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': json['updatedAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await apiService.get('/api/services/$id');
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(_transformServiceJson(response.data['data']));
      }
      throw Exception('Failed to load service');
    } catch (e) {
      // Try local cache
      final localService = _localServices.where((s) => s.id == id).firstOrNull;
      if (localService != null) return localService;
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ServiceModel> createService(ServiceModel service) async {
    print('🔍 [HealRepo] Creating service: ${service.name}');
    try {
      final response = await apiService.post(
        '/api/services',
        data: service.toJson(),
      );
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service created via API');
        final newService = ServiceModel.fromJson(_transformServiceJson(response.data['data']));
        _localServices.insert(0, newService);
        return newService;
      }
      throw Exception('Failed to create service');
    } catch (e) {
      print('! [HealRepo] API not available, creating service locally: ${handleError(e)}');
      
      // Create service with unique ID and add to local storage
      final newService = service.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _localServices.insert(0, newService);
      print('✅ [HealRepo] Service created locally: ${newService.id} - ${newService.name}');
      print('   Total local services: ${_localServices.length}');
      
      return newService;
    }
  }

  @override
  Future<ServiceModel> updateService(String id, ServiceModel service) async {
    print('🔍 [HealRepo] Updating service: $id');
    try {
      final response = await apiService.put('/api/services/$id', data: service.toJson());
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service updated via API');
        final updatedService = ServiceModel.fromJson(_transformServiceJson(response.data['data']));
        // Update local cache
        final index = _localServices.indexWhere((s) => s.id == id);
        if (index != -1) _localServices[index] = updatedService;
        return updatedService;
      }
      throw Exception('Failed to update service');
    } catch (e) {
      print('! [HealRepo] API not available, updating service locally: ${handleError(e)}');
      
      // Update in local storage
      final index = _localServices.indexWhere((s) => s.id == id);
      if (index != -1) {
        final updatedService = service.copyWith(
          id: id,
          updatedAt: DateTime.now(),
        );
        _localServices[index] = updatedService;
        print('✅ [HealRepo] Service updated locally: $id');
        return updatedService;
      }
      
      // If not found in local, return the service as-is
      print('⚠️ [HealRepo] Service not found in local storage, returning as-is');
      return service.copyWith(id: id, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteService(String id) async {
    print('🔍 [HealRepo] Deleting service: $id');
    try {
      final response = await apiService.delete('/api/services/$id');
      if (response.data['success'] != true) {
        throw Exception('Failed to delete service');
      }
      print('✅ [HealRepo] Service deleted via API');
      // Remove from local cache
      _localServices.removeWhere((s) => s.id == id);
    } catch (e) {
      print('! [HealRepo] API not available, deleting service locally: ${handleError(e)}');
      
      // Remove from local storage
      _localServices.removeWhere((s) => s.id == id);
      print('✅ [HealRepo] Service deleted locally: $id');
      print('   Remaining local services: ${_localServices.length}');
    }
  }

  @override
  Future<ServiceModel> toggleServiceStatus(String id, bool isActive) async {
    print('🔍 [HealRepo] Toggling service status: $id to $isActive');
    try {
      final response = await apiService.patch('/api/services/$id/toggle');
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service status toggled via API');
        final updatedService = ServiceModel.fromJson(_transformServiceJson(response.data['data']));
        // Update local cache
        final index = _localServices.indexWhere((s) => s.id == id);
        if (index != -1) _localServices[index] = updatedService;
        return updatedService;
      }
      throw Exception('Failed to toggle service status');
    } catch (e) {
      print('! [HealRepo] API not available, toggling locally: ${handleError(e)}');
      
      // Update in local storage
      final index = _localServices.indexWhere((s) => s.id == id);
      if (index != -1) {
        final updatedService = _localServices[index].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        _localServices[index] = updatedService;
        print('✅ [HealRepo] Service status toggled locally: $id');
        return updatedService;
      }
      
      throw Exception('Service not found');
    }
  }

  @override
  Future<List<ServiceRequest>> getServiceRequests({RequestStatus? status}) async {
    print('🔍 [HealRepo] Loading service requests, status: ${status?.name ?? "all"}');
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.name;
      
      final response = await apiService.get(
        '/api/service-requests',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> requestsList = data['requests'] ?? data ?? [];
        final requests = requestsList.map((json) => ServiceRequest.fromJson(_transformRequestJson(json))).toList();
        
        // Update local cache
        _localRequests.clear();
        _localRequests.addAll(requests);
        
        // Save to persistent storage
        await _cacheRequests(requests);
        print('✅ [HealRepo] Got ${requests.length} requests from API + saved to persistent cache');
        return requests;
      }
      throw Exception('Failed to load service requests');
    } catch (e) {
      print('! [HealRepo] API not available, using dummy requests + local: ${handleError(e)}');
      
      // Merge local requests with dummy data
      print('🔍 [HealRepo] _localRequests count: ${_localRequests.length}');
      for (int i = 0; i < _localRequests.length; i++) {
        print('   📝 Local request $i: ${_localRequests[i].id} - ${_localRequests[i].serviceName}');
      }
      
      final dummyRequests = _generateDummyRequests();
      print('🔍 [HealRepo] Generated ${dummyRequests.length} dummy requests');
      
      // Filter out dummy requests that exist in local requests (local takes precedence)
      final localIds = _localRequests.map((r) => r.id).toSet();
      final filteredDummyRequests = dummyRequests.where((d) => !localIds.contains(d.id)).toList();
      print('🔍 [HealRepo] Filtered ${dummyRequests.length - filteredDummyRequests.length} dummy requests (already in local)');
      
      // Store the dummy requests in _localRequests so they can be updated later
      if (_localRequests.isEmpty && filteredDummyRequests.isNotEmpty) {
        _localRequests.addAll(filteredDummyRequests);
        print('💾 [HealRepo] Stored ${filteredDummyRequests.length} dummy requests in _localRequests for future updates');
      }
      
      // Return all local requests (which now includes the dummy data if it was empty before)
      final allRequests = _localRequests;
      
      // Apply status filter if needed
      if (status != null) {
        final filtered = allRequests.where((r) => r.status == status).toList();
        print('✅ [HealRepo] Returning ${filtered.length} filtered requests (status: ${status.name})');
        return filtered;
      }
      
      print('✅ [HealRepo] Returning ${allRequests.length} total requests');
      return allRequests;
    }
  }
  
  /// Transform backend JSON to match frontend model
  Map<String, dynamic> _transformRequestJson(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['_id']?.toString() ?? '',
      'customerName': json['customerName'] ?? '',
      'customerPhone': json['customerPhone'] ?? '',
      'customerEmail': json['customerEmail'] ?? '',
      'serviceName': json['serviceName'] ?? '',
      'serviceCategory': json['serviceCategory'] ?? '',
      'requestedDate': json['requestedDate'] ?? DateTime.now().toIso8601String(),
      'requestedTime': json['requestedTime'] ?? '',
      'status': json['status'] ?? 'pending',
      'price': json['price'] ?? 0.0,
      'specialInstructions': json['specialInstructions'] ?? '',
      'notes': json['notes'],
      'createdAt': json['createdAt'] ?? DateTime.now().toIso8601String(),
      'startedAt': json['startedAt'],
      'completedAt': json['completedAt'],
      'cancelledAt': json['cancelledAt'],
    };
  }

  /// Merge sparse API responses (like status/notes updates) with existing cached request data.
  Map<String, dynamic> _mergeWithExisting(String id, Map<String, dynamic> apiData) {
    final index = _localRequests.indexWhere((r) => r.id == id);
    final existing = index != -1 ? _localRequests[index] : null;

    if (existing == null) {
      return apiData;
    }

    final merged = Map<String, dynamic>.from(existing.toJson());
    // API may return snake/camel mixed keys; just override matching fields.
    apiData.forEach((key, value) {
      merged[key] = value;
    });
    return merged;
  }

  @override
  Future<ServiceRequest> getServiceRequestById(String id) async {
    try {
      final response = await apiService.get('/api/service-requests/$id');
      if (response.data['success'] == true) {
        return ServiceRequest.fromJson(_transformRequestJson(response.data['data']));
      }
      throw Exception('Failed to load service request');
    } catch (e) {
      // Try local cache
      final localRequest = _localRequests.where((r) => r.id == id).firstOrNull;
      if (localRequest != null) return localRequest;
      throw Exception(handleError(e));
    }
  }
  
  @override
  Future<ServiceRequest> createServiceRequest(ServiceRequest request) async {
    print('🔍 [HealRepo] Creating service request for: ${request.customerName}');
    try {
      final response = await apiService.post(
        '/api/service-requests',
        data: {
          'customerName': request.customerName,
          'customerPhone': request.customerPhone,
          'serviceName': request.serviceName,
          'serviceCategory': request.serviceCategory,
          'requestedDate': request.requestedDate.toIso8601String(),
          'requestedTime': request.requestedTime,
          'price': request.price,
          'specialInstructions': request.specialInstructions,
          'notes': request.notes,
        },
      );
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service request created via API');
        final newRequest = ServiceRequest.fromJson(_transformRequestJson(response.data['data']));
        _localRequests.insert(0, newRequest);
        return newRequest;
      }
      throw Exception('Failed to create service request');
    } catch (e) {
      print('! [HealRepo] API not available, creating request locally: ${handleError(e)}');
      
      // Create request with unique ID and add to local storage
      final newRequest = request.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );
      
      _localRequests.insert(0, newRequest);
      print('✅ [HealRepo] Service request created locally: ${newRequest.id}');
      
      return newRequest;
    }
  }

  @override
  Future<ServiceRequest> updateRequestStatus(String id, RequestStatus status) async {
    print('🔍 [HealRepo] Updating request status: $id to ${status.name}');
    try {
      final response = await apiService.put(
        '/api/service-requests/$id/status',
        data: {'status': status.name},
      );
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Request status updated via API');
        final mergedJson = _mergeWithExisting(id, response.data['data']);
        final updatedRequest = ServiceRequest.fromJson(_transformRequestJson(mergedJson));
        // Update local cache
        final index = _localRequests.indexWhere((r) => r.id == id);
        if (index != -1) _localRequests[index] = updatedRequest;
        return updatedRequest;
      }
      throw Exception('Failed to update request status');
    } catch (e) {
      print('! [HealRepo] API not available, updating request locally: ${handleError(e)}');
      
      // Update in local storage
      final index = _localRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Set startedAt when changing to inProgress
        final updatedRequest = _localRequests[index].copyWith(
          status: status,
          startedAt: status == RequestStatus.inProgress 
              ? (_localRequests[index].startedAt ?? DateTime.now())
              : _localRequests[index].startedAt,
          completedAt: status == RequestStatus.completed ? DateTime.now() : _localRequests[index].completedAt,
          cancelledAt: status == RequestStatus.cancelled ? DateTime.now() : _localRequests[index].cancelledAt,
        );
        _localRequests[index] = updatedRequest;
        print('✅ [HealRepo] Request status updated locally: $id → ${status.name}');
        if (status == RequestStatus.inProgress) {
          print('   ⏱️ Started at: ${updatedRequest.startedAt}');
        }
        return updatedRequest;
      }
      
      // If not found in local requests, try to find it in dummy data and add it
      print('⚠️ [HealRepo] Request $id not found in local storage');
      final dummyRequests = _generateDummyRequests();
      final dummyRequest = dummyRequests.where((r) => r.id == id).firstOrNull;
      
      if (dummyRequest != null) {
        print('✅ [HealRepo] Found request in dummy data, updating and adding to local storage');
        final updatedRequest = dummyRequest.copyWith(
          status: status,
          startedAt: status == RequestStatus.inProgress ? DateTime.now() : null,
        );
        _localRequests.add(updatedRequest);
        if (status == RequestStatus.inProgress) {
          print('   ⏱️ Started at: ${updatedRequest.startedAt}');
        }
        return updatedRequest;
      }
      
      // Last resort: throw error (should not happen with the new logic)
      print('❌ [HealRepo] Request $id not found anywhere');
      throw Exception('Service request not found');
    }
  }

  @override
  Future<ServiceRequest> addRequestNotes(String id, String notes) async {
    try {
      final response = await apiService.put(
        '/api/service-requests/$id/notes',
        data: {'notes': notes},
      );
      if (response.data['success'] == true) {
        final mergedJson = _mergeWithExisting(id, response.data['data']);
        final updatedRequest = ServiceRequest.fromJson(_transformRequestJson(mergedJson));
        // Update local cache
        final index = _localRequests.indexWhere((r) => r.id == id);
        if (index != -1) _localRequests[index] = updatedRequest;
        return updatedRequest;
      }
      throw Exception('Failed to add notes');
    } catch (e) {
      // Update locally
      final index = _localRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updatedRequest = _localRequests[index].copyWith(notes: notes);
        _localRequests[index] = updatedRequest;
        return updatedRequest;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> cancelRequest(String id) async {
    try {
      final response = await apiService.delete('/api/service-requests/$id');
      if (response.data['success'] != true) {
        throw Exception('Failed to cancel request');
      }
      // Remove from local cache
      _localRequests.removeWhere((r) => r.id == id);
    } catch (e) {
      // Remove locally
      _localRequests.removeWhere((r) => r.id == id);
    }
  }

  @override
  Future<Map<String, dynamic>> getServiceStatistics() async {
    try {
      final response = await apiService.get('/api/service-requests/stats/summary');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Failed to load statistics');
    } catch (e) {
      // Return local statistics
      final stats = {
        'statusBreakdown': {
          'pending': _localRequests.where((r) => r.status == RequestStatus.pending).length,
          'confirmed': _localRequests.where((r) => r.status == RequestStatus.confirmed).length,
          'inProgress': _localRequests.where((r) => r.status == RequestStatus.inProgress).length,
          'completed': _localRequests.where((r) => r.status == RequestStatus.completed).length,
          'cancelled': _localRequests.where((r) => r.status == RequestStatus.cancelled).length,
          'total': _localRequests.length,
        },
        'todaysCount': 0,
        'totalEarnings': _localRequests
            .where((r) => r.status == RequestStatus.completed)
            .fold<double>(0.0, (sum, r) => sum + r.price),
        'completedCount': _localRequests.where((r) => r.status == RequestStatus.completed).length,
      };
      return stats;
    }
  }

  // Generate dummy services for offline mode
  List<ServiceModel> _generateDummyServices() {
    return [
      ServiceModel(
        id: '1',
        name: 'Ganpati Pooja',
        description: 'Complete Ganesh Pooja with all rituals and mantras',
        category: 'e_pooja',
        price: 1500.0,
        duration: '2 hours',
        requirements: 'Clean space, pooja items, fresh flowers',
        benefits: ['Removes obstacles', 'Brings prosperity', 'Success in ventures'],
        isActive: true,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ServiceModel(
        id: '2',
        name: 'Reiki Level 1 Healing',
        description: 'Basic Reiki energy healing session for beginners',
        category: 'reiki_healing',
        price: 2500.0,
        duration: '1.5 hours',
        requirements: 'Comfortable clothing, open mind',
        benefits: ['Stress relief', 'Energy balancing', 'Emotional healing'],
        isActive: true,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: '3',
        name: 'Evil Eye Protection',
        description: 'Complete protection from negative energies and evil eye',
        category: 'evil_eye_removal',
        price: 800.0,
        duration: '45 minutes',
        requirements: 'Personal items, photo if possible',
        benefits: ['Protection from negativity', 'Mental peace', 'Aura cleansing'],
        isActive: true,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ServiceModel(
        id: '4',
        name: 'Home Vastu Consultation',
        description: 'Complete home analysis and Vastu remedies',
        category: 'vastu_shastra',
        price: 5000.0,
        duration: '3 hours',
        requirements: 'House plan, photos of rooms',
        benefits: ['Positive energy flow', 'Better health', 'Financial prosperity'],
        isActive: false,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ServiceModel(
        id: '5',
        name: 'Ruby Gemstone Consultation',
        description: 'Personalized gemstone recommendation and charging',
        category: 'gemstone_consultation',
        price: 3000.0,
        duration: '1 hour',
        requirements: 'Birth chart, personal details',
        benefits: ['Career growth', 'Confidence boost', 'Leadership qualities'],
        isActive: true,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: '6',
        name: 'Shri Yantra Setup',
        description: 'Sacred geometry Yantra installation and activation',
        category: 'yantra',
        price: 4000.0,
        duration: '2.5 hours',
        requirements: 'Clean space, specific direction',
        benefits: ['Manifestation power', 'Spiritual growth', 'Abundance'],
        isActive: true,
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Generate dummy service requests for offline mode
  List<ServiceRequest> _generateDummyRequests() {
    return [
      ServiceRequest(
        id: '1',
        customerName: 'Priya Sharma',
        customerPhone: '+91 98765 43210',
        serviceName: 'Ganpati Pooja',
        serviceCategory: 'E-Pooja',
        requestedDate: DateTime.now().add(const Duration(days: 2)),
        requestedTime: '10:00 AM',
        status: RequestStatus.pending,
        price: 1500.0,
        specialInstructions: 'Please perform the pooja in the morning. I have all the required items ready.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ServiceRequest(
        id: '2',
        customerName: 'Rajesh Kumar',
        customerPhone: '+91 87654 32109',
        serviceName: 'Reiki Level 1 Healing',
        serviceCategory: 'Reiki Healing',
        requestedDate: DateTime.now().add(const Duration(days: 1)),
        requestedTime: '3:00 PM',
        status: RequestStatus.confirmed,
        price: 2500.0,
        specialInstructions: 'First time trying Reiki. Please explain the process.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ServiceRequest(
        id: '3',
        customerName: 'Sneha Patel',
        customerPhone: '+91 76543 21098',
        serviceName: 'Evil Eye Protection',
        serviceCategory: 'Evil Eye Removal',
        requestedDate: DateTime.now(),
        requestedTime: '11:00 AM',
        status: RequestStatus.inProgress,
        price: 800.0,
        specialInstructions: 'Urgent - feeling very negative energy lately.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ServiceRequest(
        id: '4',
        customerName: 'Amit Singh',
        customerPhone: '+91 65432 10987',
        serviceName: 'Home Vastu Consultation',
        serviceCategory: 'Vastu Shastra',
        requestedDate: DateTime.now().add(const Duration(days: 3)),
        requestedTime: '2:00 PM',
        status: RequestStatus.completed,
        price: 5000.0,
        specialInstructions: 'New house, need complete Vastu analysis.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ServiceRequest(
        id: '5',
        customerName: 'Meera Joshi',
        customerPhone: '+91 54321 09876',
        serviceName: 'Ruby Gemstone Consultation',
        serviceCategory: 'Gemstone Consultation',
        requestedDate: DateTime.now().add(const Duration(days: 5)),
        requestedTime: '4:00 PM',
        status: RequestStatus.cancelled,
        price: 3000.0,
        specialInstructions: 'Looking for career growth gemstone.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<String> _getAstrologerId() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('Astrologer ID not found');
  }

  // ============================================================================
  // PERSISTENT CACHE HELPERS (survives app restart)
  // ============================================================================

  Future<void> _cacheServices(List<ServiceModel> services) async {
    try {
      final jsonString = jsonEncode(
        services.map((s) => s.toJson()).toList(),
      );
      await storageService.setString('heal_services_cache', jsonString);
      print('💾 [HealRepo] Saved ${services.length} services to persistent cache');
    } catch (e) {
      print('⚠️ [HealRepo] Error caching services: $e');
    }
  }

  Future<void> _cacheRequests(List<ServiceRequest> requests) async {
    try {
      final jsonString = jsonEncode(
        requests.map((r) => r.toJson()).toList(),
      );
      await storageService.setString('heal_requests_cache', jsonString);
      print('💾 [HealRepo] Saved ${requests.length} requests to persistent cache');
    } catch (e) {
      print('⚠️ [HealRepo] Error caching requests: $e');
    }
  }
}


