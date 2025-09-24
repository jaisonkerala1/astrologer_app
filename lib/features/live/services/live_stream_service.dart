import 'package:flutter/foundation.dart';

// Stub service to avoid build conflicts
// This is a temporary service for the existing live streaming functionality
// The new live streaming page uses LiveStreamCardModel instead

class LiveStreamService extends ChangeNotifier {
  static LiveStreamService? _instance;
  
  LiveStreamService._();
  
  static LiveStreamService get instance {
    _instance ??= LiveStreamService._();
    return _instance!;
  }
  
  void initialize() {
    // Stub implementation
  }
}