import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'live_astrologer_circle_widget.dart';
import '../../live/services/agora_service.dart';
import '../../live/models/live_stream_model.dart';
import '../../../core/services/websocket_service.dart';

class LiveAstrologersStoriesWidget extends StatefulWidget {
  const LiveAstrologersStoriesWidget({super.key});

  @override
  State<LiveAstrologersStoriesWidget> createState() => _LiveAstrologersStoriesWidgetState();
}

class _LiveAstrologersStoriesWidgetState extends State<LiveAstrologersStoriesWidget> {
  AgoraService? _agoraService;
  WebSocketService? _webSocketService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    // Initialize Agora service
    _agoraService = AgoraService();
    await _agoraService!.initialize();
    
    // Initialize WebSocket service for real-time updates
    _webSocketService = WebSocketService();
    await _webSocketService!.connect();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Don't dispose the singleton instance, just clear the reference
    _agoraService = null;
    _webSocketService = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: 140, // Increased height to prevent overflow
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with "Live Now" title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeService.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    // Live stream count
                    if (_agoraService != null)
                      Text(
                        ' (${_getLiveStreams().length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeService.textSecondary,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Navigate to all live streams
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/live-streaming-page');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeService.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: themeService.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Horizontal scrolling live astrologers
              Expanded(
                child: _agoraService != null && _webSocketService != null
                    ? ListenableBuilder(
                        listenable: _webSocketService!,
                        builder: (context, child) => _buildLiveStreamsList(),
                      )
                    : _buildNoLiveStreamsMessage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveStreamsList() {
    final liveStreams = _getLiveStreams();
    
    if (liveStreams.isEmpty) {
      return _buildNoLiveStreamsMessage();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      itemCount: liveStreams.length,
      itemBuilder: (context, index) {
        final stream = liveStreams[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16), // Increased spacing
          child: LiveAstrologerCircleWidget(
            astrologer: _convertStreamToAstrologer(stream),
            onTap: () => _handleStreamTap(context, stream),
            onLongPress: () => _handleStreamLongPress(context, stream),
          ),
        );
      },
    );
  }

  Widget _buildNoLiveStreamsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 32,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No live streams currently',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<LiveStreamModel> _getLiveStreams() {
    if (_agoraService == null || _webSocketService == null) return [];
    
    List<LiveStreamModel> allLiveStreams = [];
    
    // Get live streams from WebSocket service (real-time updates from backend)
    allLiveStreams.addAll(
      _webSocketService!.activeStreams
          .where((stream) => stream.status == LiveStreamStatus.live)
          .toList()
    );
    
    // Add current stream if it's live (for the broadcaster)
    if (_agoraService!.currentStream != null && 
        _agoraService!.currentStream!.status == LiveStreamStatus.live) {
      allLiveStreams.add(_agoraService!.currentStream!);
    }
    
    // Remove duplicates based on stream ID
    final uniqueStreams = <String, LiveStreamModel>{};
    for (final stream in allLiveStreams) {
      uniqueStreams[stream.id] = stream;
    }
    
    return uniqueStreams.values.toList();
  }

  // Convert LiveStreamModel to the format expected by LiveAstrologerCircleWidget
  dynamic _convertStreamToAstrologer(LiveStreamModel stream) {
    return MockLiveAstrologer(
      id: stream.id,
      name: stream.astrologerName,
      profilePicture: stream.astrologerProfilePicture,
      specialty: _getCategoryDisplayName(stream.category),
      viewerCount: stream.viewerCount,
      isLive: stream.status == LiveStreamStatus.live,
      liveStreamUrl: stream.streamUrl,
      thumbnailUrl: stream.thumbnailUrl ?? '',
    );
  }

  String _getCategoryDisplayName(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.tarot:
        return 'Tarot Reading';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
      case LiveStreamCategory.general:
      default:
        return 'General';
    }
  }

  void _handleStreamTap(BuildContext context, LiveStreamModel stream) {
    HapticFeedback.lightImpact();
    // Navigate to live audience screen to join the stream
    Navigator.pushNamed(
      context, 
      '/live-audience',
      arguments: {'streamId': stream.id},
    );
  }

  void _handleStreamLongPress(BuildContext context, LiveStreamModel stream) {
    HapticFeedback.mediumImpact();
    // Show stream details modal
    _showStreamDetails(context, stream);
  }

  void _showStreamDetails(BuildContext context, LiveStreamModel stream) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stream title
              Text(
                stream.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Astrologer info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: Text(
                      stream.astrologerName.isNotEmpty 
                          ? stream.astrologerName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.astrologerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getCategoryDisplayName(stream.category),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stream stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.visibility, '${stream.viewerCount}', 'Viewers'),
                  _buildStatItem(Icons.favorite, '${stream.likes}', 'Likes'),
                  _buildStatItem(Icons.chat, '${stream.comments}', 'Comments'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleStreamTap(context, stream);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Join Live Stream',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Keep old methods for backwards compatibility
  void _handleAstrologerTap(BuildContext context, MockLiveAstrologer astrologer) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining ${astrologer.name}\'s live stream...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAstrologerLongPress(BuildContext context, MockLiveAstrologer astrologer) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${astrologer.name} - ${astrologer.specialty}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<MockLiveAstrologer> _getMockLiveAstrologers() {
    return [
      MockLiveAstrologer(
        id: '1',
        name: 'Priya Sharma',
        profilePicture: null,
        specialty: 'Vedic Astrology',
        viewerCount: 234,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '2',
        name: 'Raj Kumar',
        profilePicture: null,
        specialty: 'Tarot Reading',
        viewerCount: 189,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '3',
        name: 'Anita Singh',
        profilePicture: null,
        specialty: 'Numerology',
        viewerCount: 156,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '4',
        name: 'Vikram Joshi',
        profilePicture: null,
        specialty: 'Palmistry',
        viewerCount: 98,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '5',
        name: 'Sita Devi',
        profilePicture: null,
        specialty: 'Crystal Healing',
        viewerCount: 312,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '6',
        name: 'Arjun Patel',
        profilePicture: null,
        specialty: 'Vastu Shastra',
        viewerCount: 67,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '7',
        name: 'Meera Jain',
        profilePicture: null,
        specialty: 'Palmistry',
        viewerCount: 145,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
      MockLiveAstrologer(
        id: '8',
        name: 'Krishna Das',
        profilePicture: null,
        specialty: 'Vedic Remedies',
        viewerCount: 278,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: '', // Use fallback avatar instead
      ),
    ];
  }
}

// Mock data class
class MockLiveAstrologer {
  final String id;
  final String name;
  final String? profilePicture;
  final String specialty;
  final int viewerCount;
  final bool isLive;
  final String liveStreamUrl;
  final String thumbnailUrl;

  MockLiveAstrologer({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.specialty,
    required this.viewerCount,
    required this.isLive,
    required this.liveStreamUrl,
    required this.thumbnailUrl,
  });
}
