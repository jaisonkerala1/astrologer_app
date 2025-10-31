import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to monitor network connectivity status
/// Provides real-time updates on online/offline state
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _hasConnection = true;
  DateTime? _lastChecked;
  
  bool get isOnline => _isOnline;
  bool get hasConnection => _hasConnection;
  bool get isOffline => !_isOnline;
  DateTime? get lastChecked => _lastChecked;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    print('🌐 [ConnectivityService] Initializing...');
    
    // Check initial connectivity
    await checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        print('🌐 [ConnectivityService] Connectivity changed: $result');
        await checkConnectivity();
      },
    );
    
    print('✅ [ConnectivityService] Initialization complete');
  }

  /// Check current connectivity status
  Future<void> checkConnectivity() async {
    try {
      _lastChecked = DateTime.now();
      
      // Check device connectivity (WiFi/Mobile data)
      final result = await _connectivity.checkConnectivity();
      final hasNetworkConnection = result != ConnectivityResult.none;
      
      if (!hasNetworkConnection) {
        // No network connection at all
        _hasConnection = false;
        _isOnline = false;
        print('❌ [ConnectivityService] No network connection');
        notifyListeners();
        return;
      }
      
      // Has network connection, now verify internet access
      _hasConnection = true;
      _isOnline = await _hasInternetAccess();
      
      print('🌐 [ConnectivityService] Status: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    } catch (e) {
      print('❌ [ConnectivityService] Error checking connectivity: $e');
      _hasConnection = false;
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Verify actual internet access by pinging a reliable server
  Future<bool> _hasInternetAccess() async {
    try {
      // Try to reach Google's DNS (fast and reliable)
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ [ConnectivityService] Internet access check failed: $e');
      return false;
    }
  }

  /// Force refresh connectivity status
  Future<void> refresh() async {
    print('🔄 [ConnectivityService] Manual refresh requested');
    await checkConnectivity();
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

