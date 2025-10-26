import '../../../features/dashboard/models/dashboard_stats_model.dart';

/// Dashboard Repository Interface
/// Handles all dashboard-related data operations
/// 
/// This abstraction allows us to:
/// - Switch between different data sources (API, cache, mock)
/// - Test DashboardBloc without real API calls
/// - Keep business logic separate from data logic
abstract class DashboardRepository {
  /// Get dashboard statistics for the current astrologer
  /// Returns dashboard stats including earnings, calls, online status, etc.
  Future<DashboardStatsModel> getDashboardStats();

  /// Update astrologer's online/offline status
  /// Returns true if update was successful
  Future<bool> updateOnlineStatus(bool isOnline);

  /// Refresh dashboard data from server
  /// Returns updated dashboard stats
  Future<DashboardStatsModel> refreshDashboard();

  /// Get cached dashboard stats (if available)
  /// Returns null if no cache exists
  Future<DashboardStatsModel?> getCachedStats();

  /// Save dashboard stats to cache
  Future<void> cacheStats(DashboardStatsModel stats);

  /// Clear cached dashboard data
  Future<void> clearCache();
}


