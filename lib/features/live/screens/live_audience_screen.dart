import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/live_stream_model.dart';
import '../services/agora_service.dart';

class LiveAudienceScreen extends StatefulWidget {
  final String streamId;

  const LiveAudienceScreen({
    super.key,
    required this.streamId,
  });

  @override
  State<LiveAudienceScreen> createState() => _LiveAudienceScreenState();
}

class _LiveAudienceScreenState extends State<LiveAudienceScreen>
    with TickerProviderStateMixin {
  final AgoraService _agoraService = AgoraService();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _showControls = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _hideSystemUI();
    _joinStream();
    
    // Listen for stream end events
    _agoraService.addListener(_onAgoraServiceUpdate);
  }
  
  void _onAgoraServiceUpdate() {
    if (mounted) {
      // Check if the current stream has ended
      if (_agoraService.currentStream?.status == LiveStreamStatus.ended) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The live stream has ended.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _agoraService.removeListener(_onAgoraServiceUpdate);
    _showSystemUI();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _joinStream() async {
    final success = await _agoraService.joinLiveStream(widget.streamId);
    if (!success) {
      // Show error message and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join live stream. The stream may have ended.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _agoraService,
        builder: (context, child) {
          final stream = _agoraService.currentStream;
          
          return Stack(
            children: [
              // Stream Video (Mock)
              if (stream != null) _buildStreamVideo(stream),
              
              // Live Indicator
              _buildLiveIndicator(),
              
              // Stream Info Overlay
              if (stream != null) _buildStreamInfoOverlay(stream),
              
              // Viewer Stats
              if (stream != null) _buildViewerStats(stream),
              
              
              // Top Controls
              _buildTopControls(),
              
              // Bottom Controls
              if (stream != null) _buildBottomControls(stream),
              
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreamVideo(LiveStreamModel stream) {
    return ListenableBuilder(
      listenable: _agoraService,
      builder: (context, child) {
        if (_agoraService.isConnected) {
          // Real Agora video view for audience
          return AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _agoraService.agoraEngine!,
              canvas: const VideoCanvas(uid: 12345), // Use broadcaster UID
            ),
          );
        } else {
          // Fallback to loading screen
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to Live Stream...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${stream.astrologerName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildLiveIndicator() {
    return Positioned(
      top: 50,
      left: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreamInfoOverlay(LiveStreamModel stream) {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stream.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  child: Text(
                    stream.astrologerName.isNotEmpty
                        ? stream.astrologerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stream.astrologerName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.7),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  stream.formattedDuration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerStats(LiveStreamModel stream) {
    return Positioned(
      top: 120,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${stream.viewerCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.favorite,
              color: Colors.red.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${stream.likes}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTopControls() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(LiveStreamModel stream) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Row(
          children: [
            
            // Follow Button
            _buildControlButton(
              icon: _isFollowing ? Icons.person_remove : Icons.person_add,
              onTap: () {
                setState(() {
                  _isFollowing = !_isFollowing;
                });
                HapticFeedback.lightImpact();
              },
            ),
            
            const Spacer(),
            
            // Share Button
            _buildControlButton(
              icon: Icons.share,
              onTap: () {
                HapticFeedback.lightImpact();
                _shareStream(stream);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }




  IconData _getCategoryIcon(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return Icons.public;
      case LiveStreamCategory.astrology:
        return Icons.star;
      case LiveStreamCategory.healing:
        return Icons.healing;
      case LiveStreamCategory.meditation:
        return Icons.self_improvement;
      case LiveStreamCategory.tarot:
        return Icons.style;
      case LiveStreamCategory.numerology:
        return Icons.numbers;
      case LiveStreamCategory.palmistry:
        return Icons.contact_page;
      case LiveStreamCategory.spiritual:
        return Icons.auto_awesome;
    }
  }


  void _shareStream(LiveStreamModel stream) {
    // Mock share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
