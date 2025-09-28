import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class StatusService extends ChangeNotifier {
  static const String _statusKey = 'user_online_status';
  
  bool _isOnline = false;
  bool _disposed = false;
  bool _isUpdating = false;
  String? _lastError;
  final ApiService _apiService = ApiService();
  
  bool get isOnline => _isOnline;
  bool get isUpdating => _isUpdating;
  String? get lastError => _lastError;
  
  String get statusText => _isOnline ? 'Online' : 'Offline';
  String get statusTextHindi => _isOnline ? 'ऑनलाइन' : 'ऑफलाइन';
  
  Color get statusColor => _isOnline ? Colors.green : Colors.red;
  Color get statusColorLight => _isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
  
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnline = prefs.getBool(_statusKey) ?? false;
      print('StatusService: Initialized with local status: ${_isOnline ? "Online" : "Offline"}');
      _safeNotifyListeners();
      
      // Sync with backend to get the latest status
      await syncStatusFromBackend();
    } catch (e) {
      print('StatusService: Error initializing: $e');
      _isOnline = false; // Default to offline
      _safeNotifyListeners();
    }
  }
  
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      if (_disposed) return;
      if (_isOnline == isOnline) return;
      
      _isUpdating = true;
      _lastError = null;
      _safeNotifyListeners();
      
      // Update local state first for immediate UI response
      _isOnline = isOnline;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_statusKey, _isOnline);
      _safeNotifyListeners();
      
      // Call backend API to update database
      await _updateOnlineStatusInBackend(isOnline);
      
      _isUpdating = false;
      _safeNotifyListeners();
      print('StatusService: Status changed to ${_isOnline ? "Online" : "Offline"}');
    } catch (e) {
      print('StatusService: Error setting status: $e');
      _isUpdating = false;
      _lastError = e.toString();
      
      // Revert local state if backend call fails
      if (!_disposed) {
        _isOnline = !isOnline; // Revert to previous state
        _safeNotifyListeners();
      }
    }
  }
  
  Future<void> toggleStatus() async {
    await setOnlineStatus(!_isOnline);
  }
  
  Future<void> goOnline() async {
    await setOnlineStatus(true);
  }
  
  Future<void> goOffline() async {
    await setOnlineStatus(false);
  }
  
  /// Update online status in backend database
  Future<void> _updateOnlineStatusInBackend(bool isOnline) async {
    try {
      final response = await _apiService.put(
        ApiConstants.updateStatus,
        data: {'isOnline': isOnline},
      );
      
      if (response.statusCode == 200) {
        print('StatusService: Backend updated successfully - ${response.data}');
      } else {
        throw Exception('Failed to update status in backend');
      }
    } catch (e) {
      print('StatusService: Backend update failed: $e');
      throw e; // Re-throw to trigger error handling in setOnlineStatus
    }
  }
  
  /// Sync online status from backend on app startup
  Future<void> syncStatusFromBackend() async {
    try {
      final response = await _apiService.get(ApiConstants.dashboardStats);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final isOnlineFromBackend = response.data['data']['isOnline'] ?? false;
        
        // Only update if different from current state
        if (_isOnline != isOnlineFromBackend) {
          _isOnline = isOnlineFromBackend;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_statusKey, _isOnline);
          _safeNotifyListeners();
          print('StatusService: Synced status from backend: ${_isOnline ? "Online" : "Offline"}');
        }
      }
    } catch (e) {
      print('StatusService: Failed to sync status from backend: $e');
      // Continue with local status if backend sync fails
    }
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e) {
        print('StatusService: Error in notifyListeners: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
