import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import 'live_streaming_screen.dart';

class LivePreparationScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  
  const LivePreparationScreen({
    super.key,
    this.onClose,
    this.isVisible = true, // Default to true for standalone usage
  });

  @override
  State<LivePreparationScreen> createState() => _LivePreparationScreenState();
}

class _LivePreparationScreenState extends State<LivePreparationScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = true;
  bool _isLoadingCamera = true;
  String? _cameraError;
  
  // Form
  final _titleController = TextEditingController();
  LiveStreamCategory _selectedCategory = LiveStreamCategory.astrology;
  bool _isStartingLive = false;
  
  // Services
  final LiveStreamService _liveService = LiveStreamService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController.text = 'Daily Astrology Reading';
    
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

  void _pauseCamera() {
    if (_cameraController != null && _isCameraInitialized) {
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
        _isLoadingCamera = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Pause camera when app goes to background
      cameraController.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      // Resume camera when app comes back to foreground
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoadingCamera = true;
      _cameraError = null;
    });

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      
      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        setState(() {
          _cameraError = 'Camera and microphone permissions are required';
          _isLoadingCamera = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device';
          _isLoadingCamera = false;
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
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoadingCamera = false;
          _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Failed to initialize camera: ${e.toString()}';
          _isLoadingCamera = false;
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a stream title')),
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
        // Dispose camera before navigating
        await _cameraController?.dispose();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LiveStreamingScreen(),
            ),
          );
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
    // Properly dispose camera controller
    _cameraController?.dispose().then((_) {
      _cameraController = null;
    });
    _titleController.dispose();
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
                
                // Layer 2: Gradient Overlays
                _buildGradientOverlays(),
                
                // Layer 3: Top Controls
                _buildTopControls(),
                
                // Layer 4: Category Pills
                _buildCategoryPills(),
                
                // Layer 5: Go Live Button + Write Topic Text
                _buildBottomSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview() {
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
              // Flip camera
              if (_cameras != null && _cameras!.length > 1)
                _buildIconButton(
                  icon: Icons.flip_camera_ios,
                  onTap: _flipCamera,
                ),
              if (_cameras != null && _cameras!.length > 1)
                const SizedBox(width: 12),
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
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Go Live Button
          Center(
            child: Container(
              width: 180,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE91E63), // Instagram pink
                    Color(0xFFFC5C7D), // Lighter pink
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isStartingLive ? null : _startLiveStream,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: _isStartingLive
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Go Live',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          
          // Write your topic text (below button, left aligned)
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _showTitleBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _titleController.text.trim().isEmpty
                            ? 'Write your topic'
                            : _titleController.text.trim().length > 25
                                ? '${_titleController.text.trim().substring(0, 25)}...'
                                : _titleController.text.trim(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTitleBottomSheet() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _TitleBottomSheet(
        controller: _titleController,
        onSave: () {
          setState(() {}); // Refresh UI to show updated title
        },
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
}

// Facebook-inspired bottom sheet for title input
class _TitleBottomSheet extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  
  const _TitleBottomSheet({
    required this.controller,
    required this.onSave,
  });

  @override
  State<_TitleBottomSheet> createState() => _TitleBottomSheetState();
}

class _TitleBottomSheetState extends State<_TitleBottomSheet> {
  late FocusNode _focusNode;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // Auto-focus when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDone() {
    HapticFeedback.lightImpact();
    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
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
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'What\'s your stream about?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleDone,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            
            // Input field
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g., Daily Astrology Reading",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 3,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleDone(),
                ),
              ),
            ),
            
            // Tips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use clear, engaging titles to attract viewers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
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
}
