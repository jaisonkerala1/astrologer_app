import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/di/service_locator.dart';
import '../models/communication_item.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';

/// Voice-only call screen with Agora audio
class VoiceCallScreen extends StatefulWidget {
  final String callId;
  final String contactId;
  final String contactName;
  final ContactType contactType;
  final String channelName;
  final String token;
  final String agoraAppId;
  final String? avatarUrl;

  const VoiceCallScreen({
    super.key,
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    required this.channelName,
    required this.token,
    required this.agoraAppId,
    this.avatarUrl,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  late final SocketService _socketService;
  
  RtcEngine? _agoraEngine;
  bool _isDisposing = false;
  bool _isCallConnected = false;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = true; // Start with speaker ON for voice calls
  bool _isCallEnded = false;
  String _callStatus = 'Connecting...';
  
  int _callDuration = 0;
  Timer? _durationTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    print('📞 [VOICE] VoiceCallScreen initialized for ${widget.contactName}');
    
    _socketService = getIt<SocketService>();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeAgora();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _durationTimer?.cancel();
    _pulseController.dispose();
    _leaveChannel();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    try {
      print('📞 [VOICE] Requesting microphone permission...');
      
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!mounted || _isDisposing) return;
      if (!status.isGranted) {
        if (!mounted || _isDisposing) return;
        setState(() {
          _callStatus = 'Microphone permission denied';
        });
        return;
      }
      
      print('📞 [VOICE] Creating Agora engine with APP_ID: ${widget.agoraAppId}');
      
      // Create Agora engine
      final engine = createAgoraRtcEngine();
      _agoraEngine = engine;
      
      print('📞 [VOICE] Initializing RTC engine...');
      await engine.initialize(RtcEngineContext(
        appId: widget.agoraAppId,
      ));
      if (!mounted || _isDisposing) return;
      
      print('📞 [VOICE] ✅ Engine initialized successfully');
      print('📞 [VOICE] Setting up event handlers...');
      
      // Register event handlers
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            print('📞 [VOICE] Joined channel: ${connection.channelId}');
            
            // Enable speaker AFTER joining channel
            try {
              await engine.setEnableSpeakerphone(true);
              print('📞 [VOICE] ✅ Speaker enabled');
            } catch (e) {
              print('⚠️ [VOICE] Could not enable speaker: $e');
            }
            
            if (!mounted || _isDisposing) return;
            setState(() {
              _isCallConnected = true;
              _callStatus = 'Connected';
            });
            _startCallDurationTimer();
            _notifyCallConnected();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('📞 [VOICE] Remote user joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('📞 [VOICE] Remote user left: $remoteUid');
            if (mounted) {
              _endCall();
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('📞 [VOICE] Left channel');
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ [VOICE] Agora error: $err - $msg');
          },
        ),
      );
      
      // Small delay to ensure engine is ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _isDisposing) return;
      
      print('📞 [VOICE] Enabling audio...');
      await engine.enableAudio();
      if (!mounted || _isDisposing) return;
      
      print('📞 [VOICE] Setting audio profile...');
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      if (!mounted || _isDisposing) return;
      
      print('📞 [VOICE] Joining channel: ${widget.channelName} with token');
      
      // Join channel
      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0, // Auto-assign UID
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
        ),
      );
      if (!mounted || _isDisposing) return;
      
      print('📞 [VOICE] ✅ Join channel request sent');
      
    } catch (e) {
      print('❌ [VOICE] Error initializing Agora: $e');
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
      print('❌ [VOICE] Error leaving channel: $e');
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

  void _notifyCallConnected() {
    try {
      _socketService.notifyCallConnected(
        callId: widget.callId,
        contactId: widget.contactId,
      );
      print('✅ [VOICE] Call connected notification sent');
    } catch (e) {
      print('❌ [VOICE] Error notifying call connected: $e');
    }
  }

  void _toggleMute() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    _agoraEngine?.muteLocalAudioStream(!_isAudioEnabled);
    print('🎙️ [VOICE] Audio ${_isAudioEnabled ? "enabled" : "muted"}');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    _agoraEngine?.setEnableSpeakerphone(_isSpeakerEnabled);
    print('🔊 [VOICE] Speaker ${_isSpeakerEnabled ? "enabled" : "disabled"}');
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Column(
                    children: [
                      Text(
                        _callStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (_isCallConnected)
                        Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Avatar and name
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isCallConnected ? 1.0 : _pulseAnimation.value,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white24,
                    backgroundImage: widget.avatarUrl != null
                        ? NetworkImage(widget.avatarUrl!)
                        : null,
                    child: widget.avatarUrl == null
                        ? Icon(
                            widget.contactType == ContactType.admin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 80,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.contactType == ContactType.admin ? 'Admin Support' : 'User',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const Spacer(),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                    label: _isAudioEnabled ? 'Mute' : 'Unmute',
                    onPressed: _toggleMute,
                    backgroundColor: _isAudioEnabled ? Colors.white24 : Colors.red,
                  ),
                  
                  // Speaker button
                  _buildControlButton(
                    icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    onPressed: _toggleSpeaker,
                    backgroundColor: _isSpeakerEnabled ? Colors.blue : Colors.white24,
                  ),
                  
                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 70,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white24,
    double size = 60,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size / 2),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
