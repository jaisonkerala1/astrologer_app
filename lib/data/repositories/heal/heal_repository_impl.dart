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

  @override
  Future<List<ServiceModel>> getServices({String? category}) async {
    print('🔍 [HealRepo] Loading services, category: ${category ?? "all"}');
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/services/$astrologerId',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final services = data.map((json) => ServiceModel.fromJson(json)).toList();
        print('✅ [HealRepo] Got ${services.length} services from API');
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

  @override
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await apiService.get('/api/services/detail/$id');
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load service');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ServiceModel> createService(ServiceModel service) async {
    print('🔍 [HealRepo] Creating service: ${service.name}');
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/services',
        data: {...service.toJson(), 'astrologerId': astrologerId},
      );
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service created via API');
        return ServiceModel.fromJson(response.data['data']);
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
        return ServiceModel.fromJson(response.data['data']);
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
      final response = await apiService.patch('/api/services/$id/status', data: {'isActive': isActive});
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Service status toggled via API');
        return ServiceModel.fromJson(response.data['data']);
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
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/service-requests/$astrologerId',
        queryParameters: status != null ? {'status': status.name} : null,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final requests = data.map((json) => ServiceRequest.fromJson(json)).toList();
        print('✅ [HealRepo] Got ${requests.length} requests from API');
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
      
      final allRequests = [..._localRequests, ...dummyRequests];
      
      // Apply status filter if needed
      if (status != null) {
        final filtered = allRequests.where((r) => r.status == status).toList();
        print('✅ [HealRepo] Returning ${filtered.length} filtered requests (status: ${status.name})');
        return filtered;
      }
      
      print('✅ [HealRepo] Returning ${allRequests.length} total requests (${_localRequests.length} local + ${dummyRequests.length} dummy)');
      return allRequests;
    }
  }

  @override
  Future<ServiceRequest> getServiceRequestById(String id) async {
    try {
      final response = await apiService.get('/api/service-requests/detail/$id');
      if (response.data['success'] == true) {
        return ServiceRequest.fromJson(response.data['data']);
      }
      throw Exception('Failed to load service request');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ServiceRequest> updateRequestStatus(String id, RequestStatus status) async {
    print('🔍 [HealRepo] Updating request status: $id to ${status.name}');
    try {
      final response = await apiService.patch('/api/service-requests/$id/status', data: {'status': status.name});
      if (response.data['success'] == true) {
        print('✅ [HealRepo] Request status updated via API');
        return ServiceRequest.fromJson(response.data['data']);
      }
      throw Exception('Failed to update request status');
    } catch (e) {
      print('! [HealRepo] API not available, updating request locally: ${handleError(e)}');
      
      // Update in local storage
      final index = _localRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updatedRequest = _localRequests[index].copyWith(status: status);
        _localRequests[index] = updatedRequest;
        print('✅ [HealRepo] Request status updated locally: $id');
        return updatedRequest;
      }
      
      throw Exception('Request not found');
    }
  }

  @override
  Future<ServiceRequest> addRequestNotes(String id, String notes) async {
    try {
      final response = await apiService.patch('/api/service-requests/$id/notes', data: {'notes': notes});
      if (response.data['success'] == true) {
        return ServiceRequest.fromJson(response.data['data']);
      }
      throw Exception('Failed to add notes');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> cancelRequest(String id) async {
    try {
      final response = await apiService.patch('/api/service-requests/$id/cancel');
      if (response.data['success'] != true) {
        throw Exception('Failed to cancel request');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getServiceStatistics() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get('/api/services/$astrologerId/statistics');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Failed to load statistics');
    } catch (e) {
      throw Exception(handleError(e));
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
}


