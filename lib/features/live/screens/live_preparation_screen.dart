import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/audio/audio_waveform_widget.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../bloc/live_bloc.dart';
import '../bloc/live_event.dart';
import '../bloc/live_state.dart';
import 'live_streaming_screen.dart';

class LivePreparationScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  final Function(int)? onNavigateToPage; // Callback to navigate to specific page
  
  const LivePreparationScreen({
    super.key,
    this.onClose,
    this.isVisible = true, // Default to true for standalone usage
    this.onNavigateToPage,
  });

  @override
  State<LivePreparationScreen> createState() => _LivePreparationScreenState();
}

class _LivePreparationScreenState extends State<LivePreparationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = true;
  bool _isLoadingCamera = true;
  String? _cameraError;
  bool _isCameraMuted = false; // User manually turned off camera
  bool _isCameraInitializing = false; // Track if init is in progress
  int _initializationId = 0; // To cancel stale initializations
  
  // Audio
  StreamSubscription<List<int>>? _audioSubscription;
  Timer? _audioUpdateTimer;
  double _lastAudioLevel = 0.0;
  bool _isMicMuted = false; // User manually muted mic
  
  // Form
  final _titleController = TextEditingController();
  LiveStreamCategory _selectedCategory = LiveStreamCategory.astrology;
  bool _isStartingLive = false;

  // Settings
  bool _isPublic = true;
  bool _isHDQuality = true;
  bool _commentsEnabled = true;
  
  // Bottom sheet state
  bool _isBottomSheetOpen = false;

  // Animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // Services
  final LiveStreamService _liveService = LiveStreamService();
  
  // 🚀 PROFESSIONAL FIX: Store BLoC reference to avoid context access during dispose
  LiveBloc? _liveBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't set default text - let user type their own topic
    
    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
    
    // Only initialize camera if page is visible
    if (widget.isVisible) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(LivePreparationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle visibility changes
    if (widget.isVisible && !oldWidget.isVisible) {
      // Page became visible → Initialize camera
      _initializeCamera();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      // Page became hidden → Pause/dispose camera
      _pauseCamera();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Camera initialization is handled explicitly in _goLive() after returning from live stream
    // and in didUpdateWidget() for visibility changes
  }

  void _pauseCamera() {
    debugPrint('📷 [CAMERA] _pauseCamera called - initialized: $_isCameraInitialized, initializing: $_isCameraInitializing');
    
    // Increment ID to cancel any in-progress initialization
    _initializationId++;
    
    // Stop audio stream regardless of camera state
      _stopAudioStream();
    
    // Dispose camera if it exists (whether fully initialized or not)
    if (_cameraController != null) {
      _cameraController?.dispose();
      _cameraController = null;
    }
    
    // Reset all camera state
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isCameraInitializing = false;
        _isLoadingCamera = false;
      });
    }
    
    debugPrint('📷 [CAMERA] Camera paused and disposed');
  }

  void _startAudioStream() {
    try {
      // Start listening to microphone
      _audioSubscription = MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      ).listen((samples) {
        if (samples.isNotEmpty && mounted) {
          final normalizedLevel = _computeAudioLevel(samples);

          // Dispatch to BLoC (throttled by timer to avoid excessive updates)
          if (_audioUpdateTimer == null || !_audioUpdateTimer!.isActive) {
            // 🚀 PROFESSIONAL FIX: Use stored BLoC reference instead of context
            _liveBloc?.add(AudioLevelUpdatedEvent(normalizedLevel));
            
            // Throttle updates to ~20 times per second
            _audioUpdateTimer = Timer(const Duration(milliseconds: 50), () {});
          }
        }
      });
    } catch (e) {
      print('Error starting audio stream: $e');
    }
  }

  void _stopAudioStream() {
    _audioSubscription?.cancel();
    _audioSubscription = null;
    _audioUpdateTimer?.cancel();
    _audioUpdateTimer = null;
    _lastAudioLevel = 0.0;
    
    // 🚀 PROFESSIONAL FIX: Use stored BLoC reference instead of accessing context
    // This prevents "Looking up a deactivated widget's ancestor" errors during dispose
    _liveBloc?.add(const AudioLevelUpdatedEvent(0.0));
  }

  double _computeAudioLevel(List<int> samples) {
    // Convert PCM 16-bit little-endian bytes to signed 16-bit samples
    final byteData = ByteData.view(Uint8List.fromList(samples).buffer);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount == 0) return 0.0;

    double sumSq = 0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little).toDouble();
      sumSq += sample * sample;
    }

    // Root-mean-square amplitude
    final rms = math.sqrt(sumSq / sampleCount);

    // Normalize: typical voice RMS ~2000-8000; scale for responsiveness
    final normalized = (rms / 5000.0).clamp(0.0, 1.0);

    // Smooth to avoid jitter
    _lastAudioLevel = (_lastAudioLevel * 0.65) + (normalized * 0.35);
    return _lastAudioLevel;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Pause camera and stop audio when app goes to background
      // This also cancels any in-progress initialization
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Resume camera ONLY if this page is visible
      // Prevents camera from starting when user is on dashboard
      if (widget.isVisible && !_isCameraInitialized && !_isCameraInitializing && !_isCameraMuted) {
      _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Capture current initialization ID to detect cancellation
    final currentInitId = ++_initializationId;
    
    debugPrint('📷 [CAMERA] _initializeCamera started (id: $currentInitId)');
    
    setState(() {
      _isLoadingCamera = true;
      _isCameraInitializing = true;
      _cameraError = null;
    });

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      
      // Check if cancelled during permission request
      if (currentInitId != _initializationId || !mounted) {
        debugPrint('📷 [CAMERA] Init cancelled after permissions (id: $currentInitId)');
        return;
      }
      
      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        setState(() {
          _cameraError = 'Camera and microphone permissions are required';
          _isLoadingCamera = false;
          _isCameraInitializing = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      
      // Check if cancelled during camera enumeration
      if (currentInitId != _initializationId || !mounted) {
        debugPrint('📷 [CAMERA] Init cancelled after getting cameras (id: $currentInitId)');
        return;
      }
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device';
          _isLoadingCamera = false;
          _isCameraInitializing = false;
        });
        return;
      }

      // Select front camera by default
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      // Check if cancelled during camera initialization
      if (currentInitId != _initializationId || !mounted) {
        debugPrint('📷 [CAMERA] Init cancelled after controller init (id: $currentInitId)');
        // Dispose the controller we just initialized since it's no longer needed
        _cameraController?.dispose();
        _cameraController = null;
        return;
      }
      
      // Start audio stream only if mic is not muted
      if (!_isMicMuted) {
        _startAudioStream();
      }
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraInitializing = false;
          _isLoadingCamera = false;
          _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
          _isCameraMuted = false; // Reset muted flag on successful init
        });
        debugPrint('📷 [CAMERA] Init completed successfully (id: $currentInitId)');
      }
    } catch (e) {
      debugPrint('📷 [CAMERA] Init error: $e');
      if (mounted && currentInitId == _initializationId) {
        setState(() {
          _cameraError = 'Failed to initialize camera: ${e.toString()}';
          _isLoadingCamera = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    HapticFeedback.lightImpact();
    
    setState(() => _isLoadingCamera = true);

    try {
      await _cameraController?.dispose();
      
      // Toggle camera direction
      final newCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == 
          (_isFrontCamera ? CameraLensDirection.back : CameraLensDirection.front),
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoadingCamera = false;
          _isFrontCamera = newCamera.lensDirection == CameraLensDirection.front;
          _isFlashOn = false; // Reset flash when flipping
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCamera = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    
    HapticFeedback.lightImpact();
    
    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      // Flash not supported, revert state
      if (mounted) {
        setState(() => _isFlashOn = false);
      }
    }
  }

  Future<void> _startLiveStream() async {
    // Validate topic/description is not empty
    if (_titleController.text.trim().isEmpty) {
      // Trigger shake animation
      _shakeController.forward(from: 0);
      
      // Haptic feedback (error vibration)
      HapticFeedback.heavyImpact();
      
      // Show bottom sheet if not already open
      _showTitleBottomSheet();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please add a topic for your stream',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isStartingLive = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await _liveService.startLiveStream(
        title: _titleController.text.trim(),
        description: null,
        category: _selectedCategory,
        quality: LiveStreamQuality.high,
        isPrivate: false,
        tags: const [],
      );

      if (success && mounted) {
        // Stop audio stream and dispose camera before navigating to live streaming
        _stopAudioStream();
        await _cameraController?.dispose();
        _cameraController = null;
        setState(() {
          _isCameraInitialized = false;
          _isLoadingCamera = false;
        });
        
        if (mounted) {
          // Push to live streaming screen with title and category
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LiveStreamingScreen(
                title: _titleController.text.trim(),
                description: null,
                category: _selectedCategory,
              ),
            ),
          );
          
          // After returning from live stream - reinitialize camera and stay here
          if (mounted) {
            _initializeCamera();
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start live stream')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingLive = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop audio stream
    _stopAudioStream();
    // Properly dispose camera controller
    _cameraController?.dispose().then((_) {
      _cameraController = null;
    });
    _titleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
                    children: [
                // Layer 1: Camera Preview (Full Screen)
                _buildCameraPreview(),
                
                // Layer 1.5: Blur overlay when bottom sheet is open (performance optimization)
                if (_isBottomSheetOpen)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                
                // Layer 2: Gradient Overlays
                _buildGradientOverlays(),
                
                // Layer 3: Top Controls
                _buildTopControls(),
                
                // Layer 3.5: Top Badges (Minimal Settings)
                _buildTopBadges(),
                
                // Layer 3.7: Camera/Mic Status (render on top)
                _buildCameraMicStatus(),
                
                // Layer 4: Bottom Section
                _buildBottomSection(),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    // Show creative placeholder when camera is manually muted
    if (_isCameraMuted) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F0F1E),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white.withOpacity(0.7),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Camera Off',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the camera icon to turn it back on',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_cameraError != null) {
    return Container(
        color: Colors.black,
        child: Center(
      child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              Text(
                _cameraError!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
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

    if (_isLoadingCamera || !_isCameraInitialized || _cameraController == null) {
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

    // Full-screen camera preview
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return Column(
      children: [
        // Top gradient (for controls visibility)
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                    ],
                  ),
                ),
        ),
        const Spacer(),
        // Bottom gradient (for input & button visibility)
        Container(
          height: 380,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
            ),
          ),
        ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          _buildIconButton(
            icon: Icons.close,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Row(
              children: [
              // Flash (only for back camera)
              if (!_isFrontCamera)
                _buildIconButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onTap: _toggleFlash,
                  isActive: _isFlashOn,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCameraMicStatus() {
    final bool cameraActive = !_isCameraMuted && _isCameraInitialized && _cameraError == null;
    final bool micActive = !_isMicMuted && _audioSubscription != null;
    final bool canFlip = _cameras != null && _cameras!.length > 1;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera Flip - Google Camera style
          if (canFlip)
            _buildGoogleCameraIcon(
              icon: Icons.flip_camera_ios_rounded,
              onTap: _flipCamera,
              isActive: true,
            ),
          if (canFlip) const SizedBox(height: 16),
          
          // Camera On/Off
          _buildGoogleCameraIcon(
            icon: cameraActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            onTap: _toggleCamera,
            isActive: cameraActive,
            showActiveIndicator: true,
          ),
          const SizedBox(height: 16),
          
          // Mic On/Off
          _buildGoogleCameraIcon(
            icon: micActive ? Icons.mic_rounded : Icons.mic_off_rounded,
            onTap: _toggleMic,
            isActive: micActive,
            showActiveIndicator: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleCameraIcon({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    bool showActiveIndicator = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.25),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.5),
                size: 24,
              ),
              if (showActiveIndicator && isActive)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
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

  Widget _buildStatusIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(isActive ? 0.9 : 0.4),
                size: 22,
              ),
              if (isActive)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
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

  void _toggleCamera() {
    setState(() {
      _isCameraMuted = !_isCameraMuted;
    });
    
    if (_isCameraMuted) {
      // Stop camera
      _stopAudioStream(); // Also stop audio when camera is off
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.videocam_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Camera turned off'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else {
      // Restart camera
      _initializeCamera();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.videocam, color: Colors.white),
              SizedBox(width: 12),
              Text('Camera turned on'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    
    if (_isMicMuted) {
      // Stop mic
      _stopAudioStream();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mic_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Microphone muted'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else {
      // Start mic (only if camera is on)
      if (!_isCameraMuted && _isCameraInitialized) {
        _startAudioStream();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 12),
                Text('Microphone unmuted'),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        // Can't unmute mic without camera
        setState(() {
          _isMicMuted = true; // Revert
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Turn on camera first'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive 
          ? Colors.white.withOpacity(0.3)
          : Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(isActive ? 0.6 : 0.3),
          width: 1.5,
          ),
        ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 16,
      right: 16,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LiveStreamCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = category);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(isSelected ? 1 : 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                _getCategoryDisplayName(category),
                style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 13,
                  fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
              ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool hasTopicFilled = _titleController.text.trim().isNotEmpty;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Topic Display (minimal text overlay)
          _buildMinimalTopicDisplay(),
          
          const SizedBox(height: 20),
          
          // Audio Level Meter
          _buildAudioMeter(),
          
          const SizedBox(height: 24),
          
          // Thin separator line
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Simple Go Live Button
          _buildMinimalGoLiveButton(hasTopicFilled),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopBadges() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HD/SD Toggle - Google Camera style
          _buildGoogleCameraIcon(
            icon: _isHDQuality ? Icons.hd_rounded : Icons.sd_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isHDQuality = !_isHDQuality);
            },
            isActive: true,
          ),
          const SizedBox(height: 16),
          
          // Comments Toggle
          _buildGoogleCameraIcon(
            icon: _commentsEnabled ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _commentsEnabled = !_commentsEnabled);
            },
            isActive: _commentsEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalBadge({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTopicDisplay() {
    final bool hasTopicFilled = _titleController.text.trim().isNotEmpty;
    final topicText = _titleController.text.trim();
    
    return AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1),
            0,
          ),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _showTitleBottomSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasTopicFilled ? Icons.description : Icons.edit_outlined,
                    color: Colors.white,
                    size: 18,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTopicFilled ? topicText : 'No topic - Tap to add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: hasTopicFilled ? 16 : 15,
                        fontWeight: hasTopicFilled ? FontWeight.w600 : FontWeight.w500,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                      ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasTopicFilled) ...[
                    const SizedBox(width: 8),
                        Icon(
                      Icons.edit,
                      color: Colors.white.withOpacity(0.7),
                          size: 16,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ],
                ],
              ),
              if (hasTopicFilled) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _getCategoryEmoji(_selectedCategory),
                      style: const TextStyle(
                        fontSize: 14,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                      _getCategoryDisplayName(_selectedCategory),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                            fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                          ),
                        ),
                      ],
                    ),
              ],
            ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAudioMeter() {
    return BlocBuilder<LiveBloc, LiveState>(
      builder: (context, state) {
        // Get audio level from state (default to 0.0)
        double audioLevel = 0.0;
        if (state is LiveLoadedState) {
          audioLevel = state.audioLevel;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              // Mic icon with glow when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: audioLevel > 0.1 
                      ? Colors.white.withOpacity(0.15) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isMicMuted ? Icons.mic_off : Icons.mic,
                  color: _isMicMuted 
                      ? Colors.red.withOpacity(0.8)
                      : Colors.white.withOpacity(audioLevel > 0.1 ? 1.0 : 0.6),
                  size: 18,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // WhatsApp-style waveform visualization
              Expanded(
                child: AudioWaveformWidget(
                  mode: WaveformMode.live,
                  audioLevel: _isMicMuted ? 0.0 : audioLevel,
                  barCount: 40,
                  barWidth: 3.0,
                  barSpacing: 2.0,
                  minBarHeight: 4.0,
                  maxBarHeight: 28.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  enableRippleEffect: true,
                  enableGlow: true,
                  barBorderRadius: 2.0,
                ),
              ),
              const SizedBox(width: 12),
              // Audio level indicator
              if (!_isMicMuted)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: audioLevel > 0.1 ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getAudioLevelColor(audioLevel).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getAudioLevelColor(audioLevel).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getAudioLevelLabel(audioLevel),
                      style: TextStyle(
                        color: _getAudioLevelColor(audioLevel),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getAudioLevelColor(double level) {
    if (level > 0.8) return Colors.red; // Too loud
    if (level > 0.5) return Colors.green; // Good
    if (level > 0.2) return Colors.amber; // Low
    return Colors.white54; // Very low
  }
  
  String _getAudioLevelLabel(double level) {
    if (level > 0.8) return 'LOUD';
    if (level > 0.5) return 'GOOD';
    if (level > 0.2) return 'LOW';
    return 'QUIET';
  }

  Widget _buildMinimalGoLiveButton(bool isEnabled) {
    return GestureDetector(
      onTap: !_isStartingLive ? _handleGoLiveTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isStartingLive)
              const SizedBox(
                width: 20,
                height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
            else ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isEnabled ? const Color(0xFFFF4444) : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4444).withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                              ),
              const SizedBox(width: 12),
              Text(
                'GO LIVE',
                                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 12,
                              ),
                            ],
                          ),
                  ),
            ],
          ],
          ),
      ),
    );
  }

  Future<void> _handleGoLiveTap() async {
    // If no topic, open the bottom sheet first
    if (_titleController.text.trim().isEmpty) {
      await _showTitleBottomSheet();
      if (!mounted) return;
      if (_titleController.text.trim().isNotEmpty) {
        await _startLiveStream();
      }
    } else {
      await _startLiveStream();
    }
  }

  String _getCategoryEmoji(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return '💬';
      case LiveStreamCategory.astrology:
        return '⭐';
      case LiveStreamCategory.healing:
        return '🌿';
      case LiveStreamCategory.meditation:
        return '🧘';
      case LiveStreamCategory.tarot:
        return '🔮';
      case LiveStreamCategory.numerology:
        return '🔢';
      case LiveStreamCategory.palmistry:
        return '✋';
      case LiveStreamCategory.spiritual:
        return '🕉️';
    }
  }

  Future<void> _showTitleBottomSheet() async {
    HapticFeedback.lightImpact();
    
    // Set bottom sheet state - triggers blur overlay
    setState(() => _isBottomSheetOpen = true);
    
    // Small delay to let blur render before sheet animates
    await Future.delayed(const Duration(milliseconds: 50));
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true, // Better performance - uses root overlay
      builder: (context) => _TitleBottomSheet(
        controller: _titleController,
        selectedCategory: _selectedCategory,
        onCategoryChanged: (category) {
          setState(() => _selectedCategory = category);
        },
        onSave: () {
          setState(() {}); // Refresh UI to show updated title
        },
      ),
    );
    
    // Remove blur overlay after bottom sheet closes
    if (mounted) {
      setState(() => _isBottomSheetOpen = false);
    }
  }

  String _getCategoryDisplayName(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return 'General';
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.tarot:
        return 'Tarot';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
    }
  }
}

// Facebook-inspired bottom sheet for title input
class _TitleBottomSheet extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final LiveStreamCategory selectedCategory;
  final Function(LiveStreamCategory) onCategoryChanged;
  
  const _TitleBottomSheet({
    required this.controller,
    required this.onSave,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<_TitleBottomSheet> createState() => _TitleBottomSheetState();
}

class _TitleBottomSheetState extends State<_TitleBottomSheet> {
  late FocusNode _focusNode;
  late LiveStreamCategory _localSelectedCategory; // Local state for immediate UI updates
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _localSelectedCategory = widget.selectedCategory; // Initialize from parent
    
    // Auto-focus when sheet opens (delay to let sheet animation complete first)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _selectCategory(LiveStreamCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _localSelectedCategory = category; // Update local state immediately
    });
    widget.onCategoryChanged(category); // Notify parent
  }

  void _handleDone() {
    HapticFeedback.lightImpact();
    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0F1E),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header (increased height)
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
              child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Add details to your stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handleDone,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF4A9FFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Content Area
          Expanded(
            child: Column(
              children: [
                // Category Chips (at top, always visible)
                _buildCategoryChips(),
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withOpacity(0.08),
                ),
                
                // Text Input Area (below categories)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: "What will you talk about today?",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 200,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Category',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: LiveStreamCategory.values.map((category) {
                final isSelected = _localSelectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectCategory(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A9FFF)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4A9FFF)
                              : Colors.white.withOpacity(0.15),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCategoryDisplayName(category),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
                );
              }).toList(),
          ),
        ),
      ],
      ),
    );
  }

  String _getCategoryDisplayName(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return 'General';
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.tarot:
        return 'Tarot';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
    }
  }

  String _getCategoryEmoji(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return '💬';
      case LiveStreamCategory.astrology:
        return '⭐';
      case LiveStreamCategory.healing:
        return '🌿';
      case LiveStreamCategory.meditation:
        return '🧘';
      case LiveStreamCategory.tarot:
        return '🔮';
      case LiveStreamCategory.numerology:
        return '🔢';
      case LiveStreamCategory.palmistry:
        return '✋';
      case LiveStreamCategory.spiritual:
        return '🕉️';
      }
  }
}



