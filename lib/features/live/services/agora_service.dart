import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/live/live_repository.dart';

/// Agora Live Streaming Service
/// Handles all Agora RTC Engine operations for live broadcasting and viewing
class AgoraService extends ChangeNotifier {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // ============================================
  // AGORA CONFIGURATION
  // ============================================
  
  static const String appId = '6358473261094f98be1fea84042b1fcf';
  
  // ============================================
  // ENGINE STATE
  // ============================================
  
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isBroadcaster = false;
  String? _currentChannel;
  int? _localUid;
  
  // Remote users (for audience viewing)
  final Set<int> _remoteUsers = {};
  int? _broadcasterUid;
  
  // Video/Audio state
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isFrontCamera = true;
  
  // Local video state tracking
  LocalVideoStreamState _localVideoState = LocalVideoStreamState.localVideoStreamStateStopped;
  bool _isLocalVideoPublishing = false;
  
  // Callbacks
  Function(String message)? onError;
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserOffline;
  Function()? onJoinChannelSuccess;
  Function()? onLeaveChannel;
  Function(int uid)? onFirstRemoteVideoFrame;
  Function(LocalVideoStreamState state, LocalVideoStreamReason reason)? onLocalVideoStateChanged;
  
  // ============================================
  // GETTERS
  // ============================================
  
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  bool get isBroadcaster => _isBroadcaster;
  String? get currentChannel => _currentChannel;
  int? get localUid => _localUid;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isFrontCamera => _isFrontCamera;
  Set<int> get remoteUsers => _remoteUsers;
  int? get broadcasterUid => _broadcasterUid;
  LocalVideoStreamState get localVideoState => _localVideoState;
  bool get isLocalVideoPublishing => _isLocalVideoPublishing;
  
  // ============================================
  // INITIALIZATION
  // ============================================
  
  Future<bool> initialize({bool forBroadcasting = true}) async {
    // Health Check: If already initialized, verify engine is healthy
    if (_isInitialized && _engine != null) {
      try {
        // Test if engine is actually responsive
        await _engine!.getConnectionState();
        debugPrint('🎥 [AGORA] Engine healthy, reusing');
        return true;
      } catch (e) {
        // Engine is broken, need to reinitialize
        debugPrint('⚠️ [AGORA] Engine unhealthy ($e), reinitializing...');
        await disposeEngine();
      }
    }
    
    try {
      debugPrint('🎥 [AGORA] Initializing RTC Engine...');
      
      // Request permissions only for broadcasting
      if (forBroadcasting) {
        final permissionsGranted = await _requestPermissions();
        if (!permissionsGranted) {
          debugPrint('❌ [AGORA] Permissions not granted');
          onError?.call('Camera and microphone permissions are required');
          return false;
        }
      }
      
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅✅✅ [AGORA] JOINED channel: ${connection.channelId}, MY UID: ${connection.localUid}');
          _isJoined = true;
          _localUid = connection.localUid;
          _currentChannel = connection.channelId;
          notifyListeners();
          onJoinChannelSuccess?.call();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('👤👤👤 [AGORA] REMOTE USER JOINED: $remoteUid on channel: ${connection.channelId}');
          _remoteUsers.add(remoteUid);
          // First remote user is likely the broadcaster
          _broadcasterUid ??= remoteUid;
          notifyListeners();
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('👤 [AGORA] Remote user offline: $remoteUid, reason: $reason');
          _remoteUsers.remove(remoteUid);
          if (_broadcasterUid == remoteUid) {
            _broadcasterUid = _remoteUsers.isNotEmpty ? _remoteUsers.first : null;
          }
          notifyListeners();
          onUserOffline?.call(remoteUid);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('🚪 [AGORA] Left channel: ${connection.channelId}');
          _isJoined = false;
          _isBroadcaster = false;
          _currentChannel = null;
          _remoteUsers.clear();
          _broadcasterUid = null;
          _isLocalVideoPublishing = false;
          notifyListeners();
          onLeaveChannel?.call();
        },
        onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
          debugPrint('📺 [AGORA] First remote video frame from: $remoteUid (${width}x$height)');
          _broadcasterUid = remoteUid;
          notifyListeners();
          onFirstRemoteVideoFrame?.call(remoteUid);
        },
        // Camera State Verification - Track local video state
        onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state, LocalVideoStreamReason reason) {
          debugPrint('📹 [AGORA] Local video state: $state, reason: $reason, source: $source');
          _localVideoState = state;
          
          // Track if video is actually publishing
          if (state == LocalVideoStreamState.localVideoStreamStateCapturing ||
              state == LocalVideoStreamState.localVideoStreamStateEncoding) {
            _isLocalVideoPublishing = true;
            debugPrint('✅ [AGORA] Local video is publishing');
          } else if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
            _isLocalVideoPublishing = false;
            debugPrint('❌ [AGORA] Local video FAILED: $reason');
            onError?.call('Camera failed: $reason');
          } else if (state == LocalVideoStreamState.localVideoStreamStateStopped) {
            _isLocalVideoPublishing = false;
          }
          
          notifyListeners();
          onLocalVideoStateChanged?.call(state, reason);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('❌ [AGORA] Error: $err - $msg');
          onError?.call('Agora Error: $msg');
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) async {
          debugPrint('🔄 [AGORA] Token will expire in 30 seconds - Refreshing...');
          
          final channelId = connection.channelId;
          if (channelId == null) {
            debugPrint('⚠️ [AGORA] Cannot refresh token - channel ID is null');
            return;
          }
          
          try {
            // Fetch new token from backend
            final newToken = await _refreshToken(
              channelName: channelId,
              uid: _localUid ?? 0,
            );
            
            // Renew token in SDK
            await _engine!.renewToken(newToken);
            
            debugPrint('✅ [AGORA] Token refreshed successfully');
            
          } catch (e) {
            debugPrint('❌ [AGORA] Token refresh failed: $e');
            onError?.call('Failed to refresh token');
          }
        },
        onRequestToken: (RtcConnection connection) async {
          // Emergency: Token already expired
          debugPrint('⚠️ [AGORA] Token EXPIRED - Emergency refresh');
          
          final channelId = connection.channelId;
          if (channelId == null) {
            debugPrint('⚠️ [AGORA] Cannot refresh token - channel ID is null');
            return;
          }
          
          try {
            final newToken = await _refreshToken(
              channelName: channelId,
              uid: _localUid ?? 0,
            );
            
            await _engine!.renewToken(newToken);
            debugPrint('✅ [AGORA] Emergency token refresh successful');
            
          } catch (e) {
            debugPrint('❌ [AGORA] Emergency token refresh failed: $e');
            onError?.call('Connection lost - please restart stream');
          }
        },
      ));
      
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      
      if (forBroadcasting) {
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 30,
            bitrate: 2000,
            orientationMode: OrientationMode.orientationModeAdaptive,
          ),
        );
      }
      
      _isInitialized = true;
      debugPrint('✅ [AGORA] RTC Engine initialized');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Initialization failed: $e');
      onError?.call('Failed to initialize: $e');
      return false;
    }
  }
  
  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }
  
  // ============================================
  // BROADCASTING (HOST)
  // ============================================
  
  Future<bool> startBroadcasting({
    required String channelName,
    required String token,
    int uid = 0,
    int maxRetries = 2,
  }) async {
    debugPrint('🎥 [AGORA] Starting broadcast on channel: $channelName');
    
    // Force Dispose Before New Stream - Always ensure clean state
    if (_isJoined) {
      debugPrint('⚠️ [AGORA] Already in a channel, leaving first...');
      await leaveChannel();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Force reinitialize to ensure fresh camera/engine state
    if (_isInitialized) {
      debugPrint('🔄 [AGORA] Force disposing engine for fresh start...');
      await disposeEngine();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Initialize fresh
    final initialized = await initialize(forBroadcasting: true);
    if (!initialized) return false;
    
    // Attempt broadcast with retry logic
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('🔄 [AGORA] Retry attempt $attempt of $maxRetries');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Reset video/audio state
        _isVideoEnabled = true;
        _isAudioEnabled = true;
        _isLocalVideoPublishing = false;
        _localVideoState = LocalVideoStreamState.localVideoStreamStateStopped;
        
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        
        // Ensure video and audio are enabled
        await _engine!.enableVideo();
        await _engine!.enableAudio();
        await _engine!.muteLocalVideoStream(false);
        await _engine!.muteLocalAudioStream(false);
        
        // Start preview first
        await _engine!.startPreview();
        
        // Wait for camera to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if local video failed
        if (_localVideoState == LocalVideoStreamState.localVideoStreamStateFailed) {
          debugPrint('❌ [AGORA] Camera failed to start, retrying...');
          if (attempt < maxRetries) continue;
          onError?.call('Camera failed to start. Please check permissions.');
          return false;
        }
        
        // Join channel
        await _engine!.joinChannel(
          token: token,
          channelId: channelName,
          uid: uid,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            autoSubscribeVideo: true,
            autoSubscribeAudio: true,
          ),
        );
        
        // Wait and verify video is publishing
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!_isLocalVideoPublishing && 
            _localVideoState != LocalVideoStreamState.localVideoStreamStateCapturing &&
            _localVideoState != LocalVideoStreamState.localVideoStreamStateEncoding) {
          debugPrint('⚠️ [AGORA] Video not publishing, state: $_localVideoState');
          
          // One more attempt to enable video
          await _engine!.enableLocalVideo(true);
          await _engine!.muteLocalVideoStream(false);
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (_localVideoState == LocalVideoStreamState.localVideoStreamStateFailed) {
            debugPrint('❌ [AGORA] Video failed after retry');
            if (attempt < maxRetries) {
              await leaveChannel();
              continue;
            }
          }
        }
        
        _isBroadcaster = true;
        _currentChannel = channelName;
        debugPrint('✅ [AGORA] Broadcast started successfully');
        notifyListeners();
        return true;
        
      } catch (e) {
        debugPrint('❌ [AGORA] Failed to start broadcasting (attempt $attempt): $e');
        if (attempt >= maxRetries) {
          onError?.call('Failed to start broadcast: $e');
          return false;
        }
      }
    }
    
    return false;
  }
  
  // ============================================
  // AUDIENCE (VIEWER)
  // ============================================
  
  Future<bool> joinAsAudience({
    required String channelName,
    required String token,
    int uid = 0,
  }) async {
    if (!_isInitialized || _engine == null) {
      final initialized = await initialize(forBroadcasting: false);
      if (!initialized) return false;
    }
    
    if (_isJoined) {
      debugPrint('⚠️ [AGORA] Already in a channel, leaving first...');
      await leaveAsViewer();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    try {
      debugPrint('👀 [AGORA] Joining as audience on channel: $channelName');
      
      // Ensure audio/video are enabled before joining
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.muteAllRemoteAudioStreams(false);
      await _engine!.muteAllRemoteVideoStreams(false);
      
      // Set role to AUDIENCE
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      
      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );
      
      _isBroadcaster = false;
      _currentChannel = channelName;
      debugPrint('✅ [AGORA] Joined as audience');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to join as audience: $e');
      onError?.call('Failed to join stream: $e');
      return false;
    }
  }
  
  // ============================================
  // LEAVE / STOP
  // ============================================
  
  Future<void> leaveChannel() async {
    if (!_isJoined || _engine == null) {
      debugPrint('🛑 [AGORA] leaveChannel: not joined or no engine');
      return;
    }
    
    try {
      debugPrint('🛑 [AGORA] Leaving channel...');
      
      // Stop all audio/video FIRST before leaving (prevents lingering audio)
      await _engine!.muteAllRemoteAudioStreams(true);
      await _engine!.muteAllRemoteVideoStreams(true);
      
      // Stop local streams if broadcasting
      if (_isBroadcaster) {
        await _engine!.stopPreview();
        await _engine!.muteLocalAudioStream(true);
        await _engine!.muteLocalVideoStream(true);
      }
      
      // Leave the channel
      await _engine!.leaveChannel();
      
      // Reset state
      _isBroadcaster = false;
      _isJoined = false;
      _currentChannel = null;
      _remoteUsers.clear();
      _broadcasterUid = null;
      _isLocalVideoPublishing = false;
      
      debugPrint('✅ [AGORA] Left channel - audio/video stopped');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to leave channel: $e');
    }
  }
  
  /// Leave channel as viewer - fully cleans up to stop all audio/video
  Future<void> leaveAsViewer() async {
    debugPrint('🛑 [AGORA] leaveAsViewer called, isJoined: $_isJoined');
    
    if (_engine == null) {
      debugPrint('🛑 [AGORA] No engine to leave');
      return;
    }
    
    try {
      // Mute ALL remote streams immediately to stop audio/video
      await _engine!.muteAllRemoteAudioStreams(true);
      await _engine!.muteAllRemoteVideoStreams(true);
      
      // Leave channel (this will trigger onLeaveChannel callback)
      if (_isJoined) {
        await _engine!.leaveChannel();
        
        // Wait for leave to complete
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Reset state
      _isBroadcaster = false;
      _isJoined = false;
      _currentChannel = null;
      _remoteUsers.clear();
      _broadcasterUid = null;
      
      // Re-enable audio/video for next join (don't leave them disabled!)
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.muteAllRemoteAudioStreams(false);
      await _engine!.muteAllRemoteVideoStreams(false);
      
      debugPrint('✅ [AGORA] Viewer left - streams stopped, engine ready for next join');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [AGORA] leaveAsViewer error: $e');
    }
  }
  
  Future<void> stopBroadcasting() async => leaveChannel();
  
  // ============================================
  // VIDEO/AUDIO CONTROLS
  // ============================================
  
  Future<void> toggleVideo() async {
    if (_engine == null) return;
    _isVideoEnabled = !_isVideoEnabled;
    await _engine!.muteLocalVideoStream(!_isVideoEnabled);
    notifyListeners();
  }
  
  Future<void> toggleAudio() async {
    if (_engine == null) return;
    _isAudioEnabled = !_isAudioEnabled;
    await _engine!.muteLocalAudioStream(!_isAudioEnabled);
    notifyListeners();
  }
  
  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }
  
  Future<void> setFlash(bool enabled) async {
    if (_engine == null) return;
    await _engine!.setCameraTorchOn(enabled);
  }
  
  // ============================================
  // CLEANUP
  // ============================================
  
  Future<void> disposeEngine() async {
    debugPrint('🧹 [AGORA] Disposing...');
    
    if (_isJoined) {
      await leaveChannel();
    }
    
    if (_engine != null) {
      try {
        await _engine!.stopPreview();
      } catch (_) {}
      await _engine!.release();
      _engine = null;
    }
    
    _isInitialized = false;
    _isJoined = false;
    _isBroadcaster = false;
    _currentChannel = null;
    _localUid = null;
    _remoteUsers.clear();
    _broadcasterUid = null;
    _isLocalVideoPublishing = false;
    _localVideoState = LocalVideoStreamState.localVideoStreamStateStopped;
    _isVideoEnabled = true;
    _isAudioEnabled = true;
    
    debugPrint('✅ [AGORA] Disposed');
  }
  
  Future<void> renewToken(String newToken) async {
    if (_engine == null) return;
    await _engine!.renewToken(newToken);
    debugPrint('🔄 [AGORA] Token renewed');
  }
  
  /// Refresh token from backend
  Future<String> _refreshToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final liveRepo = getIt<LiveRepository>();
      
      // Call refresh-token endpoint
      final token = await liveRepo.refreshAgoraToken(
        channelName: channelName,
        uid: uid,
        isBroadcaster: _isBroadcaster,
      );
      
      return token;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to fetch new token: $e');
      rethrow;
    }
  }
}
