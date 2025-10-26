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

  HealRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<List<ServiceModel>> getServices({String? category}) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/services/$astrologerId',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ServiceModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load services');
    } catch (e) {
      throw Exception(handleError(e));
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
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/services',
        data: {...service.toJson(), 'astrologerId': astrologerId},
      );
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to create service');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ServiceModel> updateService(String id, ServiceModel service) async {
    try {
      final response = await apiService.put('/api/services/$id', data: service.toJson());
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update service');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> deleteService(String id) async {
    try {
      final response = await apiService.delete('/api/services/$id');
      if (response.data['success'] != true) {
        throw Exception('Failed to delete service');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ServiceModel> toggleServiceStatus(String id, bool isActive) async {
    try {
      final response = await apiService.patch('/api/services/$id/status', data: {'isActive': isActive});
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to toggle service status');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<ServiceRequest>> getServiceRequests({RequestStatus? status}) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/service-requests/$astrologerId',
        queryParameters: status != null ? {'status': status.name} : null,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ServiceRequest.fromJson(json)).toList();
      }
      throw Exception('Failed to load service requests');
    } catch (e) {
      throw Exception(handleError(e));
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
    try {
      final response = await apiService.patch('/api/service-requests/$id/status', data: {'status': status.name});
      if (response.data['success'] == true) {
        return ServiceRequest.fromJson(response.data['data']);
      }
      throw Exception('Failed to update request status');
    } catch (e) {
      throw Exception(handleError(e));
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


