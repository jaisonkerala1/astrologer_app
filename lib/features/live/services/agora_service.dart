import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/live_stream_model.dart';
import '../models/live_comment_model.dart';
import '../../../core/services/live_stream_api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/agora_token_service.dart';

class AgoraService extends ChangeNotifier {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // Agora SDK instances
  RtcEngine? _agoraEngine;
  AgoraRtmClient? _rtmClient;
  AgoraRtmChannel? _rtmChannel;
  
  // Stream data
  LiveStreamModel? _currentStream;
  List<LiveCommentModel> _comments = [];
  List<LiveStreamModel> _liveStreams = [];
  bool _isStreaming = false;
  bool _isInitialized = false;
  bool _isConnected = false;
  List<int> _remoteUsers = [];
  
  // Stream configuration
  String? _channelName;
  String? _token;
  int? _uid;
  
  // Mock data for development
  Timer? _viewerCountTimer;
  Timer? _commentsTimer;
  final Random _random = Random();

  // Backend services
  final LiveStreamApiService _apiService = LiveStreamApiService();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _webSocketSubscription;

  // Getters
  LiveStreamModel? get currentStream => _currentStream;
  List<LiveCommentModel> get comments => List.from(_comments);
  List<LiveStreamModel> get liveStreams => List.from(_liveStreams);
  bool get isStreaming => _isStreaming;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  List<int> get remoteUsers => List.from(_remoteUsers);
  int get viewerCount => _currentStream?.viewerCount ?? 0;
  int get totalViewers => _currentStream?.totalViewers ?? 0;
  int get likes => _currentStream?.likes ?? 0;
  int get commentsCount => _currentStream?.comments ?? 0;
  RtcEngine? get agoraEngine => _agoraEngine;

  // Request permissions
  Future<bool> _requestPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        debugPrint('Camera permission denied');
        return false;
      }

      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      debugPrint('All permissions granted');
      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Initialize Agora SDK
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Starting Agora initialization...');
      
      if (_isInitialized) {
        debugPrint('✅ Agora already initialized');
        return true;
      }

      // Don't request permissions during initialization
      // Permissions will be requested when actually starting a live stream

      debugPrint('🏗️ Creating Agora RTC Engine...');
      // Initialize RTC Engine
      _agoraEngine = createAgoraRtcEngine();
      
      // Use your original App ID
      const appId = '6358473261094f98be1fea84042b1fcf';
      debugPrint('⚙️ Initializing with App ID: $appId');
      await _agoraEngine!.initialize(RtcEngineContext(
        appId: appId,
      ));

      debugPrint('📹 Enabling video...');
      // Enable video (but don't start preview automatically)
      await _agoraEngine!.enableVideo();
      // Note: startPreview() is only called when actually starting a live stream

      debugPrint('📡 Setting up event handlers...');
      // Set up event handlers
      _agoraEngine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Successfully joined channel: ${connection.channelId} (elapsed: ${elapsed}ms)');
            _onChannelJoined();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 User joined: $remoteUid (elapsed: ${elapsed}ms)');
            _remoteUsers.add(remoteUid);
            _onUserJoined(remoteUid);
            
            // Video and audio subscription is handled by autoSubscribeVideo and autoSubscribeAudio options
            debugPrint('📹 Remote user detected: $remoteUid');
            
            // Force UI update immediately when remote user joins
            notifyListeners();
          },
          onUserInfoUpdated: (int remoteUid, UserInfo userInfo) {
            debugPrint('👤 User info updated: $remoteUid - ${userInfo.uid}');
          },
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
            debugPrint('📹 Remote video state changed: UID=$remoteUid, State=$state, Reason=$reason');
            if (state == RemoteVideoState.remoteVideoStateStarting) {
              debugPrint('🎬 Remote video is starting for UID: $remoteUid');
            } else if (state == RemoteVideoState.remoteVideoStateDecoding) {
              debugPrint('✅ Remote video is decoding for UID: $remoteUid');
            } else if (state == RemoteVideoState.remoteVideoStateStopped) {
              debugPrint('⏹️ Remote video stopped for UID: $remoteUid');
            }
            notifyListeners();
          },
          onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
            debugPrint('🔊 Remote audio state changed: UID=$remoteUid, State=$state, Reason=$reason');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👤 User offline: $remoteUid, reason: $reason');
            _remoteUsers.remove(remoteUid);
            _onUserLeft(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora RTC Error: $err - $msg');
            _onError(err, msg);
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint('🔄 Connection state changed: $state, reason: $reason');
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('⚠️ Token will expire soon');
          },
        ),
      );

      // Initialize RTM for messaging
      try {
        _rtmClient = await AgoraRtmClient.createInstance(appId);
        await _rtmClient!.login(null, _generateRandomUserId());
        debugPrint('RTM client initialized successfully');
      } catch (e) {
        debugPrint('RTM client failed to initialize (continuing without RTM): $e');
        _rtmClient = null; // Continue without RTM for now
      }

      _isInitialized = true;
      
      // Connect to WebSocket for real-time updates
      await _webSocketService.connect();
      _webSocketSubscription = _webSocketService.streamUpdates.listen(_handleWebSocketUpdate);
      
      // Load live streams from backend
      await _loadLiveStreamsFromBackend();

      debugPrint('🎉 Agora SDK initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Agora SDK: $e');
      return false;
    }
  }

  // Start a new live stream (Phase 2 - Real Agora)
  Future<bool> startLiveStream({
    required String title,
    String? description,
    required LiveStreamCategory category,
    LiveStreamQuality quality = LiveStreamQuality.medium,
    bool isPrivate = false,
    List<String> tags = const [],
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // Request permissions when actually starting live stream
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint('Permissions not granted, cannot start live stream');
        return false;
      }

      // Get user data from storage first
      final storageService = StorageService();
      final userDataJson = await storageService.getUserData();
      String astrologerId = 'current_user';
      String astrologerName = 'Your Name';
      String? astrologerProfilePicture;
      
      if (userDataJson != null) {
        try {
          final userData = jsonDecode(userDataJson);
          astrologerId = userData['id']?.toString() ?? 'current_user';
          astrologerName = userData['name']?.toString() ?? 'Your Name';
          astrologerProfilePicture = userData['profilePicture']?.toString();
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }

      // Generate dynamic channel name and token after getting user data
      _channelName = 'live_${astrologerId}_${DateTime.now().millisecondsSinceEpoch}';
      // Generate unique UID for broadcaster (use a lower range for broadcasters)
      _uid = _random.nextInt(10000) + 1;
      
      // For Phase 2, we can use empty token for testing
      _token = null; // Empty token for testing mode

      // Create stream model
      final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
      _currentStream = LiveStreamModel(
        id: streamId,
        astrologerId: astrologerId,
        astrologerName: astrologerName,
        astrologerProfilePicture: astrologerProfilePicture,
        title: title,
        description: description,
        category: category,
        status: LiveStreamStatus.preparing,
        quality: quality,
        startedAt: DateTime.now(),
        isPrivate: isPrivate,
        tags: tags,
        streamUrl: 'agora://$_channelName',
        thumbnailUrl: null,
      );

      // Notify backend about stream start
      final apiResult = await _apiService.startLiveStream(
        astrologerId: _currentStream!.astrologerId,
        astrologerName: _currentStream!.astrologerName,
        astrologerProfilePicture: _currentStream!.astrologerProfilePicture,
        title: _currentStream!.title,
        description: _currentStream!.description,
        category: _currentStream!.category,
        quality: _currentStream!.quality,
        isPrivate: _currentStream!.isPrivate,
        tags: _currentStream!.tags,
        agoraChannelName: _channelName!,
        agoraToken: _token,
      );

      if (apiResult == null) {
        debugPrint('❌ Failed to notify backend about stream start');
        return false;
      }

      _isStreaming = true;
      notifyListeners();

            // Start camera preview before joining channel
            await _agoraEngine!.startPreview();
            
            // Generate dynamic token for broadcaster
            debugPrint('🎫 Generating token for broadcaster...');
            final tokenData = await AgoraTokenService.generateToken(
              channelName: _channelName!,
              uid: _uid!,
              role: 'broadcaster',
            );

            String token = '';
            if (tokenData != null) {
              token = tokenData['token'] ?? '';
              debugPrint('✅ Token generated for broadcaster');
            } else {
              debugPrint('⚠️ Using empty token for broadcaster');
            }
            
            // Join channel as broadcaster
            await _agoraEngine!.joinChannel(
              token: token,
              channelId: _channelName!,
              uid: _uid!,
              options: const ChannelMediaOptions(
                clientRoleType: ClientRoleType.clientRoleBroadcaster,
                channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
                publishCameraTrack: true, // Explicitly publish camera track
                publishMicrophoneTrack: true, // Explicitly publish microphone track
              ),
            );

            // Ensure video is being published
            await _agoraEngine!.enableVideo();
            await _agoraEngine!.enableAudio();

      // Join RTM channel for messaging (only if RTM client is available)
      if (_rtmClient != null) {
        _rtmChannel = await _rtmClient!.createChannel(_channelName!);
        await _rtmChannel!.join();
        
        _rtmChannel!.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
          _onMessageReceived(message, member);
        };
      }

      // Update stream status
      _currentStream = _currentStream!.copyWith(
        status: LiveStreamStatus.live,
      );

      _startMockDataUpdates();
      notifyListeners();

      debugPrint('Live stream started successfully with real Agora');
      return true;
    } catch (e) {
      debugPrint('Error starting live stream: $e');
      return false;
    }
  }

  // End current live stream (Phase 2 - Real Agora)
  Future<bool> endLiveStream() async {
    try {
      if (_currentStream == null) return false;

      _stopMockDataUpdates();

      // Notify backend about stream end
      final success = await _apiService.endLiveStream(_currentStream!.id);
      if (!success) {
        debugPrint('❌ Failed to notify backend about stream end');
      }

      // Leave RTM channel
      if (_rtmChannel != null) {
        await _rtmChannel!.leave();
        _rtmChannel = null;
      }

      // Leave RTC channel
      if (_agoraEngine != null) {
        await _agoraEngine!.leaveChannel();
      }

      _currentStream = _currentStream!.copyWith(
        status: LiveStreamStatus.ended,
        endedAt: DateTime.now(),
      );

      // Add to completed streams
      _liveStreams.insert(0, _currentStream!);
      _currentStream = null;
      _isStreaming = false;
      _comments.clear();
      _channelName = null;
      _token = null;
      _uid = null;

      notifyListeners();
      debugPrint('Live stream ended successfully with real Agora');
      return true;
    } catch (e) {
      debugPrint('Error ending live stream: $e');
      return false;
    }
  }

  // Join live stream as audience (Phase 2 - Real Agora)
  Future<bool> joinLiveStream(String streamId) async {
    try {
      debugPrint('🔍 Looking for stream: $streamId');
      
      // Get stream from WebSocket service (which has the latest data)
      final activeStreams = _webSocketService.activeStreams;
      debugPrint('📊 Found ${activeStreams.length} active streams');
      
      final stream = activeStreams.firstWhere(
        (s) => s.id == streamId,
        orElse: () => throw Exception('Stream not found'),
      );

      debugPrint('✅ Found stream: ${stream.title} by ${stream.astrologerName}');
      debugPrint('📺 Stream status: ${stream.status}');
      debugPrint('🔗 Stream URL: ${stream.streamUrl}');

      if (!stream.isLive) {
        debugPrint('❌ Stream is not live: ${stream.status}');
        return false;
      }

      _currentStream = stream;
      _channelName = stream.streamUrl.replaceFirst('agora://', '');
      
      debugPrint('🎬 Joining channel: $_channelName as audience');
      debugPrint('🔧 Agora engine status: ${_agoraEngine != null ? "Initialized" : "Not initialized"}');
      
      // Join as audience
      _uid = _random.nextInt(100000) + 100000;
      debugPrint('👤 Using UID: $_uid');
      
      // Generate dynamic token for audience
      debugPrint('🎫 Generating token for audience...');
      final tokenData = await AgoraTokenService.generateToken(
        channelName: _channelName!,
        uid: _uid!,
        role: 'audience',
      );

      String token = '';
      if (tokenData != null) {
        token = tokenData['token'] ?? '';
        debugPrint('✅ Token generated for audience');
      } else {
        debugPrint('⚠️ Using empty token for audience');
      }
      
      await _agoraEngine!.joinChannel(
        token: token,
        channelId: _channelName!,
        uid: _uid!,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          autoSubscribeAudio: true, // Automatically subscribe to audio
          autoSubscribeVideo: true, // Automatically subscribe to video
        ),
      );

      debugPrint('✅ Successfully joined Agora channel');

      // Check if there are already remote users in the channel
      // This can happen if the broadcaster was already streaming when we joined
      debugPrint('🔍 Checking for existing remote users...');
      // Note: We'll rely on the onUserJoined callback to detect existing users
      
      // Join RTM channel for messaging (only if RTM client is available)
      if (_rtmClient != null) {
        _rtmChannel = await _rtmClient!.createChannel(_channelName!);
        await _rtmChannel!.join();
        
        _rtmChannel!.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
          _onMessageReceived(message, member);
        };
        debugPrint('✅ Joined RTM channel');
      }

      // Set connection status
      _isConnected = true;
      notifyListeners();
      debugPrint('🎉 Successfully joined live stream: $streamId');
      return true;
    } catch (e) {
      debugPrint('❌ Error joining live stream: $e');
      return false;
    }
  }

  // Send comment (Phase 2 - Real Agora)
  Future<bool> sendComment(String message) async {
    try {
      if (_rtmChannel == null || _currentStream == null) return false;

      final comment = LiveCommentModel(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        streamId: _currentStream!.id,
        userId: _uid.toString(),
        userName: 'You',
        message: message,
        timestamp: DateTime.now(),
        type: LiveCommentType.comment,
      );

      // Send via RTM
      final rtmMessage = AgoraRtmMessage.fromText(message);
      await _rtmChannel!.sendMessage(rtmMessage);

      _comments.add(comment);
      notifyListeners();
      debugPrint('Comment sent with real Agora: $message');
      return true;
    } catch (e) {
      debugPrint('Error sending comment: $e');
      return false;
    }
  }

  // Send reaction (Phase 2 - Real Agora)
  Future<bool> sendReaction(LiveReactionType reaction) async {
    try {
      if (_rtmChannel == null || _currentStream == null) return false;

      final reactionComment = LiveCommentModel(
        id: 'reaction_${DateTime.now().millisecondsSinceEpoch}',
        streamId: _currentStream!.id,
        userId: _uid.toString(),
        userName: 'You',
        message: reaction.name,
        timestamp: DateTime.now(),
        type: LiveCommentType.reaction,
      );

      // Send via RTM
      final rtmMessage = AgoraRtmMessage.fromText('REACTION:${reaction.name}');
      await _rtmChannel!.sendMessage(rtmMessage);

      _comments.add(reactionComment);
      notifyListeners();
      debugPrint('Reaction sent with real Agora: ${reaction.name}');
      return true;
    } catch (e) {
      debugPrint('Error sending reaction: $e');
      return false;
    }
  }

  // Leave live stream (for viewers)
  Future<bool> leaveLiveStream() async {
    try {
      if (_currentStream == null) return false;

      debugPrint('👋 Leaving live stream: ${_currentStream!.id}');

      // Leave RTM channel
      if (_rtmChannel != null) {
        await _rtmChannel!.leave();
        _rtmChannel = null;
        debugPrint('✅ Left RTM channel');
      }

      // Leave RTC channel
      if (_agoraEngine != null) {
        await _agoraEngine!.leaveChannel();
        debugPrint('✅ Left RTC channel');
      }

      // Reset state
      _currentStream = null;
      _isConnected = false;
      _remoteUsers.clear();
      _comments.clear();
      _channelName = null;
      _token = null;
      _uid = null;

      notifyListeners();
      debugPrint('🎉 Successfully left live stream');
      return true;
    } catch (e) {
      debugPrint('❌ Error leaving live stream: $e');
      return false;
    }
  }

  // Get live streams for astrologers to watch
  Future<List<LiveStreamModel>> getLiveStreams({
    LiveStreamCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get streams from WebSocket service (real-time data)
      final activeStreams = _webSocketService.activeStreams;
      debugPrint('📊 Found ${activeStreams.length} active streams for viewing');
      
      var filteredStreams = activeStreams.where((stream) => stream.isLive);
      if (category != null) {
        filteredStreams = filteredStreams.where((stream) => stream.category == category);
      }
      
      final result = filteredStreams.skip(offset).take(limit).toList();
      debugPrint('📺 Returning ${result.length} live streams');
      return result;
    } catch (e) {
      debugPrint('Error getting live streams: $e');
      // Fallback to local streams
      var filteredStreams = _liveStreams.where((stream) => stream.isLive);
      if (category != null) {
        filteredStreams = filteredStreams.where((stream) => stream.category == category);
      }
      return filteredStreams.skip(offset).take(limit).toList();
    }
  }

  // Get stream comments
  Future<List<LiveCommentModel>> getStreamComments(String streamId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _comments.where((comment) => comment.type == LiveCommentType.comment).toList();
    } catch (e) {
      debugPrint('Error getting stream comments: $e');
      return [];
    }
  }

  // Handle WebSocket updates
  void _handleWebSocketUpdate(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String?;
      final streamData = data['data'];

      switch (type) {
        case 'active_streams':
          if (streamData is List) {
            _liveStreams = streamData.map((stream) => _parseStreamModel(stream)).toList();
            notifyListeners();
          }
          break;
        case 'stream_started':
          final stream = _parseStreamModel(streamData);
          _liveStreams.add(stream);
          notifyListeners();
          break;
        case 'stream_ended':
          final streamId = streamData['id'] as String?;
          if (streamId != null) {
            _liveStreams.removeWhere((stream) => stream.id == streamId);
            
            // If the current user is watching this stream, end their viewing
            if (_currentStream?.id == streamId) {
              _currentStream = _currentStream!.copyWith(
                status: LiveStreamStatus.ended,
                endedAt: DateTime.now(),
              );
              
              // Leave the Agora channel
              if (_agoraEngine != null) {
                await _agoraEngine!.leaveChannel();
              }
              
              // Leave RTM channel
              if (_rtmChannel != null) {
                await _rtmChannel!.leave();
                _rtmChannel = null;
              }
              
              _isStreaming = false;
              _channelName = null;
              _token = null;
              _uid = null;
            }
            
            notifyListeners();
          }
          break;
        case 'stream_stats_updated':
          final streamId = streamData['id'] as String?;
          if (streamId != null) {
            final index = _liveStreams.indexWhere((stream) => stream.id == streamId);
            if (index != -1) {
              final stream = _liveStreams[index];
              _liveStreams[index] = stream.copyWith(
                viewerCount: streamData['viewerCount'] ?? stream.viewerCount,
                likes: streamData['likes'] ?? stream.likes,
                comments: streamData['comments'] ?? stream.comments,
              );
              notifyListeners();
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket update: $e');
    }
  }

  // Load live streams from backend
  Future<void> _loadLiveStreamsFromBackend() async {
    try {
      final streams = await _apiService.getActiveStreams();
      if (streams != null) {
        _liveStreams = streams;
        notifyListeners();
        debugPrint('📊 Loaded ${streams.length} live streams from backend');
      }
    } catch (e) {
      debugPrint('Error loading live streams from backend: $e');
      // Fallback to mock data
      _loadMockLiveStreams();
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

  // Dispose resources
  Future<void> dispose() async {
    try {
      _stopMockDataUpdates();
      
      // Cancel WebSocket subscription
      await _webSocketSubscription?.cancel();
      await _webSocketService.disconnect();
      
      // Leave RTM channel
      if (_rtmChannel != null) {
        await _rtmChannel!.leave();
        _rtmChannel = null;
      }
      
      // Logout RTM client
      if (_rtmClient != null) {
        await _rtmClient!.logout();
        _rtmClient = null;
      }
      
      // Leave RTC channel
      if (_agoraEngine != null) {
        await _agoraEngine!.leaveChannel();
        await _agoraEngine!.release();
        _agoraEngine = null;
      }
      
      // Reset state
      _isInitialized = false;
      _isStreaming = false;
      _currentStream = null;
      _channelName = null;
      _token = null;
      _uid = null;
      
    } catch (e) {
      debugPrint('Error during AgoraService disposal: $e');
    } finally {
      super.dispose();
    }
  }

  // Private methods
  String _generateRandomUserId() {
    return 'user_${_random.nextInt(100000)}';
  }

  void _onChannelJoined() {
    debugPrint('Successfully joined Agora channel');
  }

  void _onUserJoined(int uid) {
    debugPrint('User $uid joined the stream');
    // Update viewer count
    if (_currentStream != null) {
      _currentStream = _currentStream!.copyWith(
        viewerCount: _currentStream!.viewerCount + 1,
        totalViewers: _currentStream!.totalViewers + 1,
      );
      notifyListeners();
    }
  }

  void _onUserLeft(int uid) {
    debugPrint('User $uid left the stream');
    // Update viewer count
    if (_currentStream != null) {
      _currentStream = _currentStream!.copyWith(
        viewerCount: (_currentStream!.viewerCount - 1).clamp(0, double.infinity).toInt(),
      );
      notifyListeners();
    }
  }

  void _onError(ErrorCodeType err, String msg) {
    debugPrint('Agora Error: $err - $msg');
    // Handle error appropriately
  }

  void _onMessageReceived(AgoraRtmMessage message, AgoraRtmMember member) {
    try {
      final text = message.text;
      
      if (text.startsWith('REACTION:')) {
        // Handle reaction
        final reactionType = text.replaceFirst('REACTION:', '');
        debugPrint('Received reaction: $reactionType from ${member.userId}');
      } else {
        // Handle comment
        final comment = LiveCommentModel(
          id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
          streamId: _currentStream?.id ?? '',
          userId: member.userId,
          userName: member.userId,
          message: text,
          timestamp: DateTime.now(),
          type: LiveCommentType.comment,
        );
        
        _comments.add(comment);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing message: $e');
    }
  }

  void _startMockDataUpdates() {
    // Mock viewer count updates
    _viewerCountTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentStream != null) {
        final change = _random.nextInt(5) - 2; // -2 to +2
        _currentStream = _currentStream!.copyWith(
          viewerCount: (_currentStream!.viewerCount + change).clamp(0, 1000),
          likes: _currentStream!.likes + _random.nextInt(3),
        );
        notifyListeners();
      }
    });

    // Mock comments
    _commentsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentStream != null && _random.nextBool()) {
        final mockComments = [
          'Amazing reading!',
          'Thank you for the insight',
          'Can you read my palm?',
          'This is so accurate!',
          'Love your energy',
          'More please!',
        ];
        
        final comment = LiveCommentModel(
          id: 'mock_comment_${DateTime.now().millisecondsSinceEpoch}',
          streamId: _currentStream!.id,
          userId: 'mock_user_${_random.nextInt(100)}',
          userName: 'Viewer ${_random.nextInt(100)}',
          message: mockComments[_random.nextInt(mockComments.length)],
          timestamp: DateTime.now(),
          type: LiveCommentType.comment,
        );
        
        _comments.add(comment);
        notifyListeners();
      }
    });
  }

  void _stopMockDataUpdates() {
    _viewerCountTimer?.cancel();
    _commentsTimer?.cancel();
    _viewerCountTimer = null;
    _commentsTimer = null;
  }

  void _loadMockLiveStreams() {
    // Add some mock live streams for development
    final mockStreams = [
      LiveStreamModel(
        id: 'mock_stream_1',
        astrologerId: 'astrologer_1',
        astrologerName: 'Dr. Sarah Miller',
        astrologerProfilePicture: null,
        title: 'Daily Tarot Reading',
        description: 'Join me for your daily tarot card reading',
        category: LiveStreamCategory.tarot,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.medium,
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isPrivate: false,
        tags: ['tarot', 'daily', 'reading'],
        streamUrl: 'agora://mock_channel_1',
        thumbnailUrl: null,
        viewerCount: 45,
        totalViewers: 120,
        likes: 89,
        comments: 23,
      ),
      LiveStreamModel(
        id: 'mock_stream_2',
        astrologerId: 'astrologer_2',
        astrologerName: 'Master Raj',
        astrologerProfilePicture: null,
        title: 'Palm Reading Session',
        description: 'Learn about palmistry and get your palm read',
        category: LiveStreamCategory.palmistry,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.high,
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isPrivate: false,
        tags: ['palmistry', 'reading', 'future'],
        streamUrl: 'agora://mock_channel_2',
        thumbnailUrl: null,
        viewerCount: 78,
        totalViewers: 234,
        likes: 156,
        comments: 45,
      ),
      LiveStreamModel(
        id: 'mock_stream_3',
        astrologerId: 'astrologer_3',
        astrologerName: 'Anita Singh',
        astrologerProfilePicture: null,
        title: 'Vedic Astrology Reading',
        description: 'Get your birth chart analyzed',
        category: LiveStreamCategory.astrology,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.medium,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isPrivate: false,
        tags: ['vedic', 'astrology', 'birth-chart'],
        streamUrl: 'agora://mock_channel_3',
        thumbnailUrl: null,
        viewerCount: 32,
        totalViewers: 89,
        likes: 67,
        comments: 12,
      ),
    ];
    
    _liveStreams.addAll(mockStreams);
    notifyListeners();
  }
}
