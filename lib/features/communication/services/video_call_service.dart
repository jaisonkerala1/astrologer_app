import 'dart:async';
import 'dart:convert';
import '../../../core/services/storage_service.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

  // Mock video call data (no real WebRTC for now)
  dynamic _localStream;
  dynamic _remoteStream;

  // Mock data
  Timer? _mockCallTimer;
  Timer? _mockConnectionTimer;
  
  // Call state
  String? _currentCallId;
  String? _remoteUserId;
  bool _isCallActive = false;
  bool _isMockMode = true; // Always use mock mode for now
  
  // Callbacks
  Function(dynamic)? onLocalStream;
  Function(dynamic)? onRemoteStream;
  Function(String)? onCallStatusChanged;
  Function(String)? onError;
  Function()? onCallEnded;

  // Getters
  bool get isCallActive => _isCallActive;
  String? get currentCallId => _currentCallId;
  String? get remoteUserId => _remoteUserId;
  dynamic get localStream => _localStream;

  /// Initialize the video call service
  Future<void> initialize() async {
    print('Video call service initialized in mock mode');
    // No real initialization needed for mock mode
  }

  /// Start a video call
  Future<bool> startCall(String remoteUserId) async {
    try {
      _remoteUserId = remoteUserId;
      _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
      _isCallActive = true;

      onCallStatusChanged?.call('Calling...');

      // Simulate call connection with mock data
      _simulateMockCall();
      return true;

    } catch (e) {
      print('Error starting call: $e');
      onError?.call('Failed to start call: $e');
      return false;
    }
  }


  /// End the current call
  void endCall() {
    _mockCallTimer?.cancel();
    _mockConnectionTimer?.cancel();
    _cleanup();
    onCallEnded?.call();
  }

  /// Simulate mock call connection
  void _simulateMockCall() {
    // Simulate call ringing for 2-3 seconds
    _mockCallTimer = Timer(const Duration(seconds: 2), () {
      onCallStatusChanged?.call('Connected');
      
      // Simulate getting local stream (mock)
      _simulateLocalStream();
      
      // Simulate remote stream after 1 second
      Timer(const Duration(seconds: 1), () {
        _simulateRemoteStream();
      });
    });
  }

  /// Simulate local video stream
  void _simulateLocalStream() {
    // In real implementation, this would be the actual camera stream
    // For mock, we'll just trigger the callback
    print('Mock: Local stream started');
    // onLocalStream?.call(_localStream!);
  }

  /// Simulate remote video stream
  void _simulateRemoteStream() {
    // In real implementation, this would be the remote peer's stream
    // For mock, we'll just trigger the callback
    print('Mock: Remote stream started');
    // onRemoteStream?.call(_remoteStream!);
  }


  /// Accept an incoming call (mock)
  Future<bool> acceptCall(String callId) async {
    try {
      _currentCallId = callId;
      _isCallActive = true;

      onCallStatusChanged?.call('Call accepted');
      _simulateMockCall();
      return true;

    } catch (e) {
      print('Error accepting call: $e');
      onError?.call('Failed to accept call: $e');
      return false;
    }
  }

  /// Reject an incoming call (mock)
  void rejectCall(String callId) {
    onCallStatusChanged?.call('Call rejected');
    _cleanup();
  }

  /// Toggle video stream (mock)
  void toggleVideo() {
    print('Mock: Video toggled');
    // In real implementation, this would toggle the video stream
  }

  /// Toggle audio stream (mock)
  void toggleAudio() {
    print('Mock: Audio toggled');
    // In real implementation, this would toggle the audio stream
  }

  /// Get current user ID
  Future<String> _getCurrentUserId() async {
    final storageService = StorageService();
    final userData = await storageService.getUserData();
    
    if (userData == null) {
      throw Exception('User not authenticated');
    }

    final userDataMap = jsonDecode(userData);
    return userDataMap['id'] ?? userDataMap['_id'];
  }

  /// Cleanup resources
  void _cleanup() {
    _localStream = null;
    _remoteStream = null;
    _currentCallId = null;
    _remoteUserId = null;
    _isCallActive = false;
  }

  /// Dispose the service
  void dispose() {
    _mockCallTimer?.cancel();
    _mockConnectionTimer?.cancel();
    _cleanup();
  }
}
