import '../../../features/heal/models/service_model.dart';
import '../../../features/heal/models/service_request_model.dart';

/// Abstract interface for Heal/Service Centre operations
abstract class HealRepository {
  // Instant Data (WhatsApp/Instagram-style instant load)
  Map<String, dynamic> getInstantData();
  
  // Services Management
  Future<List<ServiceModel>> getServices({String? category});
  Future<ServiceModel> getServiceById(String id);
  Future<ServiceModel> createService(ServiceModel service);
  Future<ServiceModel> updateService(String id, ServiceModel service);
  Future<void> deleteService(String id);
  Future<ServiceModel> toggleServiceStatus(String id, bool isActive);
  
  // Service Requests Management
  Future<List<ServiceRequest>> getServiceRequests({RequestStatus? status});
  Future<ServiceRequest> getServiceRequestById(String id);
  Future<ServiceRequest> createServiceRequest(ServiceRequest request);
  Future<ServiceRequest> updateRequestStatus(String id, RequestStatus status);
  Future<ServiceRequest> addRequestNotes(String id, String notes);
  Future<void> cancelRequest(String id);
  
  // Statistics
  Future<Map<String, dynamic>> getServiceStatistics();
}


