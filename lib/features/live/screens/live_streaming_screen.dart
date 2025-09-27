import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';

class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with TickerProviderStateMixin {
  late final LiveStreamService _liveService;
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isEnding = false;
  bool _isControlsVisible = true;
  bool _isCommentsVisible = false;
  bool _isEffectsVisible = false;
  bool _isSettingsVisible = false;
  
  final ScrollController _commentsController = ScrollController();

  @override
  void initState() {
    super.initState();
    _liveService = LiveStreamService(); // Get the singleton instance
    _initializeAnimations();
    _hideSystemUI();
    _startStream();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _commentsController.dispose();
    _showSystemUI();
    super.dispose();
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

    _pulseController.repeat(reverse: true);
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

  Future<void> _startStream() async {
    // Simulate stream initialization
    await Future.delayed(const Duration(seconds: 1));
    print('🎥 [LIVE_STREAMING] Current stream: ${_liveService.currentStream}');
    if (mounted) {
      setState(() {});
    }
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
        _isEffectsVisible = false;
        _isSettingsVisible = false;
      }
    });
  }

  void _toggleEffects() {
    setState(() {
      _isEffectsVisible = !_isEffectsVisible;
      if (_isEffectsVisible) {
        _isCommentsVisible = false;
        _isSettingsVisible = false;
      }
    });
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsVisible = !_isSettingsVisible;
      if (_isSettingsVisible) {
        _isCommentsVisible = false;
        _isEffectsVisible = false;
      }
    });
  }

  void _endStream() {
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
            onPressed: () => Navigator.of(context).pop(),
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
              Navigator.of(context).pop();
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

  void _confirmEndStream() {
    setState(() {
      _isEnding = true;
    });
    
    _liveService.endLiveStream();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
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
                  
                  // Top gradient overlay
                  _buildTopGradient(),
                  
                  // Bottom gradient overlay
                  _buildBottomGradient(),
                  
                  // Live indicator with animation
              _buildLiveIndicator(),
              
                  // Stream info
                  _buildStreamInfo(stream, themeService),
                  
                  // Viewer count
                  _buildViewerCount(stream),
                  
                  // Duration
                  _buildDuration(stream),
                  
                  // Main controls
                  if (_isControlsVisible) _buildMainControls(themeService),
                  
                  // Comments panel
                  if (_isCommentsVisible) _buildCommentsPanel(themeService),
                  
                  // Effects panel
                  if (_isEffectsVisible) _buildEffectsPanel(themeService),
                  
                  // Settings panel
                  if (_isSettingsVisible) _buildSettingsPanel(themeService),
                  
                  // Tap to toggle controls
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleControls,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  
                  // Ending overlay
              if (_isEnding) _buildEndingOverlay(),
            ],
          );
        },
          ),
        );
      },
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

  Widget _buildCameraPreview(ThemeService themeService) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.3),
            themeService.secondaryColor.withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Mock camera feed
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
                      size: 100,
                      color: Colors.white24,
            ),
                    SizedBox(height: 16),
            Text(
                      'Live Camera Feed',
              style: TextStyle(
                        color: Colors.white38,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
              ),
            ),
                    SizedBox(height: 8),
            Text(
                      'Meta-style Live Streaming',
              style: TextStyle(
                        color: Colors.white24,
                fontSize: 14,
              ),
            ),
          ],
                ),
              ),
            ),
          ),
          
          // Camera overlay effects
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
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

  Widget _buildMainControls(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comments button
            _buildControlButton(
              icon: Icons.chat_bubble_outline,
              label: 'Comments',
              onTap: _toggleComments,
              isActive: _isCommentsVisible,
            ),
            
            const SizedBox(height: 12),
            
            // Effects button
            _buildControlButton(
              icon: Icons.auto_awesome,
              label: 'Effects',
              onTap: _toggleEffects,
              isActive: _isEffectsVisible,
            ),
            
            const SizedBox(height: 12),
            
            // Settings button
            _buildControlButton(
              icon: Icons.settings,
              label: 'Settings',
              onTap: _toggleSettings,
              isActive: _isSettingsVisible,
            ),
            
            const SizedBox(height: 12),
            
            // End stream button
            _buildControlButton(
              icon: Icons.stop,
              label: 'End',
              onTap: _endStream,
              isActive: false,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withOpacity(0.9)
              : isActive 
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.8)
                : isActive 
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDestructive
                  ? Colors.red.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDestructive 
                  ? Colors.white 
                  : isActive 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.9),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDestructive 
                    ? Colors.white 
                    : isActive 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.9),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                      'Live Comments',
                style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleComments,
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
              
              // Comments list
              Expanded(
                child: ListView.builder(
                  controller: _commentsController,
                  padding: const EdgeInsets.all(16),
                  itemCount: 5, // Mock comments
                  itemBuilder: (context, index) {
                    return _buildCommentItem(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    final comments = [
      {'user': 'Sarah M.', 'message': 'Amazing reading! 🙏', 'time': '2m'},
      {'user': 'Mike R.', 'message': 'Can you read my chart next?', 'time': '1m'},
      {'user': 'Emma L.', 'message': 'This is so accurate! ✨', 'time': '30s'},
      {'user': 'John D.', 'message': 'Thank you for the insights!', 'time': '15s'},
      {'user': 'Lisa K.', 'message': 'Love your energy! 💫', 'time': '5s'},
    ];
    
    final comment = comments[index];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              comment['user']!.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment['user']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment['message']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildEffectsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 200,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Effects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleEffects,
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
              
              // Effects grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final effects = ['✨', '🌟', '💫', '⭐', '🔥', '💎', '🎉', '❤️'];
                      return _buildEffectButton(effects[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectButton(String emoji) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _liveService.incrementLikes();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ThemeService themeService) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 80,
      height: 250,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Stream Settings',
                        style: TextStyle(
                        color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleSettings,
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
              
              // Settings options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.visibility,
                        title: 'Viewer Count',
                        subtitle: 'Show viewer count',
                        value: true,
                        onChanged: (value) {},
                      ),
                      _buildSettingItem(
                        icon: Icons.comment,
                        title: 'Comments',
                        subtitle: 'Allow comments',
                        value: true,
                        onChanged: (value) {},
                      ),
                      _buildSettingItem(
                        icon: Icons.share,
                        title: 'Share',
                        subtitle: 'Allow sharing',
                        value: true,
                        onChanged: (value) {},
                      ),
                      _buildSettingItem(
                        icon: Icons.record_voice_over,
                        title: 'Voice',
                        subtitle: 'Enable microphone',
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
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
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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
            inactiveTrackColor: Colors.white.withOpacity(0.2),
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