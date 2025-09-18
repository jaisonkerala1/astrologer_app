import '../../../core/services/api_service.dart';
import '../models/consultation_model.dart';

class ConsultationsService {
  final ApiService _apiService = ApiService();

  Future<List<ConsultationModel>> getConsultations() async {
    // For MVP: Use mock data instead of API calls to avoid network issues
    return _getMockConsultations();
  }

  Future<ConsultationModel> updateConsultationStatus(
    String consultationId,
    ConsultationStatus newStatus,
  ) async {
    // For MVP: Simulate status update
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find and update the consultation in mock data
    final consultations = _getMockConsultations();
    final consultation = consultations.firstWhere(
      (c) => c.id == consultationId,
      orElse: () => throw Exception('Consultation not found'),
    );
    
    return consultation.copyWith(
      status: newStatus,
      completedAt: newStatus == ConsultationStatus.completed ? DateTime.now() : null,
    );
  }

  Future<void> addConsultation(ConsultationModel consultation) async {
    // For MVP: Simulate adding consultation
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would save to backend
  }

  Future<void> completeConsultation(String consultationId, String? notes) async {
    // For MVP: Simulate completing consultation
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update backend with completion data
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