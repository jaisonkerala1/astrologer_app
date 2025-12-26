/// Reusable Wakelock Service
/// Handles screen wake management for live streaming, video calls, etc.
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockService {
  static final WakelockService _instance = WakelockService._internal();
  factory WakelockService() => _instance;
  WakelockService._internal();

  bool _isEnabled = false;
  int _activeSessions = 0; // Track multiple sessions (e.g., multiple live streams)

  /// Check if wakelock is currently enabled
  bool get isEnabled => _isEnabled;

  /// Get number of active sessions requiring wakelock
  int get activeSessions => _activeSessions;

  /// Enable wakelock (increment session count)
  /// Returns true if wakelock was successfully enabled
  Future<bool> enable() async {
    try {
      _activeSessions++;
      print('🔋 [WAKELOCK SERVICE] Enable called (sessions: $_activeSessions)');
      
      if (!_isEnabled) {
        await WakelockPlus.enable();
        _isEnabled = true;
        print('✅ [WAKELOCK SERVICE] Wakelock enabled - screen will stay awake');
        return true;
      }
      
      print('ℹ️ [WAKELOCK SERVICE] Wakelock already enabled');
      return true;
    } catch (e) {
      print('❌ [WAKELOCK SERVICE] Failed to enable: $e');
      _activeSessions = _activeSessions > 0 ? _activeSessions - 1 : 0;
      return false;
    }
  }

  /// Disable wakelock (decrement session count)
  /// Only disables if no active sessions remain
  Future<bool> disable() async {
    try {
      if (_activeSessions > 0) {
        _activeSessions--;
      }
      print('🔋 [WAKELOCK SERVICE] Disable called (sessions: $_activeSessions)');

      if (_activeSessions <= 0 && _isEnabled) {
        await WakelockPlus.disable();
        _isEnabled = false;
        _activeSessions = 0; // Reset to prevent negative values
        print('✅ [WAKELOCK SERVICE] Wakelock disabled - screen can sleep');
        return true;
      }

      print('ℹ️ [WAKELOCK SERVICE] Wakelock still needed (sessions: $_activeSessions)');
      return true;
    } catch (e) {
      print('❌ [WAKELOCK SERVICE] Failed to disable: $e');
      return false;
    }
  }

  /// Force disable wakelock (for emergency cleanup)
  /// Use when app goes to background or crashes
  Future<bool> forceDisable() async {
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
      _activeSessions = 0;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset session count (use with caution)
  void reset() {
    _activeSessions = 0;
    _isEnabled = false;
  }
}

