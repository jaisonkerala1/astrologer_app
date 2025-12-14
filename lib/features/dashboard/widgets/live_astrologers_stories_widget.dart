import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/repositories/live/live_repository.dart';
import 'live_astrologer_circle_widget.dart';
import '../../live/screens/live_feed_screen.dart';
import '../../live/screens/live_stream_viewer_screen.dart';
import '../../live/bloc/live_feed_bloc.dart';
import '../../live/data/repositories/mock_live_feed_repository.dart';
import '../../live/bloc/live_feed_event.dart';
import '../../live/screens/view_all_live_screen.dart';
import '../../live/models/live_stream_model.dart';

class LiveAstrologersStoriesWidget extends StatefulWidget {
  const LiveAstrologersStoriesWidget({super.key});

  @override
  State<LiveAstrologersStoriesWidget> createState() => _LiveAstrologersStoriesWidgetState();
}

class _LiveAstrologersStoriesWidgetState extends State<LiveAstrologersStoriesWidget> {
  List<LiveStreamModel> _liveStreams = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  // Socket subscriptions for real-time updates
  late final SocketService _socketService;
  StreamSubscription<Map<String, dynamic>>? _streamStartedSub;
  StreamSubscription<Map<String, dynamic>>? _streamEndedSub;

  @override
  void initState() {
    super.initState();
    _socketService = getIt<SocketService>();
    _fetchActiveLiveStreams();
    _setupSocketListeners();
  }
  
  @override
  void dispose() {
    _streamStartedSub?.cancel();
    _streamEndedSub?.cancel();
    super.dispose();
  }
  
  /// Setup real-time socket listeners
  void _setupSocketListeners() {
    // Listen for new streams
    _streamStartedSub = _socketService.streamStartedStream.listen((data) {
      debugPrint('🔴 [DASHBOARD] New stream started: ${data['astrologerName']}');
      _fetchActiveLiveStreams(); // Refresh list
    });
    
    // Listen for ended streams
    _streamEndedSub = _socketService.streamEndedStream.listen((data) {
      debugPrint('⬛ [DASHBOARD] Stream ended: ${data['streamId']}');
      _fetchActiveLiveStreams(); // Refresh list
    });
    
    debugPrint('📡 [DASHBOARD] Real-time live stream listeners active');
  }

  Future<void> _fetchActiveLiveStreams() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final liveRepo = getIt<LiveRepository>();
      final streams = await liveRepo.getActiveLiveStreams();
      
      if (mounted) {
        setState(() {
          _liveStreams = streams;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live streams: $e');
      if (mounted) {
        setState(() {
          _liveStreams = [];
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide completely if no live streams and not loading
    if (!_isLoading && _liveStreams.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double containerHeight = screenWidth < 360
        ? 122.0
        : screenWidth < 400
            ? 134.0
            : 146.0;
    final double titleFontSize = screenWidth < 360 ? 14.0 : 16.0;
    final double buttonFontSize = screenWidth < 360 ? 11.0 : 12.0;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: containerHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    // Pulsing red dot
                    _buildPulsingDot(),
                    const SizedBox(width: 8),
                    Text(
                      'Live Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeService.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: titleFontSize,
                      ),
                    ),
                    if (_liveStreams.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_liveStreams.length}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_liveStreams.isNotEmpty)
                    GestureDetector(
                        onTap: () => _navigateToViewAll(context),
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
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _buildContent(themeService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
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
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildContent(ThemeService themeService) {
    if (_isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSkeletonItem(themeService),
          );
        },
      );
    }

    if (_hasError || _liveStreams.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      itemCount: _liveStreams.length,
      itemBuilder: (context, index) {
        final stream = _liveStreams[index];
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: LiveAstrologerCircleWidget(
            astrologer: MockLiveAstrologer(
              id: stream.astrologerId,
              name: stream.astrologerName,
              profilePicture: stream.astrologerProfilePicture,
              specialty: stream.astrologerSpecialty,
              viewerCount: stream.viewerCount,
              isLive: stream.isLive,
              liveStreamUrl: '',
              thumbnailUrl: stream.thumbnailUrl ?? '',
            ),
            onTap: () => _handleAstrologerTap(context, stream),
            onLongPress: () => _handleAstrologerLongPress(context, stream),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonItem(ThemeService themeService) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeService.isDarkMode()
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 50,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: themeService.isDarkMode()
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  void _handleAstrologerTap(BuildContext context, LiveStreamModel stream) async {
    HapticFeedback.lightImpact();
    
    debugPrint('📺 [DASHBOARD] Tapped stream: ${stream.astrologerName}');
    debugPrint('📺 [DASHBOARD] Channel: ${stream.channelName}');
    debugPrint('📺 [DASHBOARD] Token: ${stream.agoraToken?.substring(0, 20)}...');
    
    try {
      // Navigate directly to viewer screen with real stream data
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamViewerScreen(
            liveStream: stream,
          ),
        ),
      );

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      debugPrint('❌ [DASHBOARD] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join live stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAstrologerLongPress(BuildContext context, LiveStreamModel stream) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${stream.astrologerName} - ${stream.astrologerSpecialty}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToViewAll(BuildContext context) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => LiveFeedBloc(
            repository: MockLiveFeedRepository(),
          )..add(const LoadLiveFeedEvent()),
          child: const ViewAllLiveScreen(),
        ),
      ),
    );
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}

// Keep for backward compatibility with LiveAstrologerCircleWidget
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
