import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/live/models/live_stream_model.dart';
import '../../../features/live/models/live_comment_model.dart';
import '../../../features/live/models/live_gift_model.dart';
import '../../../features/live/models/live_reaction_model.dart';
import '../base_repository.dart';
import 'live_repository.dart';

class LiveRepositoryImpl extends BaseRepository implements LiveRepository {
  final ApiService apiService;
  final StorageService storageService;

  LiveRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<LiveStreamModel> startLiveStream({
    required String title,
    required String description,
    required LiveStreamCategory category,
    required List<String> tags,
  }) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post('/api/live/start', data: {
        'astrologerId': astrologerId,
        'title': title,
        'description': description,
        'category': category.name,
        'tags': tags,
      });
      if (response.data['success'] == true) {
        return LiveStreamModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to start live stream');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveStreamModel> endLiveStream(String streamId) async {
    try {
      final response = await apiService.post('/api/live/$streamId/end');
      if (response.data['success'] == true) {
        return LiveStreamModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to end live stream');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveStreamModel> updateStreamInfo(String streamId, {String? title, String? description}) async {
    try {
      final response = await apiService.patch('/api/live/$streamId', data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });
      if (response.data['success'] == true) {
        return LiveStreamModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update stream info');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<LiveStreamModel>> getLiveStreams({LiveStreamCategory? category, String? search}) async {
    try {
      final response = await apiService.get('/api/live/streams', queryParameters: {
        if (category != null) 'category': category.name,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => LiveStreamModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load live streams');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveStreamModel> getStreamById(String id) async {
    try {
      final response = await apiService.get('/api/live/$id');
      if (response.data['success'] == true) {
        return LiveStreamModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to load stream');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveStreamModel> joinStream(String streamId) async {
    try {
      final userId = await _getAstrologerId();
      final response = await apiService.post('/api/live/$streamId/join', data: {'userId': userId});
      if (response.data['success'] == true) {
        return LiveStreamModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to join stream');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> leaveStream(String streamId) async {
    try {
      final userId = await _getAstrologerId();
      final response = await apiService.post('/api/live/$streamId/leave', data: {'userId': userId});
      if (response.data['success'] != true) {
        throw Exception('Failed to leave stream');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<LiveCommentModel>> getStreamComments(String streamId) async {
    try {
      final response = await apiService.get('/api/live/$streamId/comments');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => LiveCommentModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load comments');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveCommentModel> sendComment(String streamId, String message) async {
    try {
      final userId = await _getAstrologerId();
      final userName = await _getUserName();
      final response = await apiService.post('/api/live/$streamId/comments', data: {
        'userId': userId,
        'userName': userName,
        'message': message,
      });
      if (response.data['success'] == true) {
        return LiveCommentModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to send comment');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveGiftModel> sendGift(String streamId, String giftName, int giftValue) async {
    try {
      final userId = await _getAstrologerId();
      final userName = await _getUserName();
      final response = await apiService.post('/api/live/$streamId/gifts', data: {
        'userId': userId,
        'userName': userName,
        'giftName': giftName,
        'giftValue': giftValue,
      });
      if (response.data['success'] == true) {
        return LiveGiftModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to send gift');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<LiveReactionModel> sendReaction(String streamId, String emoji) async {
    try {
      final userId = await _getAstrologerId();
      final userName = await _getUserName();
      final response = await apiService.post('/api/live/$streamId/reactions', data: {
        'userId': userId,
        'userName': userName,
        'emoji': emoji,
      });
      if (response.data['success'] == true) {
        return LiveReactionModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to send reaction');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getStreamAnalytics(String streamId) async {
    try {
      final response = await apiService.get('/api/live/$streamId/analytics');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Failed to load analytics');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<int> getViewerCount(String streamId) async {
    try {
      final response = await apiService.get('/api/live/$streamId/viewers');
      if (response.data['success'] == true) {
        return response.data['data']['count'] ?? 0;
      }
      throw Exception('Failed to load viewer count');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<String> _getAstrologerId() async {
    final userData = await storageService.getUserData();
    if (userData != null) {
      final userDataMap = jsonDecode(userData);
      return userDataMap['id'] ?? userDataMap['_id'] ?? '';
    }
    throw Exception('Astrologer ID not found');
  }

  Future<String> _getUserName() async {
    final userData = await storageService.getUserData();
    if (userData != null) {
      final userDataMap = jsonDecode(userData);
      return userDataMap['name'] ?? '';
    }
    return 'User';
  }
}


