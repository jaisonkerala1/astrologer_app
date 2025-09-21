import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/dashboard_stats_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService _apiService = ApiService();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardStatsEvent>(_onLoadDashboardStats);
    on<UpdateOnlineStatusEvent>(_onUpdateOnlineStatus);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardStats(LoadDashboardStatsEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    
    try {
      // For MVP, we'll use mock data since backend isn't ready yet
      // In production, this would call the actual API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      final mockStats = DashboardStatsModel(
        todayEarnings: 1250.0,
        totalEarnings: 15600.0,
        callsToday: 8,
        totalCalls: 156,
        isOnline: false,
        totalSessions: 156,
        averageSessionDuration: 15.5,
        averageRating: 4.7,
        todayCount: 12,
      );
      
      emit(DashboardLoadedState(mockStats));
    } catch (e) {
      emit(DashboardErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateOnlineStatus(UpdateOnlineStatusEvent event, Emitter<DashboardState> emit) async {
    try {
      // For MVP, we'll simulate the API call
      // In production, this would call the actual API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update the current state with new online status
      if (state is DashboardLoadedState) {
        final currentStats = (state as DashboardLoadedState).stats;
        final updatedStats = currentStats.copyWith(isOnline: event.isOnline);
        emit(DashboardLoadedState(updatedStats));
      }
      
      emit(StatusUpdatedState(event.isOnline));
    } catch (e) {
      emit(DashboardErrorState('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboardEvent event, Emitter<DashboardState> emit) async {
    add(LoadDashboardStatsEvent());
  }
}
