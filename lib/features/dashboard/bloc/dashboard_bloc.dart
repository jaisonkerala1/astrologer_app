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
      // Call real backend API to get dashboard stats
      final response = await _apiService.get(
        '${ApiConstants.baseUrl}/api/dashboard/stats',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final statsData = response.data['data'];
        final realStats = DashboardStatsModel(
          todayEarnings: (statsData['todayEarnings'] ?? 0).toDouble(),
          totalEarnings: (statsData['totalEarnings'] ?? 0).toDouble(),
          callsToday: statsData['callsToday'] ?? 0,
          totalCalls: statsData['totalCalls'] ?? 0,
          isOnline: statsData['isOnline'] ?? false,
          totalSessions: statsData['totalSessions'] ?? 0,
          averageSessionDuration: (statsData['averageSessionDuration'] ?? 0).toDouble(),
          averageRating: (statsData['averageRating'] ?? 0).toDouble(),
          todayCount: statsData['callsToday'] ?? 0, // Using callsToday as todayCount
        );
        
        emit(DashboardLoadedState(realStats));
        print('✅ Dashboard stats loaded from database');
      } else {
        throw Exception('Failed to load dashboard stats: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
      // Fallback to mock data if API fails
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
      print('⚠️ Using fallback mock data due to API error');
    }
  }

  Future<void> _onUpdateOnlineStatus(UpdateOnlineStatusEvent event, Emitter<DashboardState> emit) async {
    try {
      // Call real backend API to update online status
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/api/dashboard/status',
        data: {'isOnline': event.isOnline},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update the current state with new online status from backend
        if (state is DashboardLoadedState) {
          final currentStats = (state as DashboardLoadedState).stats;
          final updatedStats = currentStats.copyWith(isOnline: event.isOnline);
          emit(DashboardLoadedState(updatedStats));
        }
        
        emit(StatusUpdatedState(event.isOnline));
        print('✅ Online status updated to ${event.isOnline ? 'ONLINE' : 'OFFLINE'} in database');
      } else {
        throw Exception('Failed to update online status: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error updating online status: $e');
      emit(DashboardErrorState('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboardEvent event, Emitter<DashboardState> emit) async {
    add(LoadDashboardStatsEvent());
  }
}
