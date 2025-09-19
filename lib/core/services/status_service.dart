import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusService extends ChangeNotifier {
  static const String _statusKey = 'user_online_status';
  
  bool _isOnline = false;
  
  bool get isOnline => _isOnline;
  
  String get statusText => _isOnline ? 'Online' : 'Offline';
  String get statusTextHindi => _isOnline ? 'ऑनलाइन' : 'ऑफलाइन';
  
  Color get statusColor => _isOnline ? Colors.green : Colors.red;
  Color get statusColorLight => _isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
  
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnline = prefs.getBool(_statusKey) ?? false;
      print('StatusService: Initialized with status: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    } catch (e) {
      print('StatusService: Error initializing: $e');
      _isOnline = false; // Default to offline
      notifyListeners();
    }
  }
  
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      if (_isOnline == isOnline) return;
      
      _isOnline = isOnline;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_statusKey, _isOnline);
      print('StatusService: Status changed to ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    } catch (e) {
      print('StatusService: Error setting status: $e');
      // Still update the local state even if persistence fails
      _isOnline = isOnline;
      notifyListeners();
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
}
