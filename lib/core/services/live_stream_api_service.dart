import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/live/models/live_stream_model.dart';

class LiveStreamApiService {
  static final LiveStreamApiService _instance = LiveStreamApiService._internal();
  factory LiveStreamApiService() => _instance;
  LiveStreamApiService._internal();

  // Base URL for the API
  String get _baseUrl {
    if (kDebugMode) {
      return 'http://localhost:3001/api'; // Local development
    } else {
      return 'https://astrologerapp-production.up.railway.app/api'; // Production
    }
  }

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Start a live stream
  Future<Map<String, dynamic>?> startLiveStream({
    required String astrologerId,
    required String astrologerName,
    String? astrologerProfilePicture,
    required String title,
    String? description,
    required LiveStreamCategory category,
    required LiveStreamQuality quality,
    bool isPrivate = false,
    List<String> tags = const [],
    required String agoraChannelName,
    String? agoraToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/live-streams/start');
      
      final body = {
        'astrologerId': astrologerId,
        'astrologerName': astrologerName,
        'astrologerProfilePicture': astrologerProfilePicture,
        'title': title,
        'description': description,
        'category': _categoryToString(category),
        'quality': _qualityToString(quality),
        'isPrivate': isPrivate,
        'tags': tags,
        'agoraChannelName': agoraChannelName,
        'agoraToken': agoraToken,
      };

      debugPrint('🚀 Starting live stream: $title');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Live stream started successfully');
        return data;
      } else {
        debugPrint('❌ Failed to start live stream: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }

    } catch (e) {
      debugPrint('❌ Error starting live stream: $e');
      return null;
    }
  }

  // End a live stream
  Future<bool> endLiveStream(String streamId) async {
    try {
      final url = Uri.parse('$_baseUrl/live-streams/$streamId/end');

      debugPrint('🛑 Ending live stream: $streamId');

      final response = await http.put(
        url,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Live stream ended successfully');
        return true;
      } else {
        debugPrint('❌ Failed to end live stream: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ Error ending live stream: $e');
      return false;
    }
  }

  // Get all active streams
  Future<List<LiveStreamModel>?> getActiveStreams() async {
    try {
      final url = Uri.parse('$_baseUrl/live-streams/active');

      debugPrint('📊 Fetching active streams');

      final response = await http.get(
        url,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final streams = (data['data'] as List)
              .map((stream) => _parseStreamModel(stream))
              .toList();
          debugPrint('✅ Fetched ${streams.length} active streams');
          return streams;
        }
      } else {
        debugPrint('❌ Failed to fetch active streams: ${response.statusCode}');
      }

      return null;

    } catch (e) {
      debugPrint('❌ Error fetching active streams: $e');
      return null;
    }
  }

  // Get specific stream details
  Future<LiveStreamModel?> getStreamDetails(String streamId) async {
    try {
      final url = Uri.parse('$_baseUrl/live-streams/$streamId');

      debugPrint('🔍 Fetching stream details: $streamId');

      final response = await http.get(
        url,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stream = _parseStreamModel(data['data']);
          debugPrint('✅ Fetched stream details');
          return stream;
        }
      } else {
        debugPrint('❌ Failed to fetch stream details: ${response.statusCode}');
      }

      return null;

    } catch (e) {
      debugPrint('❌ Error fetching stream details: $e');
      return null;
    }
  }

  // Update stream stats
  Future<bool> updateStreamStats({
    required String streamId,
    int? viewerCount,
    int? likes,
    int? comments,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/live-streams/$streamId/stats');

      final body = <String, dynamic>{};
      if (viewerCount != null) body['viewerCount'] = viewerCount;
      if (likes != null) body['likes'] = likes;
      if (comments != null) body['comments'] = comments;

      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Stream stats updated');
        return true;
      } else {
        debugPrint('❌ Failed to update stream stats: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ Error updating stream stats: $e');
      return false;
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('$_baseUrl/health');

      final response = await http.get(
        url,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ API health check passed: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ API health check failed: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ Error during health check: $e');
      return false;
    }
  }

  // Parse stream data to LiveStreamModel
  LiveStreamModel _parseStreamModel(Map<String, dynamic> data) {
    return LiveStreamModel(
      id: data['id'] ?? '',
      astrologerId: data['astrologerId'] ?? '',
      astrologerName: data['astrologerName'] ?? 'Unknown',
      astrologerProfilePicture: data['astrologerProfilePicture'],
      title: data['title'] ?? '',
      description: data['description'],
      category: _parseCategory(data['category']),
      status: _parseStatus(data['status']),
      quality: _parseQuality(data['quality']),
      startedAt: DateTime.tryParse(data['startedAt'] ?? '') ?? DateTime.now(),
      endedAt: data['endedAt'] != null ? DateTime.tryParse(data['endedAt']) : null,
      isPrivate: data['isPrivate'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      streamUrl: 'agora://${data['agoraChannelName'] ?? ''}',
      thumbnailUrl: data['thumbnailUrl'],
      viewerCount: data['viewerCount'] ?? 0,
      totalViewers: data['totalViewers'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  // Convert category enum to string
  String _categoryToString(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.astrology: return 'astrology';
      case LiveStreamCategory.tarot: return 'tarot';
      case LiveStreamCategory.numerology: return 'numerology';
      case LiveStreamCategory.palmistry: return 'palmistry';
      case LiveStreamCategory.healing: return 'healing';
      case LiveStreamCategory.meditation: return 'meditation';
      case LiveStreamCategory.spiritual: return 'spiritual';
      case LiveStreamCategory.general: return 'general';
    }
  }

  // Convert quality enum to string
  String _qualityToString(LiveStreamQuality quality) {
    switch (quality) {
      case LiveStreamQuality.low: return 'low';
      case LiveStreamQuality.medium: return 'medium';
      case LiveStreamQuality.high: return 'high';
      case LiveStreamQuality.ultra: return 'ultra';
    }
  }

  // Parse category string to enum
  LiveStreamCategory _parseCategory(String? category) {
    switch (category) {
      case 'astrology': return LiveStreamCategory.astrology;
      case 'tarot': return LiveStreamCategory.tarot;
      case 'numerology': return LiveStreamCategory.numerology;
      case 'palmistry': return LiveStreamCategory.palmistry;
      case 'healing': return LiveStreamCategory.healing;
      case 'meditation': return LiveStreamCategory.meditation;
      case 'spiritual': return LiveStreamCategory.spiritual;
      default: return LiveStreamCategory.general;
    }
  }

  // Parse status string to enum
  LiveStreamStatus _parseStatus(String? status) {
    switch (status) {
      case 'live': return LiveStreamStatus.live;
      case 'ended': return LiveStreamStatus.ended;
      case 'paused': return LiveStreamStatus.paused;
      default: return LiveStreamStatus.preparing;
    }
  }

  // Parse quality string to enum
  LiveStreamQuality _parseQuality(String? quality) {
    switch (quality) {
      case 'low': return LiveStreamQuality.low;
      case 'medium': return LiveStreamQuality.medium;
      case 'high': return LiveStreamQuality.high;
      case 'ultra': return LiveStreamQuality.ultra;
      default: return LiveStreamQuality.medium;
    }
  }
}
