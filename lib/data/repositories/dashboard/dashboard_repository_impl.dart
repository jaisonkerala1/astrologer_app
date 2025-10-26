import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/dashboard/models/dashboard_stats_model.dart';
import '../../../features/auth/models/astrologer_model.dart';
import '../base_repository.dart';
import 'dashboard_repository.dart';

/// Implementation of DashboardRepository
/// Handles dashboard data operations using ApiService and StorageService
class DashboardRepositoryImpl extends BaseRepository implements DashboardRepository {
  final ApiService apiService;
  final StorageService storageService;

  DashboardRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await apiService.get(ApiConstants.dashboardStats);

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
          astrologer: data['astrologer'] != null 
              ? AstrologerModel.fromJson(data['astrologer']) 
              : null,
        );

        // Cache the stats for offline access
        await cacheStats(stats);

        return stats;
      } else {
        throw Exception('Failed to load dashboard stats: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Try to return cached data if API fails
      final cachedStats = await getCachedStats();
      if (cachedStats != null) {
        print('Dashboard: Using cached stats due to error: $e');
        return cachedStats;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await apiService.put(
        ApiConstants.updateStatus,
        data: {'isOnline': isOnline},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update cached stats with new status
        final cachedStats = await getCachedStats();
        if (cachedStats != null) {
          final updatedStats = cachedStats.copyWith(isOnline: isOnline);
          await cacheStats(updatedStats);
        }
        return true;
      } else {
        throw Exception('Failed to update status: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<DashboardStatsModel> refreshDashboard() async {
    // Clear cache and fetch fresh data
    await clearCache();
    return await getDashboardStats();
  }

  @override
  Future<DashboardStatsModel?> getCachedStats() async {
    try {
      final cachedData = await storageService.getString('dashboard_stats_cache');
      if (cachedData != null) {
        // Parse cached data (you'd need to add fromJson to DashboardStatsModel)
        // For now, return null - implement caching later if needed
        return null;
      }
      return null;
    } catch (e) {
      print('Error getting cached stats: $e');
      return null;
    }
  }

  @override
  Future<void> cacheStats(DashboardStatsModel stats) async {
    try {
      // Store stats in cache (you'd need to add toJson to DashboardStatsModel)
      // For now, skip caching - implement later if needed
      // await storageService.setString('dashboard_stats_cache', jsonEncode(stats.toJson()));
    } catch (e) {
      print('Error caching stats: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('dashboard_stats_cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}


