import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../widgets/live_stream_info_widget.dart';
import '../widgets/live_action_stack_widget.dart';
import '../widgets/live_bottom_input_bar.dart';
import '../widgets/live_quick_gift_bar.dart';
import '../widgets/live_gift_animation_overlay.dart';
import '../widgets/live_gift_leaderboard.dart';
import '../widgets/live_gift_bottom_sheet.dart';
import '../widgets/live_comments_bottom_sheet.dart';
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
  bool _isQuickGiftVisible = false;
  bool _isLeaderboardVisible = false;
  bool _isStreamActive = true;
  bool _isLiked = false;
  
  // Engagement metrics
  int _likesCount = 1234;      // Unique users who liked
  int _heartsCount = 5432;     // Total heart reactions (can spam)
  int _commentsCount = 567;
  int _giftsTotal = 4850;
  
  // Gift combo system
  int _giftComboCount = 0;
  Timer? _comboResetTimer;
  String? _lastGiftName;
  bool _isGiftPulsing = false;
  
  final LiveStreamService _liveStreamService = LiveStreamService();
  final ScrollController _commentsScrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  Timer? _commentSimulationTimer;
  final List<Map<String, String>> _floatingComments = [];
  final Random _random = Random();
  final List<FloatingHeart> _floatingHearts = [];
  final List<GiftAnimation> _giftAnimations = [];
  final List<LeaderboardEntry> _leaderboardEntries = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSystemUI();
    _joinLiveStream();
    _startCommentSimulation();
    _initializeLeaderboard();
  }
  
  void _initializeLeaderboard() {
    // Mock leaderboard data
    _leaderboardEntries.addAll([
      LeaderboardEntry(
        userId: '1',
        userName: 'Amit Kumar',
        totalAmount: 5000,
        giftCount: 25,
        topGiftEmoji: '👑',
      ),
      LeaderboardEntry(
        userId: '2',
        userName: 'Priya Sharma',
        totalAmount: 3200,
        giftCount: 18,
        topGiftEmoji: '💎',
      ),
      LeaderboardEntry(
        userId: '3',
        userName: 'Rahul Singh',
        totalAmount: 1800,
        giftCount: 12,
        topGiftEmoji: '🚀',
      ),
      LeaderboardEntry(
        userId: '4',
        userName: 'Sneha Patel',
        totalAmount: 950,
        giftCount: 8,
        topGiftEmoji: '⭐',
      ),
      LeaderboardEntry(
        userId: '5',
        userName: 'Vikram Reddy',
        totalAmount: 600,
        giftCount: 6,
        topGiftEmoji: '🌹',
      ),
    ]);
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
    _commentController.dispose();
    _commentSimulationTimer?.cancel();
    _comboResetTimer?.cancel();
    _liveStreamService.leaveLiveStream(widget.liveStream.id);
    // SystemUI is restored in PopScope before navigation to prevent flickering
    // Keeping this as a safety fallback
    _restoreSystemUI();
    super.dispose();
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

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _openExpandedComments() {
    HapticFeedback.selectionClick();
    
    LiveCommentsBottomSheet.show(
      context,
      streamId: widget.liveStream.id,
      astrologerName: widget.liveStream.astrologerName,
      getComments: () {
        // Get fresh data in real-time
        return _floatingComments.map((comment) {
          return LiveComment(
            userName: comment['user'] ?? 'Unknown',
            message: comment['message'] ?? '',
            timestamp: DateTime.now().subtract(Duration(seconds: _floatingComments.indexOf(comment) * 10)),
          );
        }).toList();
      },
      onCommentSend: (text) {
        _handleSendComment();
      },
    );
  }

  void _toggleGifts() {
    HapticFeedback.selectionClick();
    LiveGiftBottomSheet.show(
      context,
      streamId: widget.liveStream.id,
      astrologerName: widget.liveStream.astrologerName,
      onGiftSend: (gift) {
        _sendGiftWithAnimation(
          name: gift.name,
          emoji: gift.emoji,
          value: gift.value,
          color: gift.color,
        );
      },
    );
  }
  
  void _showQuickGifts() {
    HapticFeedback.selectionClick();
    setState(() {
      _isQuickGiftVisible = true;
      _isLeaderboardVisible = false;
    });
  }
  
  void _hideQuickGifts() {
    setState(() {
      _isQuickGiftVisible = false;
    });
  }
  
  void _showLeaderboard() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLeaderboardVisible = true;
      _isQuickGiftVisible = false;
    });
  }
  
  void _hideLeaderboard() {
    setState(() {
      _isLeaderboardVisible = false;
    });
  }
  
  void _handleLike() {
    HapticFeedback.selectionClick();
    
    // ALWAYS send hearts for visual engagement (Instagram/TikTok style)
    _sendHeartReaction();
    
    setState(() {
      // Increment hearts count EVERY tap (unlimited engagement)
      _heartsCount++;
      
      // Toggle like status ONCE per user (first tap only)
      if (!_isLiked) {
        _isLiked = true;
        _likesCount++; // Count this user's like only ONCE
        
        // TODO: Send to server - user liked this stream
        // _liveService.likeStream(widget.liveStream.id);
      }
      
      // TODO: Send to server - heart reaction (every tap)
      // _liveService.sendHeartReaction(widget.liveStream.id);
    });
  }
  
  void _handleSendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.selectionClick();
    
    // Add to floating comments
    setState(() {
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      _floatingComments.add({
        'user': 'You',
        'message': text,
        'emoji': '💬',
      });
      _commentsCount++;
    });
    
    _commentController.clear();
    
    // Send to backend
    try {
      _liveStreamService.sendComment(widget.liveStream.id, text);
    } catch (e) {
      // Silently fail
    }
  }
  
  void _handleQuickGiftSend(QuickGift gift) {
    _hideQuickGifts();
    _sendGiftWithAnimation(
      name: gift.name,
      emoji: gift.emoji,
      value: gift.value,
      color: gift.color,
    );
  }
  
  void _sendGiftWithAnimation({
    required String name,
    required String emoji,
    required int value,
    required Color color,
  }) {
    // Handle combo system
    if (_lastGiftName == name) {
      _giftComboCount++;
    } else {
      _giftComboCount = 1;
      _lastGiftName = name;
    }
    
    // Reset combo after 5 seconds
    _comboResetTimer?.cancel();
    _comboResetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _giftComboCount = 0;
          _lastGiftName = null;
          _isGiftPulsing = false;
        });
      }
    });
    
    // Pulse gift button
    setState(() {
      _isGiftPulsing = true;
      _giftsTotal += value;
    });
    
    // Create gift animation
    final animation = GiftAnimation(
      name: name,
      emoji: emoji,
      value: value,
      color: color,
      tier: GiftAnimation.getTierFromValue(value),
      senderName: 'You',
      combo: _giftComboCount,
    );
    
    setState(() {
      _giftAnimations.add(animation);
    });
    
    // Remove animation after completion
    Future.delayed(Duration(milliseconds: animation.getDuration()), () {
      if (mounted) {
        setState(() {
          _giftAnimations.remove(animation);
        });
      }
    });
    
    // Send to backend
    try {
      // TODO: Implement actual gift sending
    } catch (e) {
      // Silently fail
    }
  }
  
  String _formatGiftTotal(int total) {
    if (total >= 10000) {
      return '₹${(total / 1000).toStringAsFixed(1)}K';
    } else if (total >= 1000) {
      return '₹${(total / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹$total';
    }
  }
  
  List<QuickGift> _getQuickGifts() {
    return [
      QuickGift(name: 'Rose', emoji: '🌹', value: 10, color: Colors.red),
      QuickGift(name: 'Star', emoji: '⭐', value: 25, color: Colors.amber),
      QuickGift(name: 'Heart', emoji: '💖', value: 50, color: Colors.pink),
      QuickGift(name: 'Crown', emoji: '👑', value: 100, color: Colors.purple),
      QuickGift(name: 'Diamond', emoji: '💎', value: 200, color: Colors.blue),
    ];
  }

  void _sendHeartReaction() {
    HapticFeedback.selectionClick();
    
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
              // Restore SystemUI before navigation
              _restoreSystemUI();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close viewer screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          // Restore SystemUI BEFORE popping to prevent flickering
          _restoreSystemUI();
          await Future.delayed(const Duration(milliseconds: 100)); // Small delay for smooth transition
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Consumer<ThemeService>(
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
                
                // Tap to toggle controls
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                
                // Live indicator
                _buildLiveIndicator(),
                
                // Viewer count
                _buildViewerCount(),
                
                // Close button (top-right)
                _buildCloseButton(),
                
                // Floating comments (left side) - Always visible for engagement
                _buildFloatingComments(),
                
                // Floating hearts animation
                ..._floatingHearts.map((heart) => _buildFloatingHeart(heart)),
                
                // Gift animations overlay (full screen)
                ..._giftAnimations.map((gift) => LiveGiftAnimationOverlay(
                  gift: gift,
                  onComplete: () {
                    setState(() {
                      _giftAnimations.remove(gift);
                    });
                  },
                )),
                
                // Right-side action stack (TikTok style)
                if (_isControlsVisible)
                  Positioned(
                    right: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                    child: LiveActionStackWidget(
                      liveStream: widget.liveStream,
                      heartsCount: _heartsCount,  // Shows total heart reactions (Instagram/TikTok style)
                      commentsCount: _commentsCount,
                      onProfileTap: () {
                        // TODO: Navigate to astrologer profile
                      },
                      onLikeTap: _handleLike,
                      onCommentsTap: _openExpandedComments,
                      onShareTap: () {
                        // TODO: Implement share
                      },
                      isLiked: _isLiked,
                    ),
                  ),
                
                // Bottom input bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LiveBottomInputBar(
                    commentController: _commentController,
                    onSendComment: _handleSendComment,
                    onGiftTap: _toggleGifts,
                    onGiftLongPress: _showQuickGifts,
                    showGiftButton: true,
                  ),
                ),
                
                // Quick gift bar overlay
                if (_isQuickGiftVisible)
                  LiveQuickGiftBar(
                    gifts: _getQuickGifts(),
                    onGiftTap: _handleQuickGiftSend,
                    onDismiss: _hideQuickGifts,
                  ),
                
                // Leaderboard overlay
                if (_isLeaderboardVisible)
                  LiveGiftLeaderboard(
                    entries: _leaderboardEntries,
                    onClose: _hideLeaderboard,
                    streamTitle: widget.liveStream.title,
                  ),
              ],
            ),
          );
        },
      ),
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

  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _restoreSystemUI();
          Navigator.pop(context);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
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


  Widget _buildFloatingComments() {
    if (_floatingComments.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
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
                  HapticFeedback.selectionClick();
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
















