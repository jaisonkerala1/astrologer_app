import '../../models/live_stream_model.dart';

/// Repository interface for Live Feed
/// Abstract for easy backend integration (Agora + REST API)
abstract class LiveFeedRepository {
  /// Get active live streams with pagination
  /// 
  /// [page] - Page number (1-indexed)
  /// [limit] - Number of streams per page
  /// [category] - Optional category filter (e.g., 'Tarot', 'Astrology')
  /// 
  /// Returns list of active live streams sorted by:
  /// - Viewers count (descending)
  /// - Start time (most recent first)
  /// - Like Instagram/YouTube algorithm
  Future<List<LiveStreamModel>> getActiveLiveStreams({
    int page = 1,
    int limit = 10,
    String? category,
  });
  
  /// Get a specific live stream by ID
  /// 
  /// [streamId] - Unique stream identifier
  /// 
  /// Returns stream details or throws if not found
  Future<LiveStreamModel> getLiveStreamById(String streamId);
  
  /// Preload stream data for smooth transitions
  /// 
  /// [streamId] - Stream to preload
  /// 
  /// For Agora: This will fetch token, channel info, etc.
  /// For now: No-op in mock, ready for real implementation
  Future<void> preloadStreamData(String streamId);
  
  /// Get available categories for filtering
  /// 
  /// Returns list of category names
  Future<List<String>> getCategories();
  
  /// Join a live stream
  /// 
  /// [streamId] - Stream to join
  /// 
  /// For Agora: Will get token and channel credentials
  /// Returns join data (token, channel, etc.)
  Future<Map<String, dynamic>> joinStream(String streamId);
  
  /// Leave a live stream
  /// 
  /// [streamId] - Stream to leave
  /// 
  /// For Agora: Will cleanup resources and notify backend
  Future<void> leaveStream(String streamId);
}

