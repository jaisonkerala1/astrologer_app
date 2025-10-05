import 'package:flutter/foundation.dart';

/// Service to manage communication state including unread counts for calls and messages
class CommunicationService extends ChangeNotifier {
  // Unread counts
  int _unreadMessagesCount = 0;
  int _missedCallsCount = 0;

  // Mock data for calls and messages
  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _messages = [];

  // Tab switching support
  String? _requestedTab;
  
  // Getters
  int get unreadMessagesCount => _unreadMessagesCount;
  int get missedCallsCount => _missedCallsCount;
  int get totalUnreadCount => _unreadMessagesCount + _missedCallsCount;
  List<Map<String, dynamic>> get calls => _calls;
  List<Map<String, dynamic>> get messages => _messages;
  String? get requestedTab => _requestedTab;

  // Initialize with mock data
  CommunicationService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _calls = [
      {
        'name': 'Sarah Miller',
        'type': 'Incoming',
        'time': '2m ago',
        'status': 'answered',
        'avatar': 'SM',
      },
      {
        'name': 'Raj Kumar',
        'type': 'Missed',
        'time': '1h ago',
        'status': 'missed',
        'avatar': 'RK',
      },
      {
        'name': 'Anita Nair',
        'type': 'Outgoing',
        'time': '3h ago',
        'status': 'outgoing',
        'avatar': 'AN',
      },
    ];

    _messages = [
      {
        'name': 'Sarah Miller',
        'preview': 'Thank you for the reading! When is the best time to...',
        'time': '2m',
        'unread': 2,
        'avatar': 'SM',
        'isOnline': true,
      },
      {
        'name': 'Raj Kumar',
        'preview': 'I need guidance about my career transition...',
        'time': '1h',
        'unread': 1,
        'avatar': 'RK',
        'isOnline': false,
      },
      {
        'name': 'Anita Nair',
        'preview': 'The consultation was amazing! ⭐',
        'time': '3h',
        'unread': 0,
        'avatar': 'AN',
        'isOnline': false,
      },
    ];

    _updateUnreadCounts();
  }

  /// Update unread counts based on current data
  void _updateUnreadCounts() {
    // Count unread messages
    _unreadMessagesCount = _messages.fold<int>(
      0,
      (sum, message) => sum + (message['unread'] as int? ?? 0),
    );

    // Count missed calls
    _missedCallsCount = _calls.where((call) => call['status'] == 'missed').length;

    notifyListeners();
  }

  /// Mark messages as read
  void markMessagesAsRead() {
    for (var message in _messages) {
      message['unread'] = 0;
    }
    _updateUnreadCounts();
  }

  /// Mark specific message as read
  void markMessageAsRead(String name) {
    final message = _messages.firstWhere(
      (msg) => msg['name'] == name,
      orElse: () => {},
    );
    if (message.isNotEmpty) {
      message['unread'] = 0;
      _updateUnreadCounts();
    }
  }

  /// Clear missed calls badge
  void clearMissedCalls() {
    // Update missed calls status to 'viewed'
    for (var call in _calls) {
      if (call['status'] == 'missed') {
        call['status'] = 'missed_viewed';
      }
    }
    _updateUnreadCounts();
  }

  /// Add new message (for demonstration/testing)
  void addNewMessage({
    required String name,
    required String preview,
    required String avatar,
    bool isOnline = false,
  }) {
    // Check if conversation already exists
    final existingIndex = _messages.indexWhere((msg) => msg['name'] == name);
    
    if (existingIndex != -1) {
      // Update existing conversation
      final existingUnread = _messages[existingIndex]['unread'] as int? ?? 0;
      _messages[existingIndex] = {
        'name': name,
        'preview': preview,
        'time': 'now',
        'unread': existingUnread + 1,
        'avatar': avatar,
        'isOnline': isOnline,
      };
      // Move to top
      final updatedMessage = _messages.removeAt(existingIndex);
      _messages.insert(0, updatedMessage);
    } else {
      // Add new conversation
      _messages.insert(0, {
        'name': name,
        'preview': preview,
        'time': 'now',
        'unread': 1,
        'avatar': avatar,
        'isOnline': isOnline,
      });
    }

    _updateUnreadCounts();
  }

  /// Add new call (for demonstration/testing)
  void addNewCall({
    required String name,
    required String type,
    required String status,
    required String avatar,
  }) {
    _calls.insert(0, {
      'name': name,
      'type': type,
      'time': 'now',
      'status': status,
      'avatar': avatar,
    });

    _updateUnreadCounts();
  }

  /// Simulate receiving a new message (for testing)
  void simulateNewMessage() {
    addNewMessage(
      name: 'Test User',
      preview: 'This is a test message notification',
      avatar: 'TU',
      isOnline: true,
    );
  }

  /// Simulate receiving a missed call (for testing)
  void simulateMissedCall() {
    addNewCall(
      name: 'Test Caller',
      type: 'Missed',
      status: 'missed',
      avatar: 'TC',
    );
  }

  /// Reset all unread counts (for testing)
  void resetUnreadCounts() {
    markMessagesAsRead();
    clearMissedCalls();
  }

  /// Request to switch to a specific tab (calls or messages)
  /// This is used when navigating from Dashboard
  void requestTabSwitch(String tab) {
    _requestedTab = tab;
    notifyListeners();
  }

  /// Clear the tab switch request after it's been handled
  void clearTabRequest() {
    _requestedTab = null;
  }
}

