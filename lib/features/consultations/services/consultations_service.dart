import '../../../core/services/api_service.dart';
import '../models/consultation_model.dart';

class ConsultationsService {
  final ApiService _apiService = ApiService();
  static List<ConsultationModel> _consultations = [];
  static const String _astrologerId = '65f8b2c4d1234567890abcdef'; // This should come from user session

  Future<List<ConsultationModel>> getConsultations({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
    String sortBy = 'scheduledTime',
    String sortOrder = 'asc',
  }) async {
    try {
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
        '/api/consultation/$_astrologerId',
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
      final response = await _apiService.put(
        '/api/consultation/status/$consultationId',
        data: {
          'status': newStatus.toString().split('.').last,
          if (notes != null) 'notes': notes,
          if (cancelledBy != null) 'cancelledBy': cancelledBy,
          if (cancellationReason != null) 'cancellationReason': cancellationReason,
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
      completedAt: newStatus == ConsultationStatus.completed ? DateTime.now() : null,
        notes: notes ?? _consultations[consultationIndex].notes,
      );
      
      _consultations[consultationIndex] = updatedConsultation;
      return updatedConsultation;
    }
  }

  Future<ConsultationModel> addConsultation(ConsultationModel consultation) async {
    try {
      final response = await _apiService.post(
        '/api/consultation/$_astrologerId',
        data: consultation.toJson(),
      );

      if (response.data['success'] == true) {
        final createdConsultation = ConsultationModel.fromJson(response.data['data']);
        _consultations.add(createdConsultation);
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
      final response = await _apiService.get(
        '/api/consultation/upcoming/$_astrologerId',
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
      final response = await _apiService.get('/api/consultation/today/$_astrologerId');

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
      final response = await _apiService.get('/api/consultation/stats/$_astrologerId');

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

  Future<ConsultationModel> addConsultationNotes(String consultationId, String notes) async {
    try {
      final response = await _apiService.put(
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
}