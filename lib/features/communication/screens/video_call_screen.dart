import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/di/service_locator.dart';
import '../models/communication_item.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';

/// Generic VideoCallScreen that works for:
/// - Admin ↔ Astrologer video calls
/// - User ↔ Astrologer video calls (future)
class VideoCallScreen extends StatefulWidget {
  final String contactId;          // Generic contact ID
  final String contactName;
  final ContactType contactType;   // 'admin', 'user', or 'astrologer'
  final bool isIncoming;
  final String callId;
  final String channelName;        // Agora channel name
  final String token;              // Agora token
  final String? avatarUrl;

  const VideoCallScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    this.isIncoming = false,
    required this.callId,
    required this.channelName,
    required this.token,
    this.avatarUrl,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Services
  late final SocketService _socketService;
  
  // Agora engine
  RtcEngine? _agoraEngine;
  bool _isDisposing = false;
  int? _remoteUid;
  bool _isJoined = false;
  
  // Call state
  bool _isCallConnected = false;
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = true;
  bool _isCallEnded = false;
  bool _isFrontCamera = true;
  String _callStatus = 'Connecting...';
  
  // Timer for call duration
  int _callDuration = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    print('🎥 [VIDEO] VideoCallScreen initialized for: ${widget.contactName}');
    
    _socketService = getIt<SocketService>();
    _setupSystemUI();
    _initializeAgora();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _durationTimer?.cancel();
    _leaveChannel();
    _restoreSystemUI();
    super.dispose();
  }

  void _setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _restoreSystemUI() {
    // Use manual mode to show navigation bar properly (fixes bottom nav hidden bug)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom], // Show both bars
    );
    
    // Restore the style to match main.dart
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Match main.dart
        statusBarBrightness: Brightness.light, // For iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _initializeAgora() async {
    try {
      print('🎥 [VIDEO] Requesting permissions...');
      
      // Request camera and microphone permissions
      await [Permission.camera, Permission.microphone].request();
      if (!mounted || _isDisposing) return;
      
      print('🎥 [VIDEO] Creating Agora engine with APP_ID: 6358473261094f98be1fea84042b1fcf');
      
      // Create Agora engine
      final engine = createAgoraRtcEngine();
      _agoraEngine = engine;
      
      print('🎥 [VIDEO] Initializing RTC engine...');
      await engine.initialize(const RtcEngineContext(
        appId: '6358473261094f98be1fea84042b1fcf',
      ));
      if (!mounted || _isDisposing) return;
      
      print('🎥 [VIDEO] ✅ Engine initialized successfully');
      
      // Register event handlers
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            print('🎥 [VIDEO] Joined channel: ${connection.channelId}');
            
            // Enable speaker AFTER joining
            try {
              await engine.setEnableSpeakerphone(true);
              print('🎥 [VIDEO] ✅ Speaker enabled');
            } catch (e) {
              print('⚠️ [VIDEO] Could not enable speaker: $e');
            }
            
            if (!mounted || _isDisposing) return;
            setState(() {
              _isJoined = true;
              _isCallConnected = true;
              _callStatus = 'Connected';
            });
            _startCallDurationTimer();
            _notifyCallConnected();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('🎥 [VIDEO] Remote user joined: $remoteUid');
            if (!mounted || _isDisposing) return;
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('🎥 [VIDEO] Remote user left: $remoteUid');
            if (!mounted || _isDisposing) return;
            setState(() {
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ [VIDEO] Agora error: $err - $msg');
          },
        ),
      );
      
      // Enable video
      await engine.enableVideo();
      if (!mounted || _isDisposing) return;
      
      // Start local preview
      await engine.startPreview();
      if (!mounted || _isDisposing) return;
      
      print('🎥 [VIDEO] Joining channel: ${widget.channelName}');
      
      // Join channel
      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
      if (!mounted || _isDisposing) return;
      
      print('🎥 [VIDEO] ✅ Join channel request sent');
      
    } catch (e) {
      print('❌ [VIDEO] Error initializing Agora: $e');
      if (!mounted || _isDisposing) return;
      setState(() {
        _callStatus = 'Failed to connect';
      });
    }
  }

  Future<void> _leaveChannel() async {
    try {
      if (_agoraEngine != null) {
        await _agoraEngine!.leaveChannel();
        await _agoraEngine!.release();
        _agoraEngine = null;
      }
    } catch (e) {
      print('❌ [VIDEO] Error leaving channel: $e');
    }
  }

  void _notifyCallConnected() {
    try {
      _socketService.notifyCallConnected(
        callId: widget.callId,
        contactId: widget.contactId,
      );
      print('✅ [VIDEO] Call connected notification sent');
    } catch (e) {
      print('❌ [VIDEO] Error notifying call connected: $e');
    }
  }

  void _startCallDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }


  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _agoraEngine?.muteLocalVideoStream(!_isVideoEnabled);
    print('📹 [VIDEO] Camera ${_isVideoEnabled ? "enabled" : "disabled"}');
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    _agoraEngine?.muteLocalAudioStream(!_isAudioEnabled);
    print('🎙️ [VIDEO] Audio ${_isAudioEnabled ? "enabled" : "muted"}');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    _agoraEngine?.setEnableSpeakerphone(_isSpeakerEnabled);
    print('🔊 [VIDEO] Speaker ${_isSpeakerEnabled ? "enabled" : "disabled"}');
  }

  void _switchCamera() {
    _agoraEngine?.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    print('📷 [VIDEO] Switched to ${_isFrontCamera ? "front" : "back"} camera');
  }

  void _endCall() {
    if (_isCallEnded) return;

    setState(() {
      _isCallEnded = true;
      _callStatus = 'Call ended';
    });

    // Notify backend via BLoC
    context.read<CallBloc>().add(EndCallEvent(
      callId: widget.callId,
      contactId: widget.contactId,
      duration: _callDuration,
      reason: 'completed',
    ));

    // Clean up and close
    _durationTimer?.cancel();
    _leaveChannel();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Remote video (full screen) - Real Agora view
                Positioned.fill(
                  child: _remoteUid != null
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _agoraEngine!,
                            canvas: VideoCanvas(uid: _remoteUid),
                            connection: RtcConnection(channelId: widget.channelName),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.contactType == ContactType.admin)
                                  const Icon(
                                    Icons.support_agent,
                                    size: 80,
                                    color: Colors.white54,
                                  )
                                else
                                  const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white54,
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  _isJoined ? 'Waiting for ${widget.contactName}...' : _callStatus,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                if (_isCallConnected) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDuration(_callDuration),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),

                // Local video (picture-in-picture) - Real camera preview
                Positioned(
                  top: 60,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.grey[800],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _isJoined && _isVideoEnabled
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _agoraEngine!,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),

                // Top bar with call info
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCallConnected ? Icons.videocam : Icons.videocam_off,
                          color: _isCallConnected ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.contactName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _callStatus,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute/Unmute
                        _buildControlButton(
                          icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                          isActive: _isAudioEnabled,
                          onTap: _toggleAudio,
                        ),
                        
                        // Video On/Off
                        _buildControlButton(
                          icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          isActive: _isVideoEnabled,
                          onTap: _toggleVideo,
                        ),
                        
                        // Speaker
                        _buildControlButton(
                          icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                          isActive: _isSpeakerEnabled,
                          onTap: _toggleSpeaker,
                        ),
                        
                        // Switch Camera
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          isActive: true,
                          onTap: _switchCamera,
                        ),
                        
                        // End Call
                        _buildControlButton(
                          icon: Icons.call_end,
                          isActive: false,
                          backgroundColor: Colors.red,
                          onTap: _endCall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: backgroundColor != null ? Colors.white : (isActive ? Colors.black : Colors.white),
          size: 28,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
