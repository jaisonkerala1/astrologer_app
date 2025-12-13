import '../../../features/live/models/live_stream_model.dart';
import '../../../features/live/models/live_comment_model.dart';
import '../../../features/live/models/live_gift_model.dart';
import '../../../features/live/models/live_reaction_model.dart';

/// Abstract interface for Live Streaming operations
abstract class LiveRepository {
  // Broadcasting (Going Live)
  Future<LiveStreamModel> startLiveStream({
    required String title,
    required String description,
    required LiveStreamCategory category,
    required List<String> tags,
  });
  Future<LiveStreamModel> endLiveStream(String streamId);
  Future<LiveStreamModel> updateStreamInfo(String streamId, {String? title, String? description});
  
  // Viewing (Browsing & Watching)
  Future<List<LiveStreamModel>> getLiveStreams({LiveStreamCategory? category, String? search});
  Future<LiveStreamModel> getStreamById(String id);
  Future<LiveStreamModel> joinStream(String streamId);
  Future<void> leaveStream(String streamId);
  
  // Interactions (Comments, Gifts, Reactions)
  Future<List<LiveCommentModel>> getStreamComments(String streamId);
  Future<LiveCommentModel> sendComment(String streamId, String message);
  Future<LiveGiftModel> sendGift(String streamId, String giftName, int giftValue);
  Future<LiveReactionModel> sendReaction(String streamId, String emoji);
  
  // Stream Stats
  Future<Map<String, dynamic>> getStreamAnalytics(String streamId);
  Future<int> getViewerCount(String streamId);
  
  // Agora Token
  Future<String> getAgoraToken({
    required String channelName,
    required int uid,
    required bool isBroadcaster,
  });
  
  Future<String> refreshAgoraToken({
    required String channelName,
    required int uid,
    required bool isBroadcaster,
  });
  
  // Active Streams (for dashboard)
  Future<List<LiveStreamModel>> getActiveLiveStreams();
}


