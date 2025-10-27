import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/consultations/models/consultation_model.dart';
import '../base_repository.dart';
import 'consultations_repository.dart';

/// Implementation of ConsultationsRepository
/// Handles consultation data operations using ApiService and StorageService
class ConsultationsRepositoryImpl extends BaseRepository implements ConsultationsRepository {
  final ApiService apiService;
  final StorageService storageService;

  ConsultationsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  /// Get astrologer ID from stored user data or JWT token
  Future<String> _getAstrologerId() async {
    try {
      // First try to get from stored user data
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        // Try both 'id' and '_id' fields
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          return astrologerId;
        }
      }
      
      // If no user data, try to get from JWT token
      final token = await storageService.getAuthToken();
      if (token != null) {
        final astrologerId = _extractAstrologerIdFromToken(token);
        if (astrologerId != null) {
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('No user data found. Please login again.');
  }
  
  /// Extract astrologer ID from JWT token
  String? _extractAstrologerIdFromToken(String token) {
    try {
      // JWT tokens have 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (middle part)
      final payload = parts[1];
      
      // Add padding if needed
      final paddedPayload = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
      
      // Decode base64
      final decodedBytes = base64Url.decode(paddedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      // Parse JSON
      final payloadMap = jsonDecode(decodedString);
      
      // Extract astrologer ID
      return payloadMap['astrologerId'] as String?;
    } catch (e) {
      print('Error extracting astrologer ID from token: $e');
      return null;
    }
  }

  @override
  Future<List<ConsultationModel>> getConsultations({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final astrologerId = await _getAstrologerId();
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await apiService.get(
        '/api/consultation/$astrologerId',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final consultationsData = response.data['data']['consultations'] as List;
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        
        // Cache for offline access
        await cacheConsultations(consultations);
        
        return consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } catch (e) {
      // Try to return cached data if API fails
      final cachedConsultations = await getCachedConsultations();
      if (cachedConsultations != null) {
        print('ConsultationsRepository: Using cached data due to error: $e');
        return cachedConsultations;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> getConsultationById(String consultationId) async {
    try {
      final response = await apiService.get('/api/consultation/details/$consultationId');

      if (response.data['success'] == true) {
        return ConsultationModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultation details');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> addConsultation(ConsultationModel consultation) async {
    try {
      final astrologerId = await _getAstrologerId();
      
      final response = await apiService.post(
        '/api/consultation/$astrologerId',
        data: consultation.toJson(),
      );

      if (response.data['success'] == true) {
        final createdConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update cache
        final cached = await getCachedConsultations();
        if (cached != null) {
          cached.add(createdConsultation);
          await cacheConsultations(cached);
        }
        
        return createdConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create consultation');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> updateConsultation(ConsultationModel consultation) async {
    try {
      final response = await apiService.put(
        '/api/consultation/${consultation.id}',
        data: consultation.toJson(),
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update cache
        final cached = await getCachedConsultations();
        if (cached != null) {
          final index = cached.indexWhere((c) => c.id == consultation.id);
          if (index != -1) {
            cached[index] = updatedConsultation;
            await cacheConsultations(cached);
          }
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update consultation');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<bool> deleteConsultation(String consultationId) async {
    try {
      final response = await apiService.delete('/api/consultation/$consultationId');

      if (response.data['success'] == true) {
        // Update cache
        final cached = await getCachedConsultations();
        if (cached != null) {
          cached.removeWhere((c) => c.id == consultationId);
          await cacheConsultations(cached);
        }
        
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete consultation');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> updateConsultationStatus(
    String consultationId,
    ConsultationStatus newStatus, {
    String? notes,
    String? cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      final updateData = {
        'status': newStatus.toString().split('.').last,
        if (notes != null) 'notes': notes,
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
      };

      // Add startedAt timestamp when starting consultation
      if (newStatus == ConsultationStatus.inProgress) {
        updateData['startedAt'] = DateTime.now().toIso8601String();
      }
      
      final response = await apiService.patch(
        '/api/consultation/status/$consultationId',
        data: updateData,
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update cache
        final cached = await getCachedConsultations();
        if (cached != null) {
          final index = cached.indexWhere((c) => c.id == consultationId);
          if (index != -1) {
            cached[index] = updatedConsultation;
            await cacheConsultations(cached);
          }
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update consultation status');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> completeConsultation(
    String consultationId,
    String? notes,
  ) async {
    try {
      // Use the status endpoint instead of non-existent complete endpoint
      final response = await apiService.patch(
        '/api/consultation/status/$consultationId',
        data: {
          'status': 'completed',
          'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        return ConsultationModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to complete consultation');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> addConsultationNotes(
    String consultationId,
    String notes,
  ) async {
    try {
      final response = await apiService.patch(
        '/api/consultation/notes/$consultationId',
        data: {'notes': notes},
      );

      if (response.data['success'] == true) {
        return ConsultationModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add notes');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<ConsultationModel> addConsultationRating(
    String consultationId,
    double rating,
    String? feedback,
  ) async {
    try {
      final response = await apiService.patch(
        '/api/consultation/rating/$consultationId',
        data: {
          'rating': rating,
          'feedback': feedback,
        },
      );

      if (response.data['success'] == true) {
        return ConsultationModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add rating');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getConsultationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final astrologerId = await _getAstrologerId();
      final queryParams = <String, dynamic>{};

      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await apiService.get(
        '/api/consultation/analytics/$astrologerId',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch analytics');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<ConsultationModel>?> getCachedConsultations() async {
    try {
      final cachedData = await storageService.getString('consultations_cache');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => ConsultationModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print('Error getting cached consultations: $e');
      return null;
    }
  }

  @override
  Future<void> cacheConsultations(List<ConsultationModel> consultations) async {
    try {
      final jsonList = consultations.map((c) => c.toJson()).toList();
      await storageService.setString('consultations_cache', jsonEncode(jsonList));
    } catch (e) {
      print('Error caching consultations: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('consultations_cache');
    } catch (e) {
      print('Error clearing consultations cache: $e');
    }
  }
}

