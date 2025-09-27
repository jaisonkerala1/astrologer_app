import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String contactName;
  final bool isIncoming;
  final String? callId;

  const VideoCallScreen({
    super.key,
    required this.contactName,
    this.isIncoming = false,
    this.callId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Video call service
  final VideoCallService _videoCallService = VideoCallService();
  
  // Call state
  bool _isCallConnected = false;
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isCallEnded = false;
  String _callStatus = 'Connecting...';
  
  // Timer for call duration
  int _callDuration = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    print('🎥 VideoCallScreen initialized for: ${widget.contactName}');
    _setupSystemUI();
    _initializeVideoCall();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _videoCallService.dispose();
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _initializeVideoCall() {
    print('🎥 Initializing video call service...');
    
    // Set up callbacks
    _videoCallService.onCallStatusChanged = (status) {
      print('📞 Call status changed: $status');
      if (mounted) {
        setState(() {
          _callStatus = status;
          if (status == 'Connected') {
            _isCallConnected = true;
            _startCallDurationTimer();
          }
        });
      }
    };

    _videoCallService.onError = (error) {
      if (mounted) {
        setState(() {
          _callStatus = 'Error: $error';
        });
      }
    };

    _videoCallService.onCallEnded = () {
      if (mounted) {
        Navigator.pop(context);
      }
    };

    // Start the call
    if (widget.isIncoming) {
      // For incoming calls, you might want to show accept/reject buttons
      _videoCallService.acceptCall(widget.callId ?? 'mock-call-id');
    } else {
      // For outgoing calls
      _videoCallService.startCall(widget.contactName);
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
    
    // Toggle video stream via service
    _videoCallService.toggleVideo();
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    
    // Toggle audio stream via service
    _videoCallService.toggleAudio();
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    
    // Toggle speaker output
    // This would require platform-specific implementation
  }

  void _endCall() {
    setState(() {
      _isCallEnded = true;
      _callStatus = 'Call ended';
    });
    
    _videoCallService.endCall();
    Navigator.pop(context);
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
                // Remote video (full screen) - Mock implementation
                Positioned.fill(
                  child: Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: themeService.primaryColor,
                            child: Text(
                              widget.contactName.isNotEmpty 
                                  ? widget.contactName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.contactName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _callStatus,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          if (_isCallConnected) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Mock Video Call Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Local video (picture-in-picture) - Mock implementation
                if (_isVideoEnabled && _isCallConnected)
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
                        child: Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mock Video',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
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
