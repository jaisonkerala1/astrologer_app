import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../features/live/models/live_stream_model.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _serverUrl;

  // Live streams data
  List<LiveStreamModel> _activeStreams = [];
  StreamController<Map<String, dynamic>> _streamController = StreamController.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  List<LiveStreamModel> get activeStreams => List.from(_activeStreams);
  Stream<Map<String, dynamic>> get streamUpdates => _streamController.stream;

  // Initialize WebSocket connection
  Future<bool> connect({String? serverUrl}) async {
    try {
      // Always use Railway WebSocket URL
      _serverUrl = serverUrl ?? 'wss://astrologerapp-production.up.railway.app/ws/live-streams';
      
      debugPrint('🔌 Using WebSocket URL: $_serverUrl');
      debugPrint('🔌 Connecting to WebSocket: $_serverUrl');

      // Disconnect existing connection if any
      await disconnect();

      _channel = IOWebSocketChannel.connect(
        _serverUrl!,
        protocols: ['live-streams'],
      );
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false, // Don't cancel on error, let us handle it
      );

      // Wait a moment to ensure connection is established
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;
      notifyListeners();
      
      debugPrint('✅ WebSocket connected successfully');
      
      // Request active streams after connection
      _requestActiveStreams();
      
      return true;

    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _isConnected = false;
      notifyListeners();
      
      // Retry connection after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          debugPrint('🔄 Retrying WebSocket connection...');
          connect(serverUrl: _serverUrl);
        }
      });
      
      return false;
    }
  }

  // Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;
      final streamData = data['data'];

      debugPrint('📨 WebSocket message received: $type');

      switch (type) {
        case 'active_streams':
          _handleActiveStreams(streamData);
          break;
        case 'stream_started':
          _handleStreamStarted(streamData);
          break;
        case 'stream_ended':
          _handleStreamEnded(streamData);
          break;
        case 'stream_stats_updated':
          _handleStreamStatsUpdated(streamData);
          break;
        default:
          debugPrint('⚠️ Unknown WebSocket message type: $type');
      }

      // Notify listeners
      notifyListeners();
      _streamController.add(data);

    } catch (e) {
      debugPrint('❌ Error parsing WebSocket message: $e');
    }
  }

  // Handle active streams list
  void _handleActiveStreams(dynamic data) {
    if (data is List) {
      _activeStreams = data.map((stream) => _parseStreamModel(stream)).toList();
      debugPrint('📊 Loaded ${_activeStreams.length} active streams');
    }
  }

  // Handle new stream started
  void _handleStreamStarted(dynamic data) {
    final stream = _parseStreamModel(data);
    _activeStreams.add(stream);
    debugPrint('🟢 Stream started: ${stream.title} by ${stream.astrologerName}');
  }

  // Handle stream ended
  void _handleStreamEnded(dynamic data) {
    final streamId = data['id'] as String?;
    if (streamId != null) {
      _activeStreams.removeWhere((stream) => stream.id == streamId);
      debugPrint('🔴 Stream ended: $streamId');
    }
  }

  // Handle stream stats updated
  void _handleStreamStatsUpdated(dynamic data) {
    final streamId = data['id'] as String?;
    if (streamId != null) {
      final index = _activeStreams.indexWhere((stream) => stream.id == streamId);
      if (index != -1) {
        final stream = _activeStreams[index];
        _activeStreams[index] = stream.copyWith(
          viewerCount: data['viewerCount'] ?? stream.viewerCount,
          likes: data['likes'] ?? stream.likes,
          comments: data['comments'] ?? stream.comments,
        );
        debugPrint('📈 Stream stats updated: $streamId');
      }
    }
  }

  // Parse stream data to LiveStreamModel
  LiveStreamModel _parseStreamModel(dynamic data) {
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

  // Request active streams from server
  void _requestActiveStreams() {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'request_active_streams',
          'timestamp': DateTime.now().toIso8601String(),
        }));
        debugPrint('📡 Requested active streams from server');
      } catch (e) {
        debugPrint('❌ Error requesting active streams: $e');
      }
    }
  }

  // Handle WebSocket errors
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    notifyListeners();
    
    // Retry connection after error
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected) {
        debugPrint('🔄 Retrying WebSocket connection after error...');
        connect(serverUrl: _serverUrl);
      }
    });
  }

  // Handle WebSocket connection closed
  void _onDone() {
    debugPrint('🔌 WebSocket connection closed');
    _isConnected = false;
    notifyListeners();
  }

  // Disconnect WebSocket
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      _activeStreams.clear();
      notifyListeners();
      debugPrint('🔌 WebSocket disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting WebSocket: $e');
    }
  }

  // Dispose resources
  @override
  void dispose() {
    disconnect();
    _streamController.close();
    super.dispose();
  }
}
