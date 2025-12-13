import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/repositories/live/live_repository.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../services/agora_service.dart';
import '../widgets/live_comments_bottom_sheet.dart';
import '../widgets/live_gift_bottom_sheet.dart';
import '../widgets/live_gift_animation_overlay.dart';
import '../utils/gift_helper.dart';

class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final LiveStreamService _liveService;
  late final AgoraService _agoraService;
  
  // Agora state
  bool _isAgoraInitialized = false;
  bool _isLoadingAgora = true;
  String? _agoraError;
  bool _isFrontCamera = true;
  bool _isFlashOn = false;
  
  // Countdown state
  bool _isCountingDown = true;
  int _countdownValue = 5;
  Timer? _countdownTimer;
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _commentController;
  late AnimationController _countdownAnimController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _countdownScaleAnimation;
  late Animation<double> _countdownFadeAnimation;
  
  bool _isEnding = false;
  bool _isControlsVisible = true;
  String? _currentStreamId; // To end stream properly
  
  // Settings state
  bool _showViewerCount = true;
  bool _allowComments = true;
  bool _allowShare = true;
  bool _microphoneEnabled = true;
  
  // Engagement metrics
  int _viewersCount = 0;
  int _likesCount = 0;
  int _heartsCount = 0;
  int _commentsCount = 0;
  int _giftsTotal = 0;
  
  // Gift animations
  final List<Map<String, dynamic>> _giftAnimations = [];
  Timer? _giftAnimationTimer;
  
  // Gift notifications for comments view
  final List<Map<String, dynamic>> _giftNotifications = [];
  
  final ScrollController _commentsController = ScrollController();
  Timer? _commentSimulationTimer;
  final List<Map<String, String>> _floatingComments = [];
  final Random _random = Random();
  
  // Auto-end stream timers
  Timer? _backgroundTimer;
  Timer? _networkLossTimer;
  DateTime? _backgroundTime;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hasNetworkConnection = true;
  
  // Constants
  static const int _backgroundTimeoutSeconds = 5; // End stream after 5s in background (reduced from 30s)
  static const int _networkLossTimeoutSeconds = 10; // End stream after 10s of no network

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveService = LiveStreamService(); // Get the singleton instance
    _agoraService = AgoraService(); // Get Agora singleton
    _initializeAnimations();
    _hideSystemUI();
    _initializeAgora(); // Initialize Agora for live streaming
    _startStream();
    _startCommentSimulation();
    _setupNetworkMonitoring(); // Monitor network connectivity
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _backgroundTimer?.cancel();
    _networkLossTimer?.cancel();
    _connectivitySubscription?.cancel();
    // Don't dispose Agora here - it's handled in _confirmEndStream
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _commentController.dispose();
    _countdownAnimController.dispose();
    _commentsController.dispose();
    _commentSimulationTimer?.cancel();
    // SystemUI is restored in _confirmEndStream() before navigation to prevent flickering
    // Keeping this as a safety fallback
    _showSystemUI();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isEnding) return; // Don't handle lifecycle if already ending
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background or screen locked
      debugPrint('📱 [LIVE] App went to background/locked - Stopping broadcast immediately');
      _backgroundTime = DateTime.now();
      
      // Immediately stop Agora broadcast to prevent frozen stream
      _agoraService.stopBroadcasting().then((_) {
        debugPrint('⏸️ [LIVE] Agora broadcast paused');
      });
      
      // Start timer for auto-end if user doesn't return
      _startBackgroundTimer();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground or screen unlocked
      debugPrint('📱 [LIVE] App resumed from background/unlocked');
      _cancelBackgroundTimer();
      
      // Check if we were in background too long
      if (_backgroundTime != null) {
        final duration = DateTime.now().difference(_backgroundTime!);
        if (duration.inSeconds >= _backgroundTimeoutSeconds) {
          debugPrint('⚠️ [LIVE] Was in background for ${duration.inSeconds}s - Auto-ending stream');
          _autoEndStream(reason: 'Stream ended due to inactivity');
        } else {
          debugPrint('✅ [LIVE] Background duration: ${duration.inSeconds}s - Stream already stopped, ending now');
          // Stream was stopped when backgrounded, so end it now
          _autoEndStream(reason: 'Stream ended (app was backgrounded)');
        }
      }
      _backgroundTime = null;
    } else if (state == AppLifecycleState.detached) {
      // App is being killed
      debugPrint('💀 [LIVE] App is being killed - Ending stream');
      _handleAppKill();
    }
  }
  
  /// Handle app force kill or crash
  void _handleAppKill() {
    // Try to end stream quickly before app dies
    if (_currentStreamId != null && !_isEnding) {
      _isEnding = true;
      try {
        final liveRepo = getIt<LiveRepository>();
        // Fire and forget - app might die before this completes
        liveRepo.endLiveStream(_currentStreamId!).catchError((_) {});
        _agoraService.stopBroadcasting().catchError((_) {});
      } catch (e) {
        debugPrint('⚠️ [LIVE] Failed to cleanup on app kill: $e');
      }
    }
  }
  
  /// Setup network connectivity monitoring
  void _setupNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final hasConnection = result != ConnectivityResult.none;
      
      if (hasConnection != _hasNetworkConnection) {
        setState(() {
          _hasNetworkConnection = hasConnection;
        });
        
        if (hasConnection) {
          // Network restored
          debugPrint('✅ [LIVE] Network connection restored');
          _cancelNetworkLossTimer();
        } else {
          // Network lost
          debugPrint('⚠️ [LIVE] Network connection lost - Starting timeout timer');
          _startNetworkLossTimer();
        }
      }
    });
    
    // Check initial connection status
    Connectivity().checkConnectivity().then((result) {
      final hasConnection = result != ConnectivityResult.none;
      setState(() {
        _hasNetworkConnection = hasConnection;
      });
    });
  }
  
  /// Start timer to auto-end stream if app stays in background too long
  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(Duration(seconds: _backgroundTimeoutSeconds), () {
      if (!mounted || _isEnding) return;
      debugPrint('⏰ [LIVE] Background timeout reached - Auto-ending stream');
      _autoEndStream(reason: 'Stream ended due to app being in background');
    });
  }
  
  /// Cancel background timer
  void _cancelBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }
  
  /// Start timer to auto-end stream if network is lost too long
  void _startNetworkLossTimer() {
    _networkLossTimer?.cancel();
    _networkLossTimer = Timer(Duration(seconds: _networkLossTimeoutSeconds), () {
      if (!mounted || _isEnding) return;
      debugPrint('⏰ [LIVE] Network loss timeout reached - Auto-ending stream');
      _autoEndStream(reason: 'Stream ended due to network connection loss');
    });
  }
  
  /// Cancel network loss timer
  void _cancelNetworkLossTimer() {
    _networkLossTimer?.cancel();
    _networkLossTimer = null;
  }
  
  /// Auto-end stream without confirmation
  Future<void> _autoEndStream({required String reason}) async {
    if (_isEnding) return; // Already ending
    
    debugPrint('🛑 [LIVE] Auto-ending stream: $reason');
    
    setState(() {
      _isEnding = true;
    });
    
    // Stop Agora broadcast
    await _agoraService.stopBroadcasting();
    debugPrint('📷 [LIVE] Agora broadcast stopped (auto)');
    
    // End stream in backend database
    if (_currentStreamId != null) {
      try {
        final liveRepo = getIt<LiveRepository>();
        await liveRepo.endLiveStream(_currentStreamId!);
        debugPrint('✅ [LIVE] Stream ended in backend (auto)');
      } catch (e) {
        debugPrint('⚠️ [LIVE] Failed to end stream in backend: $e');
      }
    }
    
    _liveService.endLiveStream();
    
    // Restore SystemUI BEFORE navigation
    _showSystemUI();
    
    // Show reason to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red[700],
        ),
      );
    }
    
    // Wait a bit then navigate back
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pop('ended');
    }
  }

  /// Initialize Agora for live streaming
  Future<void> _initializeAgora() async {
    if (_isEnding) return; // Don't initialize if ending stream
    
    setState(() {
      _isLoadingAgora = true;
      _agoraError = null;
    });

    try {
      // Set up error callback
      _agoraService.onError = (message) {
        if (mounted) {
          setState(() {
            _agoraError = message;
          });
        }
      };
      
      _agoraService.onJoinChannelSuccess = () {
        debugPrint('✅ [LIVE] Successfully joined Agora channel');
      };

      // Initialize Agora engine
      final initialized = await _agoraService.initialize();
      
      if (!initialized) {
        setState(() {
          _agoraError = 'Failed to initialize Agora. Check permissions.';
          _isLoadingAgora = false;
        });
        return;
      }

      // Start live stream via backend - this registers the stream AND returns token
      String channelName = '';
      String token = '';
      
      try {
        final liveRepo = getIt<LiveRepository>();
        
        // Call /api/live/start - registers stream in database
        final liveStream = await liveRepo.startLiveStream(
          title: 'Live Session',
          description: 'Live astrology session',
          category: LiveStreamCategory.astrology,
          tags: ['live', 'astrology'],
        );
        
        channelName = liveStream.channelName;
        token = liveStream.agoraToken ?? '';
        
        // Store stream ID for ending later
        _currentStreamId = liveStream.id;
        
        debugPrint('✅ [LIVE] Stream registered: $channelName');
        debugPrint('✅ [LIVE] Stream ID: ${liveStream.id}');
        
      } catch (e) {
        debugPrint('❌ [LIVE] Failed to start stream: $e');
        setState(() {
          _agoraError = 'Failed to start live stream. Please try again.';
          _isLoadingAgora = false;
        });
        return;
      }

      // Start broadcasting
      final broadcasting = await _agoraService.startBroadcasting(
        channelName: channelName,
        token: token,
      );
      
      if (!broadcasting) {
        setState(() {
          _agoraError = 'Failed to start broadcasting';
          _isLoadingAgora = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _isAgoraInitialized = true;
          _isLoadingAgora = false;
        });
        // Start countdown after Agora is ready
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _agoraError = 'Failed to initialize Agora: ${e.toString()}';
          _isLoadingAgora = false;
        });
      }
    }
  }

  /// Start the countdown animation before going live
  void _startCountdown() {
    if (!_isCountingDown) return;
    
    // Play haptic feedback for first number
    HapticFeedback.mediumImpact();
    _countdownAnimController.forward();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdownValue--;
      });
      
      if (_countdownValue > 0) {
        // Animate next number
        HapticFeedback.mediumImpact();
        _countdownAnimController.reset();
        _countdownAnimController.forward();
      } else {
        // Countdown finished - go live!
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isCountingDown = false;
        });
        // Start the pulse animation now that we're live
        _pulseController.repeat(reverse: true);
      }
    });
  }

  /// Switch between front and back camera
  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    HapticFeedback.selectionClick();
  }

  /// Toggle flash/torch
  Future<void> _toggleFlash() async {
    // Flash only works on back camera
    if (_isFrontCamera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash is only available on back camera'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      await _agoraService.setFlash(_isFlashOn);
      
      HapticFeedback.selectionClick();
    } catch (e) {
      // Ignore flash errors
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _commentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Countdown animation - scales and fades each number
    _countdownAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
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
    
    // Countdown number animation - scale up and fade out
    _countdownScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _countdownAnimController,
      curve: Curves.easeOut,
    ));
    
    _countdownFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _countdownAnimController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // Don't start pulse animation until countdown finishes
    _fadeController.forward();
    _slideController.forward();
  }

  void _hideSystemUI() {
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

  void _showSystemUI() {
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

  Future<void> _startStream() async {
    // Simulate stream initialization
    await Future.delayed(const Duration(seconds: 1));
    print('🎥 [LIVE_STREAMING] Current stream: ${_liveService.currentStream}');
    
    // Initialize with some starting metrics
    setState(() {
      _viewersCount = 5 + _random.nextInt(15);  // 5-20 initial viewers
      _likesCount = 10 + _random.nextInt(30);
      _heartsCount = 50 + _random.nextInt(100);
      _commentsCount = _floatingComments.length;
    });
    
    // Simulate engagement growth
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isEnding) {
        timer.cancel();
        return;
      }
      setState(() {
        // Viewers fluctuate
        _viewersCount += _random.nextInt(3) - 1;  // -1, 0, or +1
        if (_viewersCount < 1) _viewersCount = 1;
        
        // Hearts grow
        _heartsCount += _random.nextInt(10);
        
        // Likes grow slower
        if (_random.nextBool()) {
          _likesCount++;
        }
      });
    });
    
    // Simulate receiving gifts
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted || _isEnding) {
        timer.cancel();
        return;
      }
      _receiveGift();
    });
  }
  
  void _receiveGift() {
    final giftNames = ['Rose', 'Heart', 'Star', 'Diamond', 'Crown', 'Gift Box'];
    final giftEmojis = ['🌹', '💖', '⭐', '💎', '👑', '🎁'];
    final giftValues = [10, 50, 100, 500, 1000, 2000];
    final senderNames = ['Priya', 'Rahul', 'Anjali', 'Vikram', 'Neha', 'Amit', 'Kavita', 'Sanjay'];
    
    final index = _random.nextInt(giftNames.length);
    final senderIndex = _random.nextInt(senderNames.length);
    
    setState(() {
      // Add to gift notifications (for bottom sheet)
      _giftNotifications.add({
        'sender': senderNames[senderIndex],
        'gift': giftNames[index],
        'emoji': giftEmojis[index],
        'value': giftValues[index],
        'timestamp': DateTime.now(),
        'id': '${DateTime.now().millisecondsSinceEpoch}',
      });
      
      // Add to floating comments (for main screen)
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      _floatingComments.add({
        'user': senderNames[senderIndex],
        'message': '${giftEmojis[index]} sent ${giftNames[index]}',
        'emoji': giftEmojis[index],
        'isGift': 'true',  // Mark as gift
        'value': '₹${giftValues[index]}',
      });
      
      // Update total
      _giftsTotal += giftValues[index];
      _commentsCount++; // Count gift as interaction
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _toggleSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  void _endStream() {
    print('🛑 [LIVE_STREAMING] _endStream() called - Showing confirmation dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'End Live Stream?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to end this live stream? This action cannot be undone.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🛑 [LIVE_STREAMING] User cancelled ending stream');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              print('🛑 [LIVE_STREAMING] User confirmed ending stream - Closing dialog');
              Navigator.of(context).pop();
              print('🛑 [LIVE_STREAMING] Dialog closed - Calling _confirmEndStream()');
              _confirmEndStream();
            },
            child: const Text(
              'End Stream',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndStream() async {
    debugPrint('🛑 [LIVE_STREAMING] _confirmEndStream() started');
    debugPrint('🛑 [LIVE_STREAMING] Widget mounted: $mounted');
    
    setState(() {
      _isEnding = true;
    });
    debugPrint('🛑 [LIVE_STREAMING] Set _isEnding = true');
    
    // Stop Agora broadcast
    await _agoraService.stopBroadcasting();
    debugPrint('📷 [LIVE_STREAMING] Agora broadcast stopped');
    
    // End stream in backend database
    if (_currentStreamId != null) {
      try {
        final liveRepo = getIt<LiveRepository>();
        await liveRepo.endLiveStream(_currentStreamId!);
        debugPrint('✅ [LIVE_STREAMING] Stream ended in backend');
      } catch (e) {
        debugPrint('⚠️ [LIVE_STREAMING] Failed to end stream in backend: $e');
      }
    }
    
    _liveService.endLiveStream();
    debugPrint('🛑 [LIVE_STREAMING] Called _liveService.endLiveStream()');
    
    // ✅ Restore SystemUI BEFORE navigation to prevent flickering
    _showSystemUI();
    debugPrint('✅ [LIVE_STREAMING] SystemUI restored before navigation');
    
    Future.delayed(const Duration(seconds: 2), () {
      debugPrint('🛑 [LIVE_STREAMING] Delay finished (2 seconds)');
      if (mounted) {
        try {
          Navigator.of(context).pop('ended'); // Return 'ended' to trigger dashboard navigation
          debugPrint('✅ [LIVE_STREAMING] Navigator.pop() executed successfully');
        } catch (e, stackTrace) {
          debugPrint('❌ [LIVE_STREAMING] ERROR during Navigator.pop(): $e');
          debugPrint('❌ [LIVE_STREAMING] StackTrace: $stackTrace');
        }
      } else {
        debugPrint('⚠️ [LIVE_STREAMING] Widget not mounted - Cannot pop');
      }
    });
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
      {'user': 'Priya S.', 'message': 'Namaste Guruji! 🙏', 'emoji': '🙏'},
      {'user': 'Rahul M.', 'message': 'Please read my horoscope next', 'emoji': '⭐'},
      {'user': 'Anjali K.', 'message': 'Your predictions are always accurate! ✨', 'emoji': '✨'},
      {'user': 'Vikram R.', 'message': 'Thank you for the guidance 🙏', 'emoji': '🙏'},
      {'user': 'Neha P.', 'message': 'Can you talk about Rahu Ketu? 🔮', 'emoji': '🔮'},
      {'user': 'Amit J.', 'message': 'Love your energy Guruji! 💫', 'emoji': '💫'},
      {'user': 'Kavita L.', 'message': 'This is so helpful! 🌟', 'emoji': '🌟'},
      {'user': 'Sanjay B.', 'message': 'What about Saturn transit? 🪐', 'emoji': '🪐'},
      {'user': 'Deepa M.', 'message': 'Amazing session today! 🌺', 'emoji': '🌺'},
      {'user': 'Kiran P.', 'message': 'Can you explain my birth chart? 📊', 'emoji': '📊'},
      {'user': 'Meera S.', 'message': 'Your readings are life-changing 💖', 'emoji': '💖'},
      {'user': 'Suresh K.', 'message': 'Please talk about career predictions 💼', 'emoji': '💼'},
    ];

    setState(() {
      // Keep only last 4 comments
      if (_floatingComments.length >= 4) {
        _floatingComments.removeAt(0);
      }
      
      // Add new random comment
      final randomComment = dummyComments[_random.nextInt(dummyComments.length)];
      _floatingComments.add(randomComment);
      
      // Increment total comments count
      _commentsCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop && !_isEnding) {
          // Show confirmation dialog when back button pressed
          _showExitConfirmationDialog();
        }
      },
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: ListenableBuilder(
              listenable: _liveService,
              builder: (context, child) {
                final stream = _liveService.currentStream;
                
                if (stream == null) {
                  return _buildLoadingScreen();
                }

                return Stack(
                  children: [
                    // Camera Preview
                    _buildCameraPreview(themeService),
                    
                    // Network warning banner
                    if (!_hasNetworkConnection)
                      _buildNetworkWarningBanner(),
                    
                    // Countdown overlay (shows during countdown)
                    if (_isCountingDown && _isAgoraInitialized)
                      _buildCountdownOverlay(themeService),
                    
                    // Show live UI only after countdown
                    if (!_isCountingDown) ...[
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
                      
                      // Live indicator with animation
                      _buildLiveIndicator(),
                      
                      // Stream info
                      _buildStreamInfo(stream, themeService),
                      
                      // Viewer count
                      _buildViewerCount(stream),
                      
                      // Duration
                      _buildDuration(stream),
                      
                      // Floating comments (always visible)
                      _buildFloatingComments(),
                      
                      // Gift animations overlay
                      ..._giftAnimations.map((gift) => LiveGiftAnimationOverlay(
                        gift: GiftAnimation(
                          name: gift['name'],
                          emoji: gift['emoji'],
                          value: gift['value'],
                          color: gift['color'],
                          tier: gift['tier'],
                          senderName: gift['senderName'] ?? 'Anonymous',
                          combo: gift['combo'] ?? 1,
                        ),
                        onComplete: () {
                          setState(() {
                            _giftAnimations.remove(gift);
                          });
                        },
                        key: ValueKey(gift['id']),
                      )),
                      
                      // Modern action buttons (right side)
                      if (_isControlsVisible) _buildModernActionButtons(themeService),
                    ],
                    
                    // Ending overlay
                    if (_isEnding) _buildEndingOverlay(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  /// Show exit confirmation dialog when back button pressed
  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'End Live Stream?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit and end this live stream?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🛑 [LIVE] User cancelled exit');
              Navigator.of(context).pop(); // Close dialog, stay on stream
            },
            child: const Text(
              'No, Continue Streaming',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint('🛑 [LIVE] User confirmed exit');
              Navigator.of(context).pop(); // Close dialog
              _confirmEndStream(); // End stream and exit
            },
            child: const Text(
              'Yes, End Stream',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build network warning banner
  Widget _buildNetworkWarningBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.signal_wifi_off,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stream will end in ${_networkLossTimeoutSeconds}s if not restored',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Starting Live Stream...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal countdown overlay before going live
  Widget _buildCountdownOverlay(ThemeService themeService) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "Going Live in" text
              Text(
                'Going Live in',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              
              // Animated countdown number
              AnimatedBuilder(
                animation: _countdownAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _countdownScaleAnimation.value,
                    child: Opacity(
                      opacity: _countdownFadeAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _countdownValue > 0 
                                ? Colors.white.withOpacity(0.3)
                                : Colors.red,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_countdownValue > 0 
                                  ? Colors.white 
                                  : Colors.red).withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _countdownValue > 0 
                                ? '$_countdownValue' 
                                : '●',
                            style: TextStyle(
                              color: _countdownValue > 0 
                                  ? Colors.white 
                                  : Colors.red,
                              fontSize: _countdownValue > 0 ? 64 : 32,
                              fontWeight: FontWeight.w200,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Subtle hint
              Text(
                'Get ready to shine ✨',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(ThemeService themeService) {
    // Show loading state
    if (_isLoadingAgora) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Initializing broadcast...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
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
                onPressed: _initializeAgora,
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
    
    // Show Agora video preview
    if (_isAgoraInitialized && _agoraService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraService.engine!,
          canvas: const VideoCanvas(uid: 0), // 0 = local user
        ),
      );
    }
    
    // Fallback
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
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
              Colors.black.withOpacity(0.7),
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
      child: FadeTransition(
        opacity: _fadeAnimation,
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
        },
        ),
      ),
    );
  }

  Widget _buildStreamInfo(LiveStreamModel stream, ThemeService themeService) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stream.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                stream.astrologerSpecialty,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerCount(LiveStreamModel stream) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 120,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                stream.formattedViewerCount,
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

  Widget _buildDuration(LiveStreamModel stream) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60, // Below the stream info
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            stream.formattedDuration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons(ThemeService themeService) {
    return Positioned(
      right: 12,
      bottom: MediaQuery.of(context).padding.bottom + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flip camera
          _buildActionButton(
            icon: Icons.flip_camera_ios,
            label: '',
            onTap: _switchCamera,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          
          // Flash toggle (only show for back camera)
          if (!_isFrontCamera)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActionButton(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: '',
                onTap: _toggleFlash,
                color: _isFlashOn ? Colors.amber : Colors.white,
              ),
            ),
          
          // Hearts/Likes received
          _buildActionButton(
            icon: Icons.favorite,
            label: _formatCount(_heartsCount),
            onTap: () {
              // TODO: Show likes list
            },
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          
          // Comments
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(_commentsCount),
            onTap: _openComments,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          
          // Gifts received
          _buildActionButton(
            icon: Icons.card_giftcard,
            label: _formatCount(_giftsTotal),
            onTap: _openGifts,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          
          // Settings
          _buildActionButton(
            icon: Icons.settings,
            label: '',
            onTap: _toggleSettings,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          
          // End stream button (prominent red)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _endStream();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  void _openComments() {
    HapticFeedback.selectionClick();
    
    LiveCommentsBottomSheet.show(
      context,
      streamId: 'host-stream',
      astrologerName: 'You',
      getComments: () {
        // Get fresh data in real-time
        List<LiveComment> allInteractions = [];
        
        // Add regular comments
        for (var comment in _floatingComments) {
          allInteractions.add(LiveComment(
            userName: comment['user'] ?? 'Unknown',
            message: comment['message'] ?? '',
            timestamp: DateTime.now().subtract(Duration(seconds: _floatingComments.indexOf(comment) * 10)),
          ));
        }
        
        // Add gift notifications as special comments
        for (var gift in _giftNotifications) {
          allInteractions.add(LiveComment(
            userName: gift['sender'] ?? 'Unknown',
            message: '${gift['emoji']} sent ${gift['gift']} (₹${gift['value']})',
            timestamp: gift['timestamp'] ?? DateTime.now(),
            isGift: true,
          ));
        }
        
        // Sort by timestamp (newest first)
        allInteractions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return allInteractions;
      },
      onCommentSend: (text) {
        // Handle comment from host (shouldn't happen normally)
      },
    );
  }

  void _openGifts() {
    HapticFeedback.selectionClick();
    
    // Show only gift notifications
    List<LiveComment> giftsList = [];
    
    for (var gift in _giftNotifications) {
      giftsList.add(LiveComment(
        userName: gift['sender'] ?? 'Unknown',
        message: '${gift['emoji']} sent ${gift['gift']} (₹${gift['value']})',
        timestamp: gift['timestamp'] ?? DateTime.now(),
        isGift: true,
      ));
    }
    
    // Sort by timestamp (newest first)
    giftsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Show gifts bottom sheet
    _showGiftsBottomSheet(giftsList);
  }

  void _showGiftsBottomSheet(List<LiveComment> gifts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GiftsBottomSheet(
        getGifts: () {
          // Get fresh gift data in real-time
          List<LiveComment> giftsList = [];
          for (var gift in _giftNotifications) {
            giftsList.add(LiveComment(
              userName: gift['sender'] ?? 'Unknown',
              message: '${gift['emoji']} sent ${gift['gift']} (₹${gift['value']})',
              timestamp: gift['timestamp'] ?? DateTime.now(),
              isGift: true,
            ));
          }
          giftsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return giftsList;
        },
        getTotalEarnings: () => _giftsTotal,
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
                  HapticFeedback.selectionClick();
                  _openComments();
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
                        Builder(
                          builder: (context) {
                            final msg = comment['message']?.toString().toLowerCase() ?? '';
                            final giftNames = ['rose', 'star', 'heart', 'diamond', 'rainbow', 'crown'];
                            for (final name in giftNames) {
                              if (msg.contains(name)) {
                                return GiftHelper.buildGiftImage(name, comment['emoji']!, 16);
                              }
                            }
                            return Text(comment['emoji']!, style: const TextStyle(fontSize: 16));
                          },
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

  Widget _buildSettingsBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0F0F1E),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Settings options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSettingItem(
                  icon: Icons.visibility_outlined,
                  title: 'Viewer Count',
                  subtitle: 'Show viewer count',
                  value: _showViewerCount,
                  onChanged: (value) {
                    setState(() {
                      _showViewerCount = value;
                    });
                  },
                ),
                _buildSettingItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Comments',
                  subtitle: 'Allow viewers to comment',
                  value: _allowComments,
                  onChanged: (value) {
                    setState(() {
                      _allowComments = value;
                    });
                  },
                ),
                _buildSettingItem(
                  icon: Icons.share_outlined,
                  title: 'Share',
                  subtitle: 'Allow viewers to share',
                  value: _allowShare,
                  onChanged: (value) {
                    setState(() {
                      _allowShare = value;
                    });
                  },
                ),
                _buildSettingItem(
                  icon: Icons.mic_outlined,
                  title: 'Microphone',
                  subtitle: 'Enable audio',
                  value: _microphoneEnabled,
                  onChanged: (value) {
                    setState(() {
                      _microphoneEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // Icon with subtle background
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
            activeTrackColor: Colors.red.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.8),
            inactiveTrackColor: Colors.white.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildEndingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Ending Live Stream...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gifts Bottom Sheet Widget - Real-time updates
class _GiftsBottomSheet extends StatefulWidget {
  final List<LiveComment> Function() getGifts;
  final int Function() getTotalEarnings;

  const _GiftsBottomSheet({
    required this.getGifts,
    required this.getTotalEarnings,
  });

  @override
  State<_GiftsBottomSheet> createState() => _GiftsBottomSheetState();
}

class _GiftsBottomSheetState extends State<_GiftsBottomSheet> {
  late Timer _updateTimer;
  List<LiveComment> _gifts = [];
  int _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
    
    // Update every second for real-time feel
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _gifts = widget.getGifts();
      _totalEarnings = widget.getTotalEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF0F0F1E),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header with total earnings
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber,
                                Colors.orange,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gifts Received',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_gifts.length} gifts • Total: ₹$_totalEarnings',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Gifts list
              Expanded(
                child: _gifts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No gifts received yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _gifts.length,
                        itemBuilder: (context, index) {
                          return _buildGiftItem(_gifts[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftItem(LiveComment gift) {
    final giftName = GiftHelper.extractGiftName(gift.message) ?? 'Star';
    final giftColor = GiftHelper.getGiftColor(giftName);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: giftColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: giftColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Gift emoji
            Builder(
              builder: (context) {
                final msg = gift.message.toLowerCase();
                final giftNames = ['rose', 'star', 'heart', 'diamond', 'rainbow', 'crown'];
                for (final name in giftNames) {
                  if (msg.contains(name)) {
                    return GiftHelper.buildGiftImage(name, _extractGiftEmoji(gift.message), 36);
                  }
                }
                return Text(_extractGiftEmoji(gift.message), style: const TextStyle(fontSize: 36));
              },
            ),
            const SizedBox(width: 12),
            
            // Gift details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.userName,
                    style: TextStyle(
                      color: giftColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift.timeAgo,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Extract emoji from gift message
  String _extractGiftEmoji(String message) {
    final emojiMap = {
      'rose': '🌹',
      'star': '⭐',
      'heart': '💖',
      'diamond': '💎',
      'rainbow': '🌈',
      'crown': '👑',
    };
    
    for (final entry in emojiMap.entries) {
      if (message.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If emoji is already in the message, extract it
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
    final match = emojiRegex.firstMatch(message);
    if (match != null) {
      return match.group(0) ?? '🎁';
    }
    
    return '🎁'; // Default gift emoji
  }
}