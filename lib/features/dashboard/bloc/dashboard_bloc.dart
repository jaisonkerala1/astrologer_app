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
      // Call the actual backend API
      final response = await _apiService.get(ApiConstants.dashboardStats);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        final stats = DashboardStatsModel(
          todayEarnings: (data['todayEarnings'] ?? 0).toDouble(),
          totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
          callsToday: data['callsToday'] ?? 0,
          totalCalls: data['totalCalls'] ?? 0,
          isOnline: data['isOnline'] ?? false,
          totalSessions: data['totalSessions'] ?? 0,
          averageSessionDuration: (data['averageSessionDuration'] ?? 0).toDouble(),
          averageRating: (data['averageRating'] ?? 0).toDouble(),
          todayCount: data['todayCount'] ?? 0,
        );
        
        emit(DashboardLoadedState(stats));
      } else {
        throw Exception('Failed to load dashboard stats: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      emit(DashboardErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateOnlineStatus(UpdateOnlineStatusEvent event, Emitter<DashboardState> emit) async {
    try {
      // Call the actual backend API to update status
      final response = await _apiService.put(
        ApiConstants.updateStatus,
        data: {'isOnline': event.isOnline},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update the current state with new online status
        if (state is DashboardLoadedState) {
          final currentStats = (state as DashboardLoadedState).stats;
          final updatedStats = currentStats.copyWith(isOnline: event.isOnline);
          emit(DashboardLoadedState(updatedStats));
        }
        
        emit(StatusUpdatedState(event.isOnline));
      } else {
        throw Exception('Failed to update status: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      emit(DashboardErrorState('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboardEvent event, Emitter<DashboardState> emit) async {
    add(LoadDashboardStatsEvent());
  }
}
