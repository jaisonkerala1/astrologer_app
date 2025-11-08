import 'package:flutter/material.dart';
import '../models/live_stream_model.dart';
import 'live_stream_viewer_screen.dart';

/// Individual live stream page for vertical feed
/// Wraps the existing LiveStreamViewerScreen for reusability
/// Handles stream lifecycle (join/leave) based on visibility
class LiveStreamViewerPage extends StatefulWidget {
  final LiveStreamModel stream;
  final bool isActive;
  final VoidCallback onExit;
  
  const LiveStreamViewerPage({
    super.key,
    required this.stream,
    required this.isActive,
    required this.onExit,
  });

  @override
  State<LiveStreamViewerPage> createState() => _LiveStreamViewerPageState();
}

class _LiveStreamViewerPageState extends State<LiveStreamViewerPage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when scrolling
  
  bool _hasJoined = false;
  
  @override
  void initState() {
    super.initState();
    // Join stream if active initially
    if (widget.isActive) {
      _joinStream();
    }
  }
  
  @override
  void didUpdateWidget(LiveStreamViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Stream lifecycle management (Instagram-style)
    if (widget.isActive && !oldWidget.isActive) {
      // Stream became active - join it
      _joinStream();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Stream became inactive - leave it
      _leaveStream();
    }
  }
  
  @override
  void dispose() {
    // Always leave stream on dispose
    if (_hasJoined) {
      _leaveStream();
    }
    super.dispose();
  }
  
  void _joinStream() {
    if (_hasJoined) return;
    
    // TODO: Real implementation with Agora
    // - Get token from backend
    // - Join Agora channel
    // - Start receiving video/audio
    
    print('📹 Joined stream: ${widget.stream.id} - ${widget.stream.title}');
    _hasJoined = true;
  }
  
  void _leaveStream() {
    if (!_hasJoined) return;
    
    // TODO: Real implementation with Agora
    // - Leave Agora channel
    // - Cleanup resources
    // - Stop receiving video/audio
    
    print('🚪 Left stream: ${widget.stream.id}');
    _hasJoined = false;
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Use existing LiveStreamViewerScreen with the stream data
    return LiveStreamViewerScreen(
      liveStream: widget.stream,
      isActive: widget.isActive,
      onExit: widget.onExit,
    );
  }
}

