import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Waveform display modes
enum WaveformMode {
  /// Real-time microphone input visualization
  live,
  
  /// Pre-recorded waveform playback (for voice messages)
  playback,
  
  /// Static waveform display (no animation)
  static,
}

/// A WhatsApp-style audio waveform visualization widget.
/// 
/// Supports multiple modes:
/// - [WaveformMode.live]: Real-time audio level visualization (for mic input)
/// - [WaveformMode.playback]: Voice message playback with progress
/// - [WaveformMode.static]: Static display without animation
/// 
/// Example usage:
/// ```dart
/// AudioWaveformWidget(
///   mode: WaveformMode.live,
///   audioLevel: 0.7,
///   activeColor: Colors.white,
/// )
/// ```
class AudioWaveformWidget extends StatefulWidget {
  /// The display mode of the waveform
  final WaveformMode mode;
  
  /// Current audio level for live mode (0.0 - 1.0)
  final double audioLevel;
  
  /// Pre-computed waveform samples for playback mode
  final List<double>? waveformData;
  
  /// Playback progress for playback mode (0.0 - 1.0)
  final double progress;
  
  /// Whether audio is currently playing (for playback mode)
  final bool isPlaying;
  
  /// Number of bars to display
  final int barCount;
  
  /// Width of each bar
  final double barWidth;
  
  /// Spacing between bars
  final double barSpacing;
  
  /// Minimum bar height
  final double minBarHeight;
  
  /// Maximum bar height
  final double maxBarHeight;
  
  /// Color for active/played portion
  final Color activeColor;
  
  /// Color for inactive/unplayed portion
  final Color inactiveColor;
  
  /// Animation duration for bar height changes
  final Duration animationDuration;
  
  /// Whether to show wave ripple effect
  final bool enableRippleEffect;
  
  /// Whether to show glow effect on active bars
  final bool enableGlow;
  
  /// Border radius of bars
  final double barBorderRadius;

  const AudioWaveformWidget({
    super.key,
    this.mode = WaveformMode.live,
    this.audioLevel = 0.0,
    this.waveformData,
    this.progress = 0.0,
    this.isPlaying = false,
    this.barCount = 35,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.minBarHeight = 4.0,
    this.maxBarHeight = 28.0,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
    this.animationDuration = const Duration(milliseconds: 120),
    this.enableRippleEffect = true,
    this.enableGlow = true,
    this.barBorderRadius = 2.0,
  });

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  late List<double> _targetHeights;
  late List<double> _currentHeights;
  
  // For wave ripple effect
  int _rippleIndex = 0;
  
  // Random for natural variation
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );
    
    _barAnimations = List.generate(
      widget.barCount,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _barControllers[index],
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    
    _targetHeights = List.filled(widget.barCount, widget.minBarHeight);
    _currentHeights = List.filled(widget.barCount, widget.minBarHeight);
  }

  @override
  void didUpdateWidget(AudioWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle bar count changes
    if (oldWidget.barCount != widget.barCount) {
      _disposeControllers();
      _initializeAnimations();
    }
    
    // Update heights based on mode
    if (widget.mode == WaveformMode.live) {
      _updateLiveHeights();
    } else if (widget.mode == WaveformMode.playback) {
      _updatePlaybackHeights();
    }
  }

  void _updateLiveHeights() {
    final audioLevel = widget.audioLevel.clamp(0.0, 1.0);
    final heightRange = widget.maxBarHeight - widget.minBarHeight;
    
    for (int i = 0; i < widget.barCount; i++) {
      // Create natural wave pattern
      double variation;
      
      if (widget.enableRippleEffect) {
        // Wave ripple from center
        final center = widget.barCount / 2;
        final distanceFromCenter = (i - center).abs() / center;
        final wavePhase = (i + _rippleIndex) * 0.3;
        variation = math.sin(wavePhase) * 0.3 + 0.7;
        
        // Fade edges
        final edgeFade = 1.0 - (distanceFromCenter * 0.4);
        variation *= edgeFade;
      } else {
        // Simple random variation
        variation = 0.7 + _random.nextDouble() * 0.3;
      }
      
      // Calculate target height
      final baseHeight = widget.minBarHeight;
      final dynamicHeight = audioLevel * heightRange * variation;
      _targetHeights[i] = (baseHeight + dynamicHeight).clamp(
        widget.minBarHeight,
        widget.maxBarHeight,
      );
      
      // Animate to target
      final oldHeight = _currentHeights[i];
      _currentHeights[i] = _targetHeights[i];
      
      // Reset and run animation
      _barControllers[i].reset();
      _barAnimations[i] = Tween<double>(
        begin: oldHeight,
        end: _targetHeights[i],
      ).animate(CurvedAnimation(
        parent: _barControllers[i],
        curve: Curves.easeOutCubic,
      ));
      _barControllers[i].forward();
    }
    
    // Increment ripple index for wave effect
    _rippleIndex++;
  }

  void _updatePlaybackHeights() {
    if (widget.waveformData == null || widget.waveformData!.isEmpty) return;
    
    final data = widget.waveformData!;
    final heightRange = widget.maxBarHeight - widget.minBarHeight;
    
    for (int i = 0; i < widget.barCount; i++) {
      // Map bar index to waveform data
      final dataIndex = (i / widget.barCount * data.length).floor();
      final sample = data[dataIndex.clamp(0, data.length - 1)];
      
      _targetHeights[i] = widget.minBarHeight + (sample * heightRange);
    }
  }

  void _disposeControllers() {
    for (final controller in _barControllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxBarHeight,
      child: CustomPaint(
        painter: _WaveformPainter(
          barCount: widget.barCount,
          barWidth: widget.barWidth,
          barSpacing: widget.barSpacing,
          minBarHeight: widget.minBarHeight,
          maxBarHeight: widget.maxBarHeight,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          barBorderRadius: widget.barBorderRadius,
          enableGlow: widget.enableGlow,
          mode: widget.mode,
          progress: widget.progress,
          barAnimations: _barAnimations,
          targetHeights: _targetHeights,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final double minBarHeight;
  final double maxBarHeight;
  final Color activeColor;
  final Color inactiveColor;
  final double barBorderRadius;
  final bool enableGlow;
  final WaveformMode mode;
  final double progress;
  final List<Animation<double>> barAnimations;
  final List<double> targetHeights;

  _WaveformPainter({
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
    required this.minBarHeight,
    required this.maxBarHeight,
    required this.activeColor,
    required this.inactiveColor,
    required this.barBorderRadius,
    required this.enableGlow,
    required this.mode,
    required this.progress,
    required this.barAnimations,
    required this.targetHeights,
  }) : super(repaint: Listenable.merge(barAnimations));

  @override
  void paint(Canvas canvas, Size size) {
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < barCount; i++) {
      // Get animated height
      final height = barAnimations[i].value;
      
      // Calculate bar position
      final x = startX + i * (barWidth + barSpacing);
      final y = centerY - height / 2;
      
      // Determine color based on mode and progress
      Color barColor;
      if (mode == WaveformMode.playback) {
        final barProgress = i / barCount;
        barColor = barProgress <= progress ? activeColor : inactiveColor;
      } else {
        // Live mode - use active color with opacity based on height
        final heightRatio = (height - minBarHeight) / (maxBarHeight - minBarHeight);
        barColor = activeColor.withOpacity(0.5 + heightRatio * 0.5);
      }
      
      // Draw glow effect for active bars
      if (enableGlow && mode == WaveformMode.live) {
        final heightRatio = (height - minBarHeight) / (maxBarHeight - minBarHeight);
        if (heightRatio > 0.3) {
          final glowPaint = Paint()
            ..color = activeColor.withOpacity(heightRatio * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 1, y - 1, barWidth + 2, height + 2),
              Radius.circular(barBorderRadius + 1),
            ),
            glowPaint,
          );
        }
      }
      
      // Draw bar
      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          Radius.circular(barBorderRadius),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}

/// A compact version of the waveform for inline use (like chat bubbles)
class CompactAudioWaveform extends StatelessWidget {
  final double audioLevel;
  final double progress;
  final bool isPlaying;
  final Color color;
  final double height;
  
  const CompactAudioWaveform({
    super.key,
    this.audioLevel = 0.0,
    this.progress = 0.0,
    this.isPlaying = false,
    this.color = Colors.white,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AudioWaveformWidget(
        mode: isPlaying ? WaveformMode.live : WaveformMode.playback,
        audioLevel: audioLevel,
        progress: progress,
        isPlaying: isPlaying,
        barCount: 25,
        barWidth: 2.5,
        barSpacing: 1.5,
        minBarHeight: 3.0,
        maxBarHeight: height - 4,
        activeColor: color,
        inactiveColor: color.withOpacity(0.3),
        enableGlow: false,
        enableRippleEffect: true,
      ),
    );
  }
}









