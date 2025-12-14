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
  
  // Callbacks
  Function(String message)? onError;
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserOffline;
  Function()? onJoinChannelSuccess;
  Function()? onLeaveChannel;
  Function(int uid)? onFirstRemoteVideoFrame;
  
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
  
  // ============================================
  // INITIALIZATION
  // ============================================
  
  Future<bool> initialize({bool forBroadcasting = true}) async {
    if (_isInitialized && _engine != null) {
      debugPrint('🎥 [AGORA] Already initialized');
      return true;
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
          notifyListeners();
          onLeaveChannel?.call();
        },
        onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
          debugPrint('📺 [AGORA] First remote video frame from: $remoteUid (${width}x$height)');
          _broadcasterUid = remoteUid;
          notifyListeners();
          onFirstRemoteVideoFrame?.call(remoteUid);
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
  }) async {
    if (!_isInitialized || _engine == null) {
      final initialized = await initialize(forBroadcasting: true);
      if (!initialized) return false;
    }
    
    if (_isJoined) {
      debugPrint('⚠️ [AGORA] Already in a channel');
      return true;
    }
    
    try {
      debugPrint('🎥 [AGORA] Starting broadcast on channel: $channelName');
      
      // Reset video/audio state for fresh broadcast
      _isVideoEnabled = true;
      _isAudioEnabled = true;
      
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // Ensure video and audio are enabled (not muted from previous session)
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.muteLocalVideoStream(false);
      await _engine!.muteLocalAudioStream(false);
      
      await _engine!.startPreview();
      
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
      
      _isBroadcaster = true;
      _currentChannel = channelName;
      debugPrint('✅ [AGORA] Broadcast started');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to start broadcasting: $e');
      onError?.call('Failed to start broadcast: $e');
      return false;
    }
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
      debugPrint('⚠️ [AGORA] Already in a channel');
      // Leave current channel first
      await leaveChannel();
    }
    
    try {
      debugPrint('👀 [AGORA] Joining as audience on channel: $channelName');
      
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
      return;
    }
    
    try {
      debugPrint('🛑 [AGORA] Leaving channel...');
      
      if (_isBroadcaster) {
        await _engine!.stopPreview();
      }
      await _engine!.leaveChannel();
      
      _isBroadcaster = false;
      _isJoined = false;
      _currentChannel = null;
      _remoteUsers.clear();
      _broadcasterUid = null;
      
      debugPrint('✅ [AGORA] Left channel');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to leave channel: $e');
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
