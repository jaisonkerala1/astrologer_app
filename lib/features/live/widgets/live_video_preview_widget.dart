import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Video source enum - for future Agora/WebRTC integration
enum VideoSource {
  /// Local camera preview (current implementation)
  localCamera,
  
  /// Agora RTC video (future implementation)
  agora,
  
  /// WebRTC video (future implementation)
  webrtc,
}

/// A reusable video preview widget that abstracts the video source.
/// 
/// Currently supports local camera preview.
/// Designed to be easily swapped with Agora or other video sources in the future.
/// 
/// Usage:
/// ```dart
/// LiveVideoPreviewWidget(
///   cameraController: _cameraController,
///   isCameraInitialized: _isCameraInitialized,
///   isLoading: _isLoadingCamera,
///   errorMessage: _cameraError,
///   videoSource: VideoSource.localCamera,
/// )
/// ```
/// 
/// Future Agora integration:
/// ```dart
/// LiveVideoPreviewWidget(
///   videoSource: VideoSource.agora,
///   agoraEngine: _agoraEngine,
///   agoraUid: _localUid,
/// )
/// ```
class LiveVideoPreviewWidget extends StatelessWidget {
  /// The video source to use for rendering
  final VideoSource videoSource;
  
  /// Camera controller for local camera preview
  final CameraController? cameraController;
  
  /// Whether the camera is initialized
  final bool isCameraInitialized;
  
  /// Whether the camera is loading
  final bool isLoading;
  
  /// Error message if camera initialization failed
  final String? errorMessage;
  
  /// Optional overlay widget to show on top of the video
  final Widget? overlay;
  
  /// Callback when user taps retry after an error
  final VoidCallback? onRetry;
  
  // Future Agora properties (commented out for now)
  // final RtcEngine? agoraEngine;
  // final int? agoraUid;
  // final String? agoraChannelId;

  const LiveVideoPreviewWidget({
    super.key,
    this.videoSource = VideoSource.localCamera,
    this.cameraController,
    this.isCameraInitialized = false,
    this.isLoading = false,
    this.errorMessage,
    this.overlay,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video content based on source
          _buildVideoContent(context),
          
          // Optional overlay
          if (overlay != null) overlay!,
        ],
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    switch (videoSource) {
      case VideoSource.localCamera:
        return _buildLocalCameraPreview(context);
      case VideoSource.agora:
        return _buildAgoraPlaceholder();
      case VideoSource.webrtc:
        return _buildWebRTCPlaceholder();
    }
  }

  /// Builds the local camera preview
  Widget _buildLocalCameraPreview(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return _buildLoadingState();
    }

    // Show error state
    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    // Show camera preview
    if (isCameraInitialized && cameraController != null) {
      return _buildCameraPreview();
    }

    // Fallback - no camera
    return _buildNoCameraState();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
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

  Widget _buildErrorState(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Camera error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: cameraController!.value.previewSize?.height ?? 1920,
            height: cameraController!.value.previewSize?.width ?? 1080,
            child: CameraPreview(cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCameraState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'No camera available',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder for Agora integration
  /// TODO: Replace with actual Agora LocalView/RemoteView when integrating
  Widget _buildAgoraPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Agora Video',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Integration pending',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
    
    // Future Agora implementation:
    // return AgoraVideoView(
    //   controller: VideoViewController(
    //     rtcEngine: agoraEngine!,
    //     canvas: VideoCanvas(uid: agoraUid),
    //   ),
    // );
  }

  /// Placeholder for WebRTC integration
  Widget _buildWebRTCPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'WebRTC Video',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Integration pending',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


