import '../../../features/consultations/models/consultation_model.dart';

/// Consultations Repository Interface
/// Handles all consultation-related data operations
/// 
/// This abstraction allows us to:
/// - Switch between different data sources (API, local DB, mock)
/// - Test ConsultationsBloc without real API calls
/// - Keep business logic separate from data logic
abstract class ConsultationsRepository {
  /// Get all consultations for the current astrologer
  /// Optional filters: status, type, date range, pagination, sorting
  Future<List<ConsultationModel>> getConsultations({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get a single consultation by ID
  Future<ConsultationModel> getConsultationById(String consultationId);

  /// Add a new consultation
  Future<ConsultationModel> addConsultation(ConsultationModel consultation);

  /// Update an existing consultation
  Future<ConsultationModel> updateConsultation(ConsultationModel consultation);

  /// Delete a consultation by ID
  Future<bool> deleteConsultation(String consultationId);

  /// Update consultation status (scheduled, in-progress, completed, cancelled)
  Future<ConsultationModel> updateConsultationStatus(
    String consultationId,
    ConsultationStatus newStatus, {
    String? notes,
    String? cancelledBy,
    String? cancellationReason,
  });

  /// Complete a consultation with notes
  Future<ConsultationModel> completeConsultation(
    String consultationId,
    String? notes,
  );

  /// Add notes to a consultation
  Future<ConsultationModel> addConsultationNotes(
    String consultationId,
    String notes,
  );

  /// Add rating to a consultation
  Future<ConsultationModel> addConsultationRating(
    String consultationId,
    double rating,
    String? feedback,
  );

  /// Get consultation analytics
  Future<Map<String, dynamic>> getConsultationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get cached consultations (for offline access)
  Future<List<ConsultationModel>?> getCachedConsultations();

  /// Cache consultations for offline access
  Future<void> cacheConsultations(List<ConsultationModel> consultations);

  /// Clear cached consultations
  Future<void> clearCache();

  /// Get instant data synchronously from in-memory or persistent cache
  /// Used for instant loading (stale-while-revalidate pattern)
  /// Returns empty list if no cache available
  List<ConsultationModel> getInstantData();
}

