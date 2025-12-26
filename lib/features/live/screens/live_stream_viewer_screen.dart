import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/bloc/wakelock/wakelock_bloc.dart';
import '../../../core/bloc/wakelock/wakelock_event.dart';
import '../../../data/repositories/live/live_repository.dart';
import '../models/live_stream_model.dart';
import '../models/live_comment_model.dart';
import '../bloc/live_comment_bloc.dart';
import '../bloc/live_comment_event.dart';
import '../bloc/live_comment_state.dart';
import '../widgets/live_stream_info_widget.dart';
import '../widgets/live_action_stack_widget.dart';
import '../widgets/live_bottom_input_bar.dart';
import '../widgets/live_quick_gift_bar.dart';
import '../widgets/live_gift_animation_overlay.dart';
import '../widgets/live_gift_leaderboard.dart';
import '../widgets/live_gift_bottom_sheet.dart';
import '../widgets/live_comments_bottom_sheet.dart';
import '../widgets/live_floating_comments_widget.dart';
import '../services/live_stream_service.dart';
import '../services/agora_service.dart';
import '../utils/gift_helper.dart';

class LiveStreamViewerScreen extends StatefulWidget {
  final LiveStreamModel liveStream;
  final bool isActive; // Whether this stream is currently visible in feed
  final VoidCallback? onExit; // Custom exit handler for feed

  const LiveStreamViewerScreen({
    super.key,
    required this.liveStream,
    this.isActive = true,
    this.onExit,
  });

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isControlsVisible = true;
  bool _isQuickGiftVisible = false;
  bool _isLeaderboardVisible = false;
  bool _isStreamActive = true;
  bool _isLiked = false;
  
  // Engagement metrics (local counts - start at 0, not dummy data)
  int _heartsCount = 0;     // Total heart reactions (can spam)
  int _commentsCount = 0;
  int _giftsTotal = 0;
  
  // Gift combo system
  int _giftComboCount = 0;
  Timer? _comboResetTimer;
  String? _lastGiftName;
  bool _isGiftPulsing = false;
  
  final LiveStreamService _liveStreamService = LiveStreamService();
  final AgoraService _agoraService = AgoraService();
  late final SocketService _socketService;
  late final LiveCommentBloc _commentBloc;
  late final WakelockBloc _wakelockBloc;
  final ScrollController _commentsScrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  
  // Real-time viewer count from socket
  StreamSubscription<Map<String, dynamic>>? _viewerCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _likesCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _giftSubscription;
  int _realViewerCount = 0;
  int _realLikesCount = 0;
  
  // Agora state
  bool _isAgoraConnected = false;
  bool _isAgoraLoading = true;
  String? _agoraError;
  int? _remoteBroadcasterUid;
  Timer? _commentSimulationTimer;
  Timer? _giftSimulationTimer;
  Timer? _reconnectTimer; // Timer for reconnection attempts
  bool _isReconnecting = false; // Show reconnecting UI
  final List<Map<String, String>> _floatingComments = []; // Only last 4 for floating display
  final List<Map<String, String>> _allComments = []; // All comments for bottom sheet
  final Random _random = Random();
  final List<FloatingHeart> _floatingHearts = [];
  final List<GiftAnimation> _giftAnimations = [];
  final List<LeaderboardEntry> _leaderboardEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService = getIt<SocketService>();
    _wakelockBloc = getIt<WakelockBloc>();
    _commentBloc = LiveCommentBloc(
      socketService: _socketService,
      liveRepository: getIt<LiveRepository>(),
    );
    _setupAnimations();
    _setupSystemUI();
    _joinLiveStream();
    _startCommentSimulation();
    // Gift simulation removed - using real-time socket gifts now
    _initializeLeaderboard();
    _connectSocket();
    // Enable wakelock when viewing live stream
    _wakelockBloc.add(const EnableWakelockEvent());
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

  /// Connect to Socket.IO for real-time viewer count
  Future<void> _connectSocket() async {
    try {
      await _socketService.connect();
      
      // Listen for viewer count updates
      _viewerCountSubscription = _socketService.viewerCountStream.listen((data) {
        if (mounted && data['streamId'] == widget.liveStream.id) {
          setState(() {
            _realViewerCount = data['count'] ?? 0;
          });
          debugPrint('👥 [VIEWER] Real-time viewer count: $_realViewerCount');
        }
      });
      
      // Listen for likes count updates
      _likesCountSubscription = _socketService.likesCountStream.listen((data) {
        debugPrint('👍 [VIEWER] Received LIKE_COUNT event: $data');
        debugPrint('👍 [VIEWER] Comparing streamId: ${data['streamId']} vs ${widget.liveStream.id}');
        if (mounted && data['streamId'] == widget.liveStream.id) {
          final newCount = data['count'] ?? 0;
          debugPrint('👍 [VIEWER] Updating likes count from $_realLikesCount to $newCount');
          setState(() {
            _realLikesCount = newCount;
          });
        } else {
          debugPrint('👍 [VIEWER] Ignoring - streamId mismatch or not mounted');
        }
      });
      
      // Listen for stream end
      _socketService.liveEndStream.listen((data) {
        if (mounted && data['streamId'] == widget.liveStream.id) {
          debugPrint('🛑 [VIEWER] Stream ended via socket');
          _showStreamEndedDialog();
        }
      });
      
      // Listen for real-time gifts from other viewers
      _giftSubscription = _socketService.liveGiftStream.listen((data) {
        if (mounted && data['streamId'] == widget.liveStream.id) {
          debugPrint('🎁 [VIEWER] Received gift: $data');
          _handleReceivedGift(data);
        }
      });
      
      // Join the room
      _joinSocketRoom();
      
      debugPrint('🔌 [VIEWER] Socket connected');
    } catch (e) {
      debugPrint('⚠️ [VIEWER] Socket connection error: $e');
    }
  }
  
  /// Join socket room as viewer
  void _joinSocketRoom() {
    debugPrint('🔍 [VIEWER] Attempting to join socket room. StreamId: ${widget.liveStream.id}, isConnected: ${_socketService.isConnected}');
    
    if (_socketService.isConnected) {
      _socketService.joinLiveStream(
        streamId: widget.liveStream.id,
        isBroadcaster: false,
      );
      
      // Subscribe to comments via BLoC
      _commentBloc.add(LiveCommentSubscribeEvent(widget.liveStream.id));
      
      debugPrint('📺 [VIEWER] Joined socket room: ${widget.liveStream.id}');
    } else {
      // Socket not connected yet, retry after a delay
      debugPrint('⚠️ [VIEWER] Socket not connected, retrying in 1 second...');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _joinSocketRoom();
        }
      });
    }
  }
  
  /// Leave socket room
  void _leaveSocketRoom() {
    if (_socketService.isConnected) {
      _socketService.leaveLiveStream(widget.liveStream.id);
      _commentBloc.add(const LiveCommentUnsubscribeEvent());
      debugPrint('👋 [VIEWER] Left socket room: ${widget.liveStream.id}');
    }
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
    setState(() {
      _isAgoraLoading = true;
      _agoraError = null;
    });
    
    try {
      // Get channel name from the stream (uses astrologerId as channel)
      final channelName = widget.liveStream.channelName;
      
      // Get token from backend
      String token = widget.liveStream.agoraToken ?? '';
      
      if (token.isEmpty) {
        try {
          final liveRepo = getIt<LiveRepository>();
          token = await liveRepo.getAgoraToken(
            channelName: channelName,
            uid: 0,
            isBroadcaster: false,
          );
        } catch (e) {
          debugPrint('Failed to get token from backend: $e');
          // Continue without token for testing
        }
      }
      
      // Set up Agora callbacks
      _agoraService.onUserJoined = (uid) {
        debugPrint('📺 [VIEWER] Broadcaster joined: $uid');
      if (mounted) {
        setState(() {
            _remoteBroadcasterUid = uid;
          _isStreamActive = true;
        });
      }
      };
      
      _agoraService.onUserOffline = (uid) {
        debugPrint('📺 [VIEWER] Broadcaster left: $uid');
        if (mounted && _remoteBroadcasterUid == uid) {
          setState(() {
            _remoteBroadcasterUid = null;
            _isStreamActive = false;
            _isReconnecting = true; // Show reconnecting state
          });
          
          // Wait 5 seconds before showing "ended" dialog
          // Give broadcaster time to reconnect
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && !_isStreamActive) {
              setState(() {
                _isReconnecting = false;
              });
              _showStreamEndedDialog();
            }
          });
        }
      };
      
      _agoraService.onError = (message) {
        debugPrint('❌ [VIEWER] Agora error: $message');
        if (mounted) {
          setState(() {
            _agoraError = message;
            _isAgoraLoading = false;
          });
        }
      };
      
      _agoraService.onFirstRemoteVideoFrame = (uid) {
        debugPrint('📺 [VIEWER] First video frame from: $uid');
        if (mounted) {
          setState(() {
            _remoteBroadcasterUid = uid;
            _isAgoraConnected = true;
            _isAgoraLoading = false;
            _isStreamActive = true;
            _isReconnecting = false; // Cancel reconnecting state
          });
          
          // Cancel reconnect timer if broadcaster came back
          _reconnectTimer?.cancel();
        }
      };
      
      // Join as audience
      debugPrint('📺 [VIEWER] Joining channel: $channelName');
      debugPrint('📺 [VIEWER] Token length: ${token.length}');
      
      final success = await _agoraService.joinAsAudience(
        channelName: channelName,
        token: token,
        uid: 0,
      );
      
      debugPrint('📺 [VIEWER] Join result: $success');
      
      if (success && mounted) {
        setState(() {
          _isAgoraConnected = true;
          _isAgoraLoading = false;
        });
        
        // Check if broadcaster is already in channel
        if (_agoraService.broadcasterUid != null) {
          setState(() {
            _remoteBroadcasterUid = _agoraService.broadcasterUid;
            _isStreamActive = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _agoraError = 'Failed to join stream';
          _isAgoraLoading = false;
        });
      }
      
      // Also call the service for analytics
      await _liveStreamService.joinLiveStream(widget.liveStream.id);
      
    } catch (e) {
      debugPrint('❌ [VIEWER] Failed to join: $e');
      if (mounted) {
        setState(() {
          _agoraError = 'Failed to join: $e';
          _isAgoraLoading = false;
        });
      }
    }
  }
  
  void _showStreamEndedDialog() {
    // Stop audio immediately when stream ends
    _agoraService.leaveAsViewer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Stream Ended',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This live stream has ended.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close dialog
              await _exitViewer(); // Clean up
              if (widget.onExit != null) {
                widget.onExit!();
              } else if (context.mounted) {
                Navigator.of(context).pop(); // Close viewer screen
              }
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    _commentsScrollController.dispose();
    _commentController.dispose();
    _commentSimulationTimer?.cancel();
    _giftSimulationTimer?.cancel();
    _comboResetTimer?.cancel();
    _reconnectTimer?.cancel(); // Cancel reconnect timer
    _viewerCountSubscription?.cancel(); // Cancel socket subscription
    _likesCountSubscription?.cancel(); // Cancel likes socket subscription
    _giftSubscription?.cancel(); // Cancel gift socket subscription
    _commentBloc.close(); // Close comment BLoC
    
    // Disable wakelock when leaving viewer screen
    _wakelockBloc.add(const DisableWakelockEvent());
    
    // Leave socket room
    _leaveSocketRoom();
    
    // Leave Agora channel as viewer - stops all audio/video
    _agoraService.leaveAsViewer();
    
    _liveStreamService.leaveLiveStream(widget.liveStream.id);
    // SystemUI is restored in PopScope before navigation to prevent flickering
    // Keeping this as a safety fallback
    _restoreSystemUI();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - pause wakelock to save battery
      _wakelockBloc.add(const AppPausedEvent());
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - resume wakelock if stream is still active
      _wakelockBloc.add(const AppResumedEvent(shouldReEnable: true));
    }
  }
  
  /// Clean exit handler - ensures all streams are stopped before navigation
  Future<void> _exitViewer() async {
    debugPrint('🚪 [VIEWER] Exiting viewer screen...');
    
    // Leave socket room first
    _leaveSocketRoom();
    
    // Stop Agora (this is critical to stop audio)
    await _agoraService.leaveAsViewer();
    
    // Leave via API
    _liveStreamService.leaveLiveStream(widget.liveStream.id);
    
    // Restore system UI
    _restoreSystemUI();
    
    debugPrint('✅ [VIEWER] Cleanup complete');
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
      commentBloc: _commentBloc,
      onCommentSend: (text) {
        // Send comment via BLoC
        _commentBloc.add(LiveCommentSendEvent(
          streamId: widget.liveStream.id,
          message: text,
        ));
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
        
        // Send like to server via socket
        debugPrint('👍 [VIEWER] Sending like for stream: ${widget.liveStream.id}, socket connected: ${_socketService.isConnected}');
        _socketService.likeLiveStream(widget.liveStream.id);
      }
    });
  }
  
  void _handleSendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.selectionClick();
    
    // Send comment via BLoC
    _commentBloc.add(LiveCommentSendEvent(
      streamId: widget.liveStream.id,
      message: text,
    ));
    
    _commentController.clear();
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
    
    // Send to backend via socket
    _socketService.sendLiveGift(
      streamId: widget.liveStream.id,
      giftType: name,
      giftValue: value,
    );
    
    debugPrint('🎁 [VIEWER] Sent gift: $name (₹$value)');
  }
  
  /// Handle gift received from socket (other viewers sending gifts)
  void _handleReceivedGift(Map<String, dynamic> data) {
    final senderName = data['senderName'] ?? 'Someone';
    final giftType = data['giftType'] ?? 'Gift';
    final int giftValue = (data['giftValue'] ?? 0) as int;
    
    // Get gift emoji and color from type
    final giftInfo = _getGiftInfo(giftType);
    
    // Create gift animation
    final animation = GiftAnimation(
      name: giftType,
      emoji: giftInfo['emoji']!,
      value: giftValue,
      color: Color(int.parse(giftInfo['color']!)),
      tier: GiftAnimation.getTierFromValue(giftValue),
      senderName: senderName,
      combo: 1,
    );
    
    setState(() {
      // Add gift animation
      _giftAnimations.add(animation);
      
      // Update gift total
      _giftsTotal += giftValue;
    });
    
    // Remove animation after completion
    Future.delayed(Duration(milliseconds: animation.getDuration()), () {
      if (mounted) {
        setState(() {
          _giftAnimations.remove(animation);
        });
      }
    });
    
    debugPrint('🎁 [VIEWER] Displayed gift from $senderName: $giftType (₹$giftValue)');
  }
  
  /// Get gift info (emoji and color) from gift type
  Map<String, String> _getGiftInfo(String giftType) {
    final giftMap = {
      'Rose': {'emoji': '🌹', 'color': '0xFFFF4458'},
      'Star': {'emoji': '⭐', 'color': '0xFFFFD700'},
      'Heart': {'emoji': '💖', 'color': '0xFFFF1493'},
      'Crown': {'emoji': '👑', 'color': '0xFFFFC107'},
      'Diamond': {'emoji': '💎', 'color': '0xFF00BFFF'},
      'Rainbow': {'emoji': '🌈', 'color': '0xFF9D4EDD'},
      'Gift Box': {'emoji': '🎁', 'color': '0xFFE91E63'},
    };
    
    return giftMap[giftType] ?? {'emoji': '🎁', 'color': '0xFFE91E63'};
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

    final randomComment = dummyComments[_random.nextInt(dummyComments.length)];
    
    setState(() {
      // Keep only last 4 comments for floating display
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      
      // Add new random comment to floating display
      _floatingComments.add(randomComment);
      
      // Add to all comments list (for bottom sheet) - no limit
      _allComments.add(randomComment);
    });
  }

  void _startGiftSimulation() {
    // Add initial gift after a short delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _addSimulatedGift();
    });
    
    // Add new gift every 8-15 seconds (less frequent than comments)
    _giftSimulationTimer = Timer.periodic(
      Duration(seconds: 8 + _random.nextInt(8)),
      (timer) {
        if (mounted) {
          _addSimulatedGift();
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _addSimulatedGift() {
    final dummyGifts = [
      {'name': 'Rose', 'emoji': '🌹', 'value': '10', 'color': '0xFFFF4458', 'tier': 'basic'},
      {'name': 'Star', 'emoji': '⭐', 'value': '50', 'color': '0xFFFFD700', 'tier': 'premium'},
      {'name': 'Heart', 'emoji': '❤️', 'value': '100', 'color': '0xFFFF1493', 'tier': 'premium'},
      {'name': 'Diamond', 'emoji': '💎', 'value': '500', 'color': '0xFF00BFFF', 'tier': 'luxury'},
      {'name': 'Rainbow', 'emoji': '🌈', 'value': '1000', 'color': '0xFF9D4EDD', 'tier': 'luxury'},
      {'name': 'Crown', 'emoji': '👑', 'value': '5000', 'color': '0xFFFFC107', 'tier': 'legendary'},
    ];

    final dummyUsers = [
      'Arjun K.', 'Sneha R.', 'Vikram M.', 'Divya S.', 'Rohan P.', 
      'Anjali L.', 'Karthik J.', 'Meera T.', 'Sanjay N.', 'Kavya M.',
    ];

    // Weighted random: more basic gifts, fewer legendary
    final weights = [40, 25, 15, 10, 7, 3]; // Percentages
    final randomValue = _random.nextInt(100);
    int giftIndex = 0;
    int cumulative = 0;
    
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue < cumulative) {
        giftIndex = i;
        break;
      }
    }

    final gift = dummyGifts[giftIndex];
    final sender = dummyUsers[_random.nextInt(dummyUsers.length)];
    
    // Create gift animation
    final animation = GiftAnimation(
      name: gift['name']!,
      emoji: gift['emoji']!,
      value: int.parse(gift['value']!),
      color: Color(int.parse(gift['color']!)),
      tier: GiftAnimation.getTierFromValue(int.parse(gift['value']!)),
      senderName: sender,
      combo: 1,
    );
    
    setState(() {
      // Add gift animation
      _giftAnimations.add(animation);
      
      // Add gift as a special comment to floating comments
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      _floatingComments.add({
        'user': sender,
        'message': 'sent ${gift['name']}',
        'emoji': gift['emoji']!,
        'value': '₹${gift['value']}',
        'isGift': 'true',
      });
      
      // Add to all comments as well
      _allComments.add({
        'user': sender,
        'message': 'sent ${gift['name']}',
        'emoji': gift['emoji']!,
        'value': '₹${gift['value']}',
        'isGift': 'true',
      });
    });
    
    // Remove animation after completion
    Future.delayed(Duration(milliseconds: animation.getDuration()), () {
      if (mounted) {
        setState(() {
          _giftAnimations.remove(animation);
        });
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
    // Disable PopScope when in feed mode (let feed handle navigation)
    final isInFeed = widget.onExit != null;
    
    final content = Consumer<ThemeService>(
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
                
                // Stream info (broadcaster name + topic)
                _buildStreamInfo(),
                
                // Viewer count
                _buildViewerCount(),
                
                // Close button (top-right)
                _buildCloseButton(),
                
                // Floating comments (left side) - Real-time via BLoC
                BlocBuilder<LiveCommentBloc, LiveCommentState>(
                  bloc: _commentBloc,
                  builder: (context, commentState) {
                    if (commentState is LiveCommentLoaded) {
                      return LiveFloatingCommentsWidget(
                        comments: commentState.floatingComments,
                        onTap: _openExpandedComments,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
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
                
                // Right-side action stack (TikTok style) - Real-time comment count
                if (_isControlsVisible)
                  Positioned(
                    right: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                    child: BlocBuilder<LiveCommentBloc, LiveCommentState>(
                      bloc: _commentBloc,
                      builder: (context, commentState) {
                        final realCommentCount = commentState is LiveCommentLoaded 
                            ? commentState.allComments.length 
                            : 0;
                        return LiveActionStackWidget(
                      liveStream: widget.liveStream,
                          likesCount: _realLikesCount,  // Real-time unique likes count
                      heartsCount: _heartsCount,  // Shows total heart reactions (Instagram/TikTok style)
                          commentsCount: realCommentCount,
                      onProfileTap: () {
                        // TODO: Navigate to astrologer profile
                      },
                      onLikeTap: _handleLike,
                      onCommentsTap: _openExpandedComments,
                      onShareTap: () {
                        // TODO: Implement share
                      },
                      isLiked: _isLiked,
                        );
                      },
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
      );
    
    // Wrap with PopScope only when NOT in feed mode
    if (isInFeed) {
      return content; // No PopScope in feed mode - let feed handle navigation
    } else {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (!didPop) {
            // Clean up Agora BEFORE popping to stop audio immediately
            await _exitViewer();
            await Future.delayed(const Duration(milliseconds: 100));
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: content,
      );
    }
  }

  Widget _buildVideoArea(ThemeService themeService) {
    // Show loading state
    if (_isAgoraLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Connecting to stream...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show error state
    if (_agoraError != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _agoraError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _joinLiveStream,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show Agora remote video if connected
    if (_isAgoraConnected && _remoteBroadcasterUid != null && _agoraService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(uid: _remoteBroadcasterUid!),
          connection: RtcConnection(channelId: widget.liveStream.channelName),
        ),
      );
    }
    
    // Waiting for broadcaster
    if (_isAgoraConnected && _remoteBroadcasterUid == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Waiting for broadcaster...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback - show placeholder (should not reach here normally)
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
          if (!_isStreamActive && !_isReconnecting)
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
          
          // Reconnecting overlay
          if (_isReconnecting)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stream will resume shortly',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  Widget _buildStreamInfo() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 52, // Below LIVE indicator
      left: 16,
      right: 100, // Leave space for close button
      child: AnimatedOpacity(
        opacity: _isControlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Broadcaster name with glow effect
            Text(
              widget.liveStream.astrologerName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Topic/Title with subtle styling
            Text(
              widget.liveStream.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        onTap: () async {
          HapticFeedback.selectionClick();
          
          // Clean up Agora BEFORE navigation
          await _exitViewer();
          
          if (widget.onExit != null) {
            widget.onExit!(); // Use custom exit handler for feed
          } else if (context.mounted) {
            Navigator.pop(context); // Default behavior
          }
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
    // Use real-time viewer count if available
    final displayCount = _realViewerCount > 0 ? _realViewerCount : widget.liveStream.viewerCount;
    
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
                _formatViewerCount(displayCount),
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
  
  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
                    // Gift-specific color based on gift type (minimal and flat)
                    color: comment['isGift'] == 'true'
                        ? GiftHelper.getGiftColor(
                            GiftHelper.extractGiftName(comment['message'] ?? '') ?? 'Star'
                          ).withOpacity(0.15)
                        : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: comment['isGift'] == 'true'
                          ? GiftHelper.getGiftColor(
                              GiftHelper.extractGiftName(comment['message'] ?? '') ?? 'Star'
                            ).withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                      width: comment['isGift'] == 'true' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gift emoji for gift notifications
                      if (comment['isGift'] == 'true' && comment['emoji'] != null) ...[
                        Text(
                          comment['emoji']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${comment['user']} ',
                                style: TextStyle(
                                  color: comment['isGift'] == 'true'
                                      ? GiftHelper.getGiftColor(
                                          GiftHelper.extractGiftName(comment['message'] ?? '') ?? 'Star'
                                        )
                                      : Colors.white,
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
                              // Show value for gifts
                              if (comment['isGift'] == 'true' && comment['value'] != null)
                                TextSpan(
                                  text: ' ${comment['value']}',
                                  style: TextStyle(
                                    color: GiftHelper.getGiftColor(
                                      GiftHelper.extractGiftName(comment['message'] ?? '') ?? 'Star'
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

















