import 'dart:convert';
import 'dart:typed_data';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/consultation_model.dart';

class ConsultationsService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  static List<ConsultationModel> _consultations = [];
  
  // In-memory cache for analytics data
  static Map<String, dynamic>? _weeklyStatsCache;
  static Map<String, dynamic>? _monthlyStatsCache;
  static Map<String, dynamic>? _allTimeStatsCache;
  static List<ConsultationModel>? _weeklyConsultationsCache;
  static List<ConsultationModel>? _monthlyConsultationsCache;
  static List<ConsultationModel>? _allTimeConsultationsCache;
  
  // Get astrologer ID from stored user data or JWT token
  Future<String> _getAstrologerId() async {
    try {
      // First try to get from stored user data
      final userData = await _storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        // Try both 'id' and '_id' fields
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          print('Using astrologer ID from storage: $astrologerId');
          return astrologerId;
        }
      }
      
      // If no user data, try to get from JWT token
      final token = await _storageService.getAuthToken();
      if (token != null) {
        final astrologerId = _extractAstrologerIdFromToken(token);
        if (astrologerId != null) {
          print('Using astrologer ID from JWT token: $astrologerId');
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('No user data found. Please login again.');
  }
  
  // Extract astrologer ID from JWT token
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

      final response = await _apiService.get(
        '/api/consultation/$astrologerId',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final consultationsData = response.data['data']['consultations'] as List;
        _consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        return _consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } catch (e) {
      print('Error fetching consultations: $e');
      // Fallback to mock data for development
    if (_consultations.isEmpty) {
      _consultations = _getMockConsultations();
    }
    return _consultations;
    }
  }

  Future<ConsultationModel> updateConsultationStatus(
    String consultationId,
    ConsultationStatus newStatus, {
    String? notes,
    String? cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      print('Updating consultation $consultationId to status: ${newStatus.toString().split('.').last}');
      
      final updateData = {
        'status': newStatus.toString().split('.').last,
        if (notes != null) 'notes': notes,
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
      };

      // Add startedAt timestamp when starting consultation
      if (newStatus == ConsultationStatus.inProgress) {
        updateData['startedAt'] = DateTime.now().toIso8601String();
        print('Adding startedAt timestamp: ${updateData['startedAt']}');
      }
      
      final response = await _apiService.patch(
        '/api/consultation/status/$consultationId',
        data: updateData,
      );

      print('API Response: ${response.data}');

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
          print('Updated consultation in local cache: ${updatedConsultation.status.displayName}');
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update consultation status');
      }
    } catch (e) {
      print('Error updating consultation status: $e');
      // Fallback to local update for development
      final consultationIndex = _consultations.indexWhere(
        (c) => c.id == consultationId,
      );
      
      if (consultationIndex == -1) {
        throw Exception('Consultation not found');
      }
      
      final updatedConsultation = _consultations[consultationIndex].copyWith(
        status: newStatus,
        startedAt: newStatus == ConsultationStatus.inProgress ? DateTime.now() : _consultations[consultationIndex].startedAt,
        completedAt: newStatus == ConsultationStatus.completed ? DateTime.now() : null,
        cancelledAt: newStatus == ConsultationStatus.cancelled ? DateTime.now() : null,
        notes: notes ?? _consultations[consultationIndex].notes,
      );
      
      _consultations[consultationIndex] = updatedConsultation;
      print('Updated consultation locally: ${updatedConsultation.status.displayName}');
      return updatedConsultation;
    }
  }

  Future<ConsultationModel> addConsultation(ConsultationModel consultation) async {
    try {
      print('Creating consultation for: ${consultation.clientName}');
      final astrologerId = await _getAstrologerId();
      print('Astrologer ID: $astrologerId');
      print('Consultation data: ${consultation.toJson()}');
      
      final response = await _apiService.post(
        '/api/consultation/$astrologerId',
        data: consultation.toJson(),
      );

      print('API Response: ${response.data}');

      if (response.data['success'] == true) {
        final createdConsultation = ConsultationModel.fromJson(response.data['data']);
        _consultations.add(createdConsultation);
        print('Consultation added to local cache: ${createdConsultation.clientName}');
        return createdConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create consultation');
      }
    } catch (e) {
      print('Error creating consultation: $e');
      // Fallback to local addition for development
      final newConsultation = consultation.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );
      _consultations.add(newConsultation);
      print('Added consultation locally as fallback: ${newConsultation.clientName}');
      return newConsultation;
    }
  }

  Future<ConsultationModel> completeConsultation(String consultationId, String? notes) async {
    return await updateConsultationStatus(
      consultationId,
      ConsultationStatus.completed,
      notes: notes,
    );
  }

  Future<ConsultationModel> updateConsultation(ConsultationModel consultation) async {
    try {
      final response = await _apiService.put(
        '/api/consultation/${consultation.id}',
        data: consultation.toJson(),
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultation.id,
        );
        if (consultationIndex != -1) {
    _consultations[consultationIndex] = updatedConsultation;
        }
    
    return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update consultation');
      }
    } catch (e) {
      print('Error updating consultation: $e');
      // Fallback to local update for development
      final consultationIndex = _consultations.indexWhere(
        (c) => c.id == consultation.id,
      );
      
      if (consultationIndex != -1) {
        _consultations[consultationIndex] = consultation;
      }
      return consultation;
    }
  }

  Future<void> deleteConsultation(String consultationId) async {
    try {
      final response = await _apiService.delete('/api/consultation/$consultationId');

      if (response.data['success'] == true) {
        // Remove from local cache
        _consultations.removeWhere((c) => c.id == consultationId);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete consultation');
      }
    } catch (e) {
      print('Error deleting consultation: $e');
      // Fallback to local deletion for development
      _consultations.removeWhere((c) => c.id == consultationId);
      throw Exception('Failed to delete consultation: $e');
    }
  }

  Future<List<ConsultationModel>> getUpcomingConsultations({int limit = 10}) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get(
        '/api/consultation/upcoming/$astrologerId',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.data['success'] == true) {
        final consultationsData = response.data['data'] as List;
        return consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch upcoming consultations');
      }
    } catch (e) {
      print('Error fetching upcoming consultations: $e');
      // Return upcoming consultations from local cache
      final now = DateTime.now();
      return _consultations
          .where((c) => c.scheduledTime.isAfter(now) && 
                       c.status == ConsultationStatus.scheduled)
          .take(limit)
          .toList();
    }
  }

  Future<List<ConsultationModel>> getTodaysConsultations() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/today/$astrologerId');

      if (response.data['success'] == true) {
        final consultationsData = response.data['data'] as List;
        return consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch today\'s consultations');
      }
    } catch (e) {
      print('Error fetching today\'s consultations: $e');
      // Return today's consultations from local cache
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return _consultations
          .where((c) => c.scheduledTime.isAfter(startOfDay) && 
                       c.scheduledTime.isBefore(endOfDay))
          .toList();
    }
  }

  Future<Map<String, dynamic>> getConsultationStats() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/stats/$astrologerId');

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch consultation stats');
      }
    } catch (e) {
      print('Error fetching consultation stats: $e');
      // Return mock stats
      return {
        'totalEarnings': 0.0,
        'stats': [
          {'_id': 'scheduled', 'count': 0, 'totalAmount': 0},
          {'_id': 'completed', 'count': 0, 'totalAmount': 0},
          {'_id': 'cancelled', 'count': 0, 'totalAmount': 0},
        ]
      };
    }
  }

  Future<Map<String, dynamic>> getWeeklyConsultationStats() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/stats/$astrologerId/weekly');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        // Cache the data
        _weeklyStatsCache = data;
        await _storageService.setString('analytics_weekly_stats', jsonEncode(data));
        print('💾 [ConsultationsService] Cached weekly stats');
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch weekly consultation stats');
      }
    } catch (e) {
      print('Error fetching weekly consultation stats: $e');
      // Return mock weekly stats
      return {
        'totalConsultations': 0,
        'totalEarnings': 0.0,
        'completedConsultations': 0,
        'cancelledConsultations': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getMonthlyConsultationStats() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/stats/$astrologerId/monthly');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        // Cache the data
        _monthlyStatsCache = data;
        await _storageService.setString('analytics_monthly_stats', jsonEncode(data));
        print('💾 [ConsultationsService] Cached monthly stats');
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch monthly consultation stats');
      }
    } catch (e) {
      print('Error fetching monthly consultation stats: $e');
      // Return mock monthly stats
      return {
        'totalConsultations': 0,
        'totalEarnings': 0.0,
        'completedConsultations': 0,
        'cancelledConsultations': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getAllTimeConsultationStats() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/stats/$astrologerId/all-time');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        // Cache the data
        _allTimeStatsCache = data;
        await _storageService.setString('analytics_alltime_stats', jsonEncode(data));
        print('💾 [ConsultationsService] Cached all-time stats');
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch all-time consultation stats');
      }
    } catch (e) {
      print('Error fetching all-time consultation stats: $e');
      // Return mock all-time stats
      return {
        'totalConsultations': 0,
        'totalEarnings': 0.0,
        'completedConsultations': 0,
        'cancelledConsultations': 0,
      };
    }
  }

  Future<List<ConsultationModel>> getWeeklyConsultations() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/weekly/$astrologerId');

      if (response.data['success'] == true) {
        final consultationsData = response.data['data'] as List;
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        // Cache the data
        _weeklyConsultationsCache = consultations;
        await _storageService.setString('analytics_weekly_consultations', 
            jsonEncode(consultations.map((c) => c.toJson()).toList()));
        print('💾 [ConsultationsService] Cached ${consultations.length} weekly consultations');
        return consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch weekly consultations');
      }
    } catch (e) {
      print('Error fetching weekly consultations: $e');
      // Return empty list for development
      return [];
    }
  }

  Future<List<ConsultationModel>> getMonthlyConsultations() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/monthly/$astrologerId');

      if (response.data['success'] == true) {
        final consultationsData = response.data['data'] as List;
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        // Cache the data
        _monthlyConsultationsCache = consultations;
        await _storageService.setString('analytics_monthly_consultations', 
            jsonEncode(consultations.map((c) => c.toJson()).toList()));
        print('💾 [ConsultationsService] Cached ${consultations.length} monthly consultations');
        return consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch monthly consultations');
      }
    } catch (e) {
      print('Error fetching monthly consultations: $e');
      // Return empty list for development
      return [];
    }
  }

  Future<List<ConsultationModel>> getAllTimeConsultations() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.get('/api/consultation/all-time/$astrologerId');

      if (response.data['success'] == true) {
        final consultationsData = response.data['data'] as List;
        final consultations = consultationsData
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
        // Cache the data
        _allTimeConsultationsCache = consultations;
        await _storageService.setString('analytics_alltime_consultations', 
            jsonEncode(consultations.map((c) => c.toJson()).toList()));
        print('💾 [ConsultationsService] Cached ${consultations.length} all-time consultations');
        return consultations;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch all-time consultations');
      }
    } catch (e) {
      print('Error fetching all-time consultations: $e');
      // Return empty list for development
      return [];
    }
  }

  Future<ConsultationModel> addConsultationNotes(String consultationId, String notes) async {
    try {
      final response = await _apiService.patch(
        '/api/consultation/notes/$consultationId',
        data: {'notes': notes},
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add consultation notes');
      }
    } catch (e) {
      print('Error adding consultation notes: $e');
      // Fallback to local update for development
    final consultationIndex = _consultations.indexWhere(
      (c) => c.id == consultationId,
    );
    
    if (consultationIndex != -1) {
        final updatedConsultation = _consultations[consultationIndex].copyWith(notes: notes);
        _consultations[consultationIndex] = updatedConsultation;
        return updatedConsultation;
      }
      throw Exception('Consultation not found');
    }
  }

  Future<ConsultationModel> addConsultationRating(String consultationId, int rating, String? feedback) async {
    try {
      final response = await _apiService.put(
        '/api/consultation/rating/$consultationId',
        data: {
          'rating': rating,
          if (feedback != null) 'feedback': feedback,
        },
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add consultation rating');
      }
    } catch (e) {
      print('Error adding consultation rating: $e');
      throw Exception('Failed to add consultation rating: $e');
    }
  }

  Future<ConsultationModel> addAstrologerRating(String consultationId, int rating, String? feedback) async {
    try {
      print('Adding astrologer rating: $rating stars for consultation $consultationId');
      
      final response = await _apiService.patch(
        '/api/consultation/astrologer-rating/$consultationId',
        data: {
          'astrologerRating': rating,
          if (feedback != null) 'astrologerFeedback': feedback,
        },
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
        }
        
        print('Successfully added astrologer rating: ${updatedConsultation.astrologerRating} stars');
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add astrologer rating');
      }
    } catch (e) {
      print('Error adding astrologer rating: $e');
      throw Exception('Failed to add astrologer rating: $e');
    }
  }

  Future<ConsultationModel> trackConsultationShare(String consultationId) async {
    try {
      print('Tracking share for consultation $consultationId');
      
      final response = await _apiService.patch(
        '/api/consultation/share/$consultationId',
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
        }
        
        print('Successfully tracked share. New count: ${updatedConsultation.shareCount}');
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to track consultation share');
      }
    } catch (e) {
      print('Error tracking consultation share: $e');
      throw Exception('Failed to track consultation share: $e');
    }
  }

  Future<ConsultationModel> rescheduleConsultation(String consultationId, DateTime newScheduledTime) async {
    try {
      print('Rescheduling consultation $consultationId to ${newScheduledTime.toIso8601String()}');
      
      final response = await _apiService.patch(
        '/api/consultation/reschedule/$consultationId',
        data: {
          'scheduledTime': newScheduledTime.toIso8601String(),
          'status': 'scheduled',
        },
      );

      if (response.data['success'] == true) {
        final updatedConsultation = ConsultationModel.fromJson(response.data['data']);
        
        // Update local cache
        final consultationIndex = _consultations.indexWhere(
          (c) => c.id == consultationId,
        );
        if (consultationIndex != -1) {
          _consultations[consultationIndex] = updatedConsultation;
        }
        
        print('Successfully rescheduled consultation to ${updatedConsultation.scheduledTime}');
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to reschedule consultation');
      }
    } catch (e) {
      print('Error rescheduling consultation: $e');
      throw Exception('Failed to reschedule consultation: $e');
    }
  }

  // Mock data for development
  List<ConsultationModel> _getMockConsultations() {
    final now = DateTime.now();
    
    return [
      ConsultationModel(
        id: '1',
        clientName: 'Rajesh Sharma',
        clientPhone: '+91 9876543210',
        scheduledTime: now.add(const Duration(hours: 2)),
        duration: 30,
        amount: 500.0,
        status: ConsultationStatus.scheduled,
        type: ConsultationType.phone,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ConsultationModel(
        id: '2',
        clientName: 'Priya Patel',
        clientPhone: '+91 9876543211',
        scheduledTime: now.add(const Duration(hours: 4)),
        duration: 45,
        amount: 750.0,
        status: ConsultationStatus.scheduled,
        type: ConsultationType.video,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ConsultationModel(
        id: '3',
        clientName: 'Amit Kumar',
        clientPhone: '+91 9876543212',
        scheduledTime: now.subtract(const Duration(hours: 1)),
        duration: 30,
        amount: 500.0,
        status: ConsultationStatus.completed,
        type: ConsultationType.phone,
        notes: 'Discussed career prospects and marriage timing',
        createdAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(hours: 1)),
      ),
      ConsultationModel(
        id: '4',
        clientName: 'Sunita Gupta',
        clientPhone: '+91 9876543213',
        scheduledTime: now.add(const Duration(days: 1, hours: 10)),
        duration: 60,
        amount: 1000.0,
        status: ConsultationStatus.scheduled,
        type: ConsultationType.inPerson,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ConsultationModel(
        id: '5',
        clientName: 'Vikas Singh',
        clientPhone: '+91 9876543214',
        scheduledTime: now.subtract(const Duration(hours: 3)),
        duration: 30,
        amount: 500.0,
        status: ConsultationStatus.completed,
        type: ConsultationType.video,
        notes: 'Health and financial guidance provided',
        createdAt: now.subtract(const Duration(days: 4)),
        completedAt: now.subtract(const Duration(hours: 3)),
      ),
      ConsultationModel(
        id: '6',
        clientName: 'Kavya Menon',
        clientPhone: '+91 9876543215',
        scheduledTime: now.add(const Duration(hours: 6)),
        duration: 30,
        amount: 500.0,
        status: ConsultationStatus.scheduled,
        type: ConsultationType.chat,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }

  // Update consultation by ID with specific fields
  Future<ConsultationModel> updateConsultationById(String consultationId, Map<String, dynamic> updateData) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await _apiService.put(
        '/api/consultation/$consultationId',
        data: updateData,
      );

      if (response.data['success'] == true) {
        final consultationData = response.data['data'];
        final updatedConsultation = ConsultationModel.fromJson(consultationData);
        
        // Update local cache
        final index = _consultations.indexWhere((c) => c.id == consultationId);
        if (index != -1) {
          _consultations[index] = updatedConsultation;
        }
        
        return updatedConsultation;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update consultation');
      }
    } catch (e) {
      print('Error updating consultation: $e');
      rethrow;
    }
  }

  // ============================================================================
  // INSTANT ANALYTICS DATA (Cache-first for WhatsApp/Instagram-style loading)
  // ============================================================================
  
  /// Get analytics data instantly from cache (synchronous)
  /// Returns all analytics data in one call for two-phase loading pattern
  Map<String, dynamic> getInstantAnalyticsData() {
    print('⚡ [ConsultationsService] getInstantAnalyticsData() called');
    
    final result = <String, dynamic>{};
    
    // 1. Try in-memory cache first (fastest)
    if (_weeklyStatsCache != null) {
      result['weeklyStats'] = _weeklyStatsCache;
      print('✅ [ConsultationsService] Weekly stats from memory cache');
    }
    if (_monthlyStatsCache != null) {
      result['monthlyStats'] = _monthlyStatsCache;
      print('✅ [ConsultationsService] Monthly stats from memory cache');
    }
    if (_allTimeStatsCache != null) {
      result['allTimeStats'] = _allTimeStatsCache;
      print('✅ [ConsultationsService] All-time stats from memory cache');
    }
    if (_weeklyConsultationsCache != null) {
      result['weeklyConsultations'] = _weeklyConsultationsCache;
      print('✅ [ConsultationsService] Weekly consultations from memory cache');
    }
    if (_monthlyConsultationsCache != null) {
      result['monthlyConsultations'] = _monthlyConsultationsCache;
      print('✅ [ConsultationsService] Monthly consultations from memory cache');
    }
    if (_allTimeConsultationsCache != null) {
      result['allTimeConsultations'] = _allTimeConsultationsCache;
      print('✅ [ConsultationsService] All-time consultations from memory cache');
    }
    
    // 2. If in-memory cache is incomplete, try persistent storage (still fast)
    if (result.isEmpty || result.length < 6) {
      try {
        // Load weekly stats
        if (!result.containsKey('weeklyStats')) {
          final cached = _storageService.getStringSync('analytics_weekly_stats');
          if (cached != null) {
            result['weeklyStats'] = jsonDecode(cached) as Map<String, dynamic>;
            _weeklyStatsCache = result['weeklyStats'] as Map<String, dynamic>;
            print('✅ [ConsultationsService] Weekly stats from persistent cache');
          }
        }
        
        // Load monthly stats
        if (!result.containsKey('monthlyStats')) {
          final cached = _storageService.getStringSync('analytics_monthly_stats');
          if (cached != null) {
            result['monthlyStats'] = jsonDecode(cached) as Map<String, dynamic>;
            _monthlyStatsCache = result['monthlyStats'] as Map<String, dynamic>;
            print('✅ [ConsultationsService] Monthly stats from persistent cache');
          }
        }
        
        // Load all-time stats
        if (!result.containsKey('allTimeStats')) {
          final cached = _storageService.getStringSync('analytics_alltime_stats');
          if (cached != null) {
            result['allTimeStats'] = jsonDecode(cached) as Map<String, dynamic>;
            _allTimeStatsCache = result['allTimeStats'] as Map<String, dynamic>;
            print('✅ [ConsultationsService] All-time stats from persistent cache');
          }
        }
        
        // Load weekly consultations
        if (!result.containsKey('weeklyConsultations')) {
          final cached = _storageService.getStringSync('analytics_weekly_consultations');
          if (cached != null) {
            final List<dynamic> jsonList = jsonDecode(cached);
            final consultations = jsonList
                .map((json) => ConsultationModel.fromJson(json))
                .toList();
            result['weeklyConsultations'] = consultations;
            _weeklyConsultationsCache = consultations;
            print('✅ [ConsultationsService] Weekly consultations from persistent cache');
          }
        }
        
        // Load monthly consultations
        if (!result.containsKey('monthlyConsultations')) {
          final cached = _storageService.getStringSync('analytics_monthly_consultations');
          if (cached != null) {
            final List<dynamic> jsonList = jsonDecode(cached);
            final consultations = jsonList
                .map((json) => ConsultationModel.fromJson(json))
                .toList();
            result['monthlyConsultations'] = consultations;
            _monthlyConsultationsCache = consultations;
            print('✅ [ConsultationsService] Monthly consultations from persistent cache');
          }
        }
        
        // Load all-time consultations
        if (!result.containsKey('allTimeConsultations')) {
          final cached = _storageService.getStringSync('analytics_alltime_consultations');
          if (cached != null) {
            final List<dynamic> jsonList = jsonDecode(cached);
            final consultations = jsonList
                .map((json) => ConsultationModel.fromJson(json))
                .toList();
            result['allTimeConsultations'] = consultations;
            _allTimeConsultationsCache = consultations;
            print('✅ [ConsultationsService] All-time consultations from persistent cache');
          }
        }
      } catch (e) {
        print('⚠️ [ConsultationsService] Error loading from persistent cache: $e');
      }
    }
    
    if (result.isEmpty) {
      print('⚠️ [ConsultationsService] No cached analytics data available');
    } else {
      print('✅ [ConsultationsService] Returning ${result.length}/6 cached analytics data items');
    }
    
    return result;
  }
}