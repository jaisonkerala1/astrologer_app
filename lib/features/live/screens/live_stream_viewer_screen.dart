import 'dart:async';
import 'dart:math';
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
  bool _isFloatingCommentsVisible = true; // Floating comments visibility
  bool _isExpandedCommentsVisible = false; // Expanded panel visibility
  bool _isGiftsVisible = false;
  bool _isStreamActive = true;
  
  final LiveStreamService _liveStreamService = LiveStreamService();
  final ScrollController _commentsScrollController = ScrollController();
  Timer? _commentSimulationTimer;
  final List<Map<String, String>> _floatingComments = [];
  final Random _random = Random();
  final List<FloatingHeart> _floatingHearts = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSystemUI();
    _joinLiveStream();
    _startCommentSimulation();
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
    _commentSimulationTimer?.cancel();
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

  void _toggleFloatingComments() {
    setState(() {
      _isFloatingCommentsVisible = !_isFloatingCommentsVisible;
    });
  }

  void _openExpandedComments() {
    setState(() {
      _isExpandedCommentsVisible = true;
      _isGiftsVisible = false;
    });
  }

  void _closeExpandedComments() {
    setState(() {
      _isExpandedCommentsVisible = false;
    });
  }

  void _toggleGifts() {
    setState(() {
      _isGiftsVisible = !_isGiftsVisible;
      if (_isGiftsVisible) {
        _isExpandedCommentsVisible = false;
      }
    });
  }

  void _sendHeartReaction() {
    HapticFeedback.mediumImpact();
    
    // Add 3-5 hearts with random positions
    final heartCount = 3 + _random.nextInt(3);
    for (int i = 0; i < heartCount; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          setState(() {
            _floatingHearts.add(FloatingHeart(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
              startX: 0.3 + (_random.nextDouble() * 0.4), // Random X between 30-70%
            ));
          });
          
          // Remove heart after animation completes (3 seconds)
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _floatingHearts.removeWhere((heart) => 
                  heart.id == DateTime.now().millisecondsSinceEpoch.toString() + i.toString()
                );
              });
            }
          });
        }
      });
    }
    
    // Send to backend
    try {
      _liveStreamService.sendReaction(widget.liveStream.id, '❤️');
    } catch (e) {
      // Silently fail - animation still shows
    }
  }

  void _startCommentSimulation() {
    // Add initial comments
    _addSimulatedComment();
    
    // Add new comment every 3-5 seconds
    _commentSimulationTimer = Timer.periodic(
      Duration(seconds: 3 + _random.nextInt(3)),
      (timer) {
        if (mounted) {
          _addSimulatedComment();
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _addSimulatedComment() {
    final dummyComments = [
      {'user': 'Arjun K.', 'message': 'Great insights Guruji! 🙏', 'emoji': '🙏'},
      {'user': 'Sneha R.', 'message': 'Can you do my reading next? ⭐', 'emoji': '⭐'},
      {'user': 'Vikram M.', 'message': 'This is so accurate! ✨', 'emoji': '✨'},
      {'user': 'Divya S.', 'message': 'Thank you for sharing! 🌟', 'emoji': '🌟'},
      {'user': 'Rohan P.', 'message': 'Amazing predictions! 🔮', 'emoji': '🔮'},
      {'user': 'Anjali L.', 'message': 'Very helpful session 💫', 'emoji': '💫'},
      {'user': 'Karthik J.', 'message': 'Love your energy! 💖', 'emoji': '💖'},
      {'user': 'Meera T.', 'message': 'Please explain more about Mercury 🪐', 'emoji': '🪐'},
      {'user': 'Sanjay N.', 'message': 'Watching from Mumbai! 🌺', 'emoji': '🌺'},
      {'user': 'Kavya M.', 'message': 'Can you talk about career? 💼', 'emoji': '💼'},
      {'user': 'Aditya B.', 'message': 'Following you since last year! 🎉', 'emoji': '🎉'},
      {'user': 'Pooja K.', 'message': 'Beautiful reading! 🌸', 'emoji': '🌸'},
    ];

    setState(() {
      // Keep only last 4 comments
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      
      // Add new random comment
      final randomComment = dummyComments[_random.nextInt(dummyComments.length)];
      _floatingComments.add(randomComment);
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
              
              // Tap to toggle controls (must be before buttons so buttons are on top)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  child: Container(color: Colors.transparent),
                ),
              ),
              
              // Live indicator
              _buildLiveIndicator(),
              
              // Stream info
              _buildStreamInfo(themeService),
              
              // Viewer count
              _buildViewerCount(),
              
              // Floating comments (always visible unless toggled off)
              if (_isFloatingCommentsVisible && !_isExpandedCommentsVisible)
                _buildFloatingComments(),
              
              // Floating hearts animation
              ..._floatingHearts.map((heart) => _buildFloatingHeart(heart)),
              
              // Main controls
              if (_isControlsVisible) _buildMainControls(),
              
              // Expanded comments panel
              if (_isExpandedCommentsVisible) _buildCommentsPanel(themeService),
              
              // Gifts panel
              if (_isGiftsVisible) _buildGiftsPanel(themeService),
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
          onCommentsTap: _toggleFloatingComments,
          isCommentsHidden: !_isFloatingCommentsVisible,
          onGiftsTap: _toggleGifts,
          onReactionsTap: _sendHeartReaction,
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

  Widget _buildFloatingComments() {
    if (_floatingComments.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _floatingComments.asMap().entries.map((entry) {
          final index = entry.key;
          final comment = entry.value;
          final opacity = 1.0 - ((_floatingComments.length - 1 - index) * 0.15);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value * opacity,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openExpandedComments();
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${comment['user']} ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: comment['message'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommentsPanel(ThemeService themeService) {
    // Generate more dummy comments for the expanded view
    final allComments = [
      {'user': 'Arjun K.', 'message': 'Great insights Guruji! 🙏', 'time': '5m'},
      {'user': 'Sneha R.', 'message': 'Can you do my reading next? ⭐', 'time': '4m'},
      {'user': 'Vikram M.', 'message': 'This is so accurate! ✨', 'time': '3m'},
      {'user': 'Divya S.', 'message': 'Thank you for sharing! 🌟', 'time': '2m'},
      {'user': 'Rohan P.', 'message': 'Amazing predictions! 🔮', 'time': '2m'},
      {'user': 'Anjali L.', 'message': 'Very helpful session 💫', 'time': '1m'},
      {'user': 'Karthik J.', 'message': 'Love your energy! 💖', 'time': '45s'},
      {'user': 'Meera T.', 'message': 'Please explain more about Mercury 🪐', 'time': '30s'},
      {'user': 'Sanjay N.', 'message': 'Watching from Mumbai! 🌺', 'time': '15s'},
      {'user': 'Kavya M.', 'message': 'Can you talk about career? 💼', 'time': '10s'},
      {'user': 'Aditya B.', 'message': 'Following you since last year! 🎉', 'time': '5s'},
      {'user': 'Pooja K.', 'message': 'Beautiful reading! 🌸', 'time': 'now'},
    ];
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 400,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'All Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _closeExpandedComments,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comments list (full history)
              Expanded(
                child: ListView.builder(
                  controller: _commentsScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    return _buildExpandedCommentItem(allComments[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCommentItem(Map<String, String> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              comment['user']!.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment['user']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment['message']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            comment['time']!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 450,
      child: SlideTransition(
        position: _slideAnimation,
        child: LiveStreamGiftWidget(
          liveStreamId: widget.liveStream.id,
          astrologerName: widget.liveStream.astrologerName,
          onClose: _toggleGifts,
        ),
      ),
    );
  }

  Widget _buildFloatingHeart(FloatingHeart heart) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(heart.id),
      duration: const Duration(milliseconds: 3000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // Calculate position
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Y position: start from bottom, move to top
        final y = screenHeight - (screenHeight * value);
        
        // X position: slight wave motion (sine wave)
        final waveAmplitude = 50.0;
        final waveFrequency = 3.0;
        final xOffset = sin(value * waveFrequency * 3.14159) * waveAmplitude;
        final x = (screenWidth * heart.startX) + xOffset;
        
        // Opacity: fade in quickly, stay visible, fade out at end
        double opacity = 1.0;
        if (value < 0.1) {
          opacity = value * 10;
        } else if (value > 0.8) {
          opacity = 1.0 - ((value - 0.8) * 5);
        }
        
        // Scale: start small, grow, then shrink at end
        double scale = 1.0;
        if (value < 0.2) {
          scale = 0.5 + (value * 2.5);
        } else if (value > 0.85) {
          scale = 1.0 - ((value - 0.85) * 3);
        }
        
        return Positioned(
          left: x - 20,
          top: y - 40,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.1, 1.5),
              child: Transform.rotate(
                angle: (value * 0.5) - 0.25,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '❤️',
                      style: TextStyle(
                        fontSize: 32,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.red,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// FloatingHeart model class
class FloatingHeart {
  final String id;
  final double startX;
  
  FloatingHeart({
    required this.id,
    required this.startX,
  });
}
















