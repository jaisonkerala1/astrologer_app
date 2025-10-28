import 'package:equatable/equatable.dart';
import '../models/consultation_model.dart';

abstract class ConsultationsState extends Equatable {
  const ConsultationsState();

  @override
  List<Object?> get props => [];
}

class ConsultationsInitial extends ConsultationsState {
  const ConsultationsInitial();
}

class ConsultationsLoading extends ConsultationsState {
  final bool isInitialLoad;
  
  const ConsultationsLoading({this.isInitialLoad = true});
  
  @override
  List<Object?> get props => [isInitialLoad];
}

class ConsultationsLoaded extends ConsultationsState {
  final List<ConsultationModel> allConsultations; // Original data
  final List<ConsultationModel> consultations; // Filtered data
  final List<ConsultationModel> todayConsultations;
  final List<ConsultationModel> upcomingConsultations;
  final List<ConsultationModel> completedConsultations;
  final ConsultationStatus? activeFilter;
  final DateTime? dateFilter;
  final String searchQuery;
  final bool isSearching;
  final bool isRefreshing; // For instant loading (stale-while-revalidate)

  const ConsultationsLoaded({
    required this.allConsultations,
    required this.consultations,
    required this.todayConsultations,
    required this.upcomingConsultations,
    required this.completedConsultations,
    this.activeFilter,
    this.dateFilter,
    this.searchQuery = '',
    this.isSearching = false,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        allConsultations,
        consultations,
        todayConsultations,
        upcomingConsultations,
        completedConsultations,
        activeFilter,
        dateFilter,
        searchQuery,
        isSearching,
        isRefreshing,
      ];

  ConsultationsLoaded copyWith({
    List<ConsultationModel>? allConsultations,
    List<ConsultationModel>? consultations,
    List<ConsultationModel>? todayConsultations,
    List<ConsultationModel>? upcomingConsultations,
    List<ConsultationModel>? completedConsultations,
    ConsultationStatus? activeFilter,
    DateTime? dateFilter,
    String? searchQuery,
    bool? isSearching,
    bool? isRefreshing,
    bool clearFilters = false,
  }) {
    return ConsultationsLoaded(
      allConsultations: allConsultations ?? this.allConsultations,
      consultations: consultations ?? this.consultations,
      todayConsultations: todayConsultations ?? this.todayConsultations,
      upcomingConsultations: upcomingConsultations ?? this.upcomingConsultations,
      completedConsultations: completedConsultations ?? this.completedConsultations,
      activeFilter: clearFilters ? null : (activeFilter ?? this.activeFilter),
      dateFilter: clearFilters ? null : (dateFilter ?? this.dateFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Stats methods
  int get totalConsultations => consultations.length;
  
  int get todayCount => todayConsultations.length;
  
  int get completedCount => completedConsultations.length;
  
  double get todayEarnings => todayConsultations
      .where((c) => c.status == ConsultationStatus.completed)
      .fold(0.0, (sum, consultation) => sum + consultation.amount);
  
  double get totalEarnings => completedConsultations
      .fold(0.0, (sum, consultation) => sum + consultation.amount);

  ConsultationModel? get nextConsultation {
    final upcoming = upcomingConsultations
        .where((c) => c.status == ConsultationStatus.scheduled)
        .toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return upcoming.first;
  }
}

class ConsultationsError extends ConsultationsState {
  final String message;

  const ConsultationsError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class ConsultationUpdating extends ConsultationsState {
  final String consultationId;

  const ConsultationUpdating({
    required this.consultationId,
  });

  @override
  List<Object?> get props => [consultationId];
}

class ConsultationUpdated extends ConsultationsState {
  final ConsultationModel consultation;

  const ConsultationUpdated({
    required this.consultation,
  });

  @override
  List<Object?> get props => [consultation];
}

class ConsultationDeleted extends ConsultationsState {
  const ConsultationDeleted();
}
