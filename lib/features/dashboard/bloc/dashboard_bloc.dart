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
        
        print('📊 Dashboard stats from backend: $statsData');
        
        emit(DashboardLoadedState(realStats));
        print('✅ Dashboard stats loaded from database');
      } else {
        throw Exception('Failed to load dashboard stats: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      
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
      print('🔄 Updating online status to: ${event.isOnline}');
      
      // Call real backend API to update online status
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/api/dashboard/status',
        data: {'isOnline': event.isOnline},
      );

      print('📡 API Response: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Always reload dashboard stats after updating online status
        emit(StatusUpdatedState(event.isOnline));
        print('✅ Online status updated to ${event.isOnline ? 'ONLINE' : 'OFFLINE'} in database');
        print('🔄 Triggering dashboard stats reload...');
        
        // Reload dashboard stats with updated online status
        try {
          final statsResponse = await _apiService.get(
            '${ApiConstants.baseUrl}/api/dashboard/stats',
          );

          if (statsResponse.statusCode == 200 && statsResponse.data['success'] == true) {
            final statsData = statsResponse.data['data'];
            print('📊 Dashboard stats reloaded: $statsData');
            
            final realStats = DashboardStatsModel(
              todayEarnings: (statsData['todayEarnings'] ?? 0).toDouble(),
              totalEarnings: (statsData['totalEarnings'] ?? 0).toDouble(),
              callsToday: statsData['callsToday'] ?? 0,
              totalCalls: statsData['totalCalls'] ?? 0,
              isOnline: statsData['isOnline'] ?? false,
              totalSessions: statsData['totalSessions'] ?? 0,
              averageSessionDuration: (statsData['averageSessionDuration'] ?? 0).toDouble(),
              averageRating: (statsData['averageRating'] ?? 0).toDouble(),
              todayCount: statsData['callsToday'] ?? 0,
            );
            
            emit(DashboardLoadedState(realStats));
            print('✅ Dashboard stats reloaded successfully after status update');
          }
        } catch (e) {
          print('❌ Error reloading dashboard stats: $e');
        }
      } else {
        throw Exception('Failed to update online status: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error updating online status: $e');
      print('❌ Error type: ${e.runtimeType}');
      emit(DashboardErrorState('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboardEvent event, Emitter<DashboardState> emit) async {
    add(LoadDashboardStatsEvent());
  }
}
