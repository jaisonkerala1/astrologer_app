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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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
  
  // Animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // Services
  final LiveStreamService _liveService = LiveStreamService();

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
                
                // Layer 2: Gradient Overlays
                _buildGradientOverlays(),
                
                // Layer 3: Top Controls
                _buildTopControls(),
                
                // Layer 4: Go Live Button + Write Topic Text
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
          // Write your topic text (above button, left aligned)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * 
                        ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1), 0),
                    child: child,
                  );
                },
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
          ),
          
          const SizedBox(height: 20),
          
          // Go Live Button (full width, aligned with topic text)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4444).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isStartingLive ? null : _startLiveStream,
                  borderRadius: BorderRadius.circular(26),
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
                              const Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: 20,
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
        selectedCategory: _selectedCategory,
        onCategoryChanged: (category) {
          setState(() => _selectedCategory = category);
        },
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
                final isSelected = widget.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onCategoryChanged(category);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCategoryEmoji(category),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getCategoryDisplayName(category),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
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



