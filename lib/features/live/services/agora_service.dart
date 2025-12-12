import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Agora Live Streaming Service
/// Handles all Agora RTC Engine operations for live broadcasting
class AgoraService extends ChangeNotifier {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // ============================================
  // AGORA CONFIGURATION - UPDATE THESE VALUES
  // ============================================
  
  /// Your Agora App ID from the Agora Console
  static const String appId = '6358473261094f98be1fea84042b1fcf';
  
  /// Default channel name for testing
  /// Use the same channel name in Agora Web Demo to view the stream
  static const String defaultChannelName = 'abc';

  /// Debug/testing token (TEMPORARY).
  /// NOTE: Tokens expire; for production generate tokens from your backend.
  static const String defaultTestToken =
      '007eJxTYEhu+XhDtOirR7dZ2LQq9ntcaXskEphYKzTjgxZd+r19x2UFBjNjUwsTc2MjM0MDS5M0S4ukVMO01EQLEwMToyTDtOS0G/+tMxsCGRnuPpvJysgAgSA+M0NiUjIDAwAILh+F';
  
  /// Temporary token - Generate from Agora Console for testing
  /// Set to null if App Certificate is disabled (not recommended for production)
  /// For testing: Go to Agora Console > Project > Generate temp token
  String? _token;
  
  // ============================================
  // ENGINE STATE
  // ============================================
  
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isBroadcasting = false;
  String? _currentChannel;
  int? _localUid;
  
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
  
  // ============================================
  // GETTERS
  // ============================================
  
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  bool get isBroadcasting => _isBroadcasting;
  String? get currentChannel => _currentChannel;
  int? get localUid => _localUid;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isFrontCamera => _isFrontCamera;
  
  // ============================================
  // INITIALIZATION
  // ============================================
  
  /// Initialize the Agora RTC Engine
  /// Must be called before any other operations
  Future<bool> initialize() async {
    if (_isInitialized && _engine != null) {
      debugPrint('🎥 [AGORA] Already initialized');
      return true;
    }
    
    try {
      debugPrint('🎥 [AGORA] Initializing RTC Engine...');
      
      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint('❌ [AGORA] Permissions not granted');
        onError?.call('Camera and microphone permissions are required');
        return false;
      }
      
      // Create RTC Engine
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      
      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ [AGORA] Joined channel: ${connection.channelId}, uid: ${connection.localUid}');
          _isJoined = true;
          _localUid = connection.localUid;
          _currentChannel = connection.channelId;
          notifyListeners();
          onJoinChannelSuccess?.call();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('👤 [AGORA] User joined: $remoteUid');
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('👤 [AGORA] User offline: $remoteUid, reason: $reason');
          onUserOffline?.call(remoteUid);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('🚪 [AGORA] Left channel: ${connection.channelId}');
          _isJoined = false;
          _isBroadcasting = false;
          _currentChannel = null;
          notifyListeners();
          onLeaveChannel?.call();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('❌ [AGORA] Error: $err - $msg');
          onError?.call('Agora Error: $msg');
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('⚠️ [AGORA] Token will expire soon');
          // TODO: Implement token refresh logic
        },
      ));
      
      // Enable video
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      
      // Set video encoder configuration for live streaming
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2000,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      
      _isInitialized = true;
      debugPrint('✅ [AGORA] RTC Engine initialized successfully');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Initialization failed: $e');
      onError?.call('Failed to initialize Agora: $e');
      return false;
    }
  }
  
  /// Request camera and microphone permissions
  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    return cameraStatus.isGranted && micStatus.isGranted;
  }
  
  // ============================================
  // BROADCASTING (HOST)
  // ============================================
  
  /// Start broadcasting as a host
  /// [channelName] - The channel name to broadcast on
  /// [token] - The temporary token (optional for testing if App Certificate is disabled)
  Future<bool> startBroadcasting({
    String? channelName,
    String? token,
    int uid = 0, // 0 = auto-assign
  }) async {
    if (!_isInitialized || _engine == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    if (_isJoined) {
      debugPrint('⚠️ [AGORA] Already broadcasting');
      return true;
    }
    
    try {
      final channel = channelName ?? defaultChannelName;
      _token = token;
      
      debugPrint('🎥 [AGORA] Starting broadcast on channel: $channel');
      
      // Set client role to broadcaster (host)
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // Start local video preview
      await _engine!.startPreview();
      
      // Set camera to front by default
      if (_isFrontCamera) {
        await _engine!.switchCamera();
        _isFrontCamera = true;
      }
      
      // Join channel as broadcaster
      await _engine!.joinChannel(
        token: _token ?? '',
        channelId: channel,
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
      
      _isBroadcasting = true;
      _currentChannel = channel;
      debugPrint('✅ [AGORA] Broadcast started on channel: $channel');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to start broadcasting: $e');
      onError?.call('Failed to start broadcast: $e');
      return false;
    }
  }
  
  /// Stop broadcasting and leave the channel
  Future<void> stopBroadcasting() async {
    if (!_isJoined || _engine == null) {
      debugPrint('⚠️ [AGORA] Not broadcasting');
      return;
    }
    
    try {
      debugPrint('🛑 [AGORA] Stopping broadcast...');
      
      await _engine!.stopPreview();
      await _engine!.leaveChannel();
      
      _isBroadcasting = false;
      _isJoined = false;
      _currentChannel = null;
      
      debugPrint('✅ [AGORA] Broadcast stopped');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [AGORA] Failed to stop broadcasting: $e');
    }
  }
  
  // ============================================
  // VIDEO/AUDIO CONTROLS
  // ============================================
  
  /// Toggle local video on/off
  Future<void> toggleVideo() async {
    if (_engine == null) return;
    
    _isVideoEnabled = !_isVideoEnabled;
    await _engine!.muteLocalVideoStream(!_isVideoEnabled);
    debugPrint('📹 [AGORA] Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }
  
  /// Toggle local audio on/off
  Future<void> toggleAudio() async {
    if (_engine == null) return;
    
    _isAudioEnabled = !_isAudioEnabled;
    await _engine!.muteLocalAudioStream(!_isAudioEnabled);
    debugPrint('🎤 [AGORA] Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }
  
  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_engine == null) return;
    
    await _engine!.switchCamera();
    _isFrontCamera = !_isFrontCamera;
    debugPrint('📷 [AGORA] Switched to ${_isFrontCamera ? 'front' : 'back'} camera');
    notifyListeners();
  }
  
  /// Enable/disable camera flash (torch)
  Future<void> setFlash(bool enabled) async {
    if (_engine == null) return;
    
    await _engine!.setCameraTorchOn(enabled);
    debugPrint('🔦 [AGORA] Flash ${enabled ? 'on' : 'off'}');
  }
  
  // ============================================
  // CLEANUP
  // ============================================
  
  /// Dispose the Agora RTC Engine
  /// Call this when the app is closing or the feature is no longer needed
  Future<void> dispose() async {
    debugPrint('🧹 [AGORA] Disposing...');
    
    if (_isJoined) {
      await stopBroadcasting();
    }
    
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
    
    _isInitialized = false;
    _isJoined = false;
    _isBroadcasting = false;
    _currentChannel = null;
    _localUid = null;
    
    debugPrint('✅ [AGORA] Disposed');
  }
  
  // ============================================
  // TOKEN MANAGEMENT
  // ============================================
  
  /// Set the authentication token
  /// Use this to update the token before joining or when the token expires
  void setToken(String token) {
    _token = token;
  }
  
  /// Renew the token (call this when token is about to expire)
  Future<void> renewToken(String newToken) async {
    if (_engine == null) return;
    
    _token = newToken;
    await _engine!.renewToken(newToken);
    debugPrint('🔄 [AGORA] Token renewed');
  }
}

