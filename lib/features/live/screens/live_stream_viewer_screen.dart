import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../widgets/live_stream_controls_widget.dart';
import '../widgets/live_stream_info_widget.dart';
import '../widgets/live_stream_comments_widget.dart';
import '../widgets/live_stream_reactions_widget.dart';
import '../widgets/live_stream_gift_widget.dart';
import '../services/live_stream_service.dart';

class LiveStreamViewerScreen extends StatefulWidget {
  final LiveStreamModel liveStream;

  const LiveStreamViewerScreen({
    super.key,
    required this.liveStream,
  });

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isControlsVisible = true;
  bool _isCommentsVisible = false;
  bool _isGiftsVisible = false;
  bool _isReactionsVisible = false;
  bool _isStreamActive = true;
  
  final LiveStreamService _liveStreamService = LiveStreamService();
  final ScrollController _commentsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSystemUI();
    _joinLiveStream();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
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

  Future<void> _joinLiveStream() async {
    try {
      await _liveStreamService.joinLiveStream(widget.liveStream.id);
      // Simulate stream connection
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isStreamActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to join live stream: $e');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _commentsScrollController.dispose();
    _liveStreamService.leaveLiveStream(widget.liveStream.id);
    _restoreSystemUI();
    super.dispose();
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _toggleComments() {
    setState(() {
      _isCommentsVisible = !_isCommentsVisible;
      if (_isCommentsVisible) {
        _isGiftsVisible = false;
        _isReactionsVisible = false;
      }
    });
  }

  void _toggleGifts() {
    setState(() {
      _isGiftsVisible = !_isGiftsVisible;
      if (_isGiftsVisible) {
        _isCommentsVisible = false;
        _isReactionsVisible = false;
      }
    });
  }

  void _toggleReactions() {
    setState(() {
      _isReactionsVisible = !_isReactionsVisible;
      if (_isReactionsVisible) {
        _isCommentsVisible = false;
        _isGiftsVisible = false;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Main video area
              _buildVideoArea(themeService),
              
              // Top gradient overlay
              _buildTopGradient(),
              
              // Bottom gradient overlay
              _buildBottomGradient(),
              
              // Live indicator
              _buildLiveIndicator(),
              
              // Stream info
              _buildStreamInfo(themeService),
              
              // Viewer count
              _buildViewerCount(),
              
              // Main controls
              if (_isControlsVisible) _buildMainControls(),
              
              // Comments panel
              if (_isCommentsVisible) _buildCommentsPanel(themeService),
              
              // Gifts panel
              if (_isGiftsVisible) _buildGiftsPanel(themeService),
              
              // Reactions panel
              if (_isReactionsVisible) _buildReactionsPanel(themeService),
              
              // Tap to toggle controls
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoArea(ThemeService themeService) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeService.primaryColor.withOpacity(0.8),
            themeService.primaryColor.withOpacity(0.6),
            Colors.black.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Mock video background
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeService.primaryColor.withOpacity(0.3),
                    themeService.secondaryColor.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 80,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Live Stream',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mock Video Feed',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Stream status overlay
          if (!_isStreamActive)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to live stream...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
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
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamInfo(ThemeService themeService) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: LiveStreamInfoWidget(
          liveStream: widget.liveStream,
          onProfileTap: () {
            // TODO: Navigate to astrologer profile
          },
        ),
      ),
    );
  }

  Widget _buildViewerCount() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 100,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.liveStream.viewerCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: LiveStreamControlsWidget(
          onCommentsTap: _toggleComments,
          onGiftsTap: _toggleGifts,
          onReactionsTap: _toggleReactions,
          onShareTap: () {
            // TODO: Implement share functionality
          },
          onReportTap: () {
            // TODO: Implement report functionality
          },
        ),
      ),
    );
  }

  Widget _buildCommentsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 300,
      child: SlideTransition(
        position: _slideAnimation,
        child: LiveStreamCommentsWidget(
          liveStreamId: widget.liveStream.id,
          scrollController: _commentsScrollController,
          onClose: _toggleComments,
        ),
      ),
    );
  }

  Widget _buildGiftsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 200,
      child: SlideTransition(
        position: _slideAnimation,
        child: LiveStreamGiftWidget(
          liveStreamId: widget.liveStream.id,
          onClose: _toggleGifts,
        ),
      ),
    );
  }

  Widget _buildReactionsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 150,
      child: SlideTransition(
        position: _slideAnimation,
        child: LiveStreamReactionsWidget(
          liveStreamId: widget.liveStream.id,
          onClose: _toggleReactions,
        ),
      ),
    );
  }
}


