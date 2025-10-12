import 'package:flutter/foundation.dart';
import '../models/communication_item.dart';

/// Service to manage communication state including unread counts for calls and messages
class CommunicationService extends ChangeNotifier {
  // Unread counts
  int _unreadMessagesCount = 0;
  int _missedCallsCount = 0;
  int _missedVideoCallsCount = 0;

  // Mock data for calls and messages (legacy - kept for compatibility)
  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _messages = [];

  // Unified communication list
  List<CommunicationItem> _allCommunications = [];
  
  // Current filter
  CommunicationFilter _activeFilter = CommunicationFilter.all;

  // Tab switching support (legacy)
  String? _requestedTab;
  
  // Getters
  int get unreadMessagesCount => _unreadMessagesCount;
  int get missedCallsCount => _missedCallsCount;
  int get missedVideoCallsCount => _missedVideoCallsCount;
  int get totalUnreadCount => _unreadMessagesCount + _missedCallsCount + _missedVideoCallsCount;
  List<Map<String, dynamic>> get calls => _calls;
  List<Map<String, dynamic>> get messages => _messages;
  String? get requestedTab => _requestedTab;
  CommunicationFilter get activeFilter => _activeFilter;
  
  /// Get unified list of all communications
  List<CommunicationItem> get allCommunications => _allCommunications;
  
  /// Get filtered communications based on active filter
  List<CommunicationItem> get filteredCommunications {
    switch (_activeFilter) {
      case CommunicationFilter.all:
        return _allCommunications;
      case CommunicationFilter.calls:
        return _allCommunications
            .where((item) => item.type == CommunicationType.voiceCall)
            .toList();
      case CommunicationFilter.messages:
        return _allCommunications
            .where((item) => item.type == CommunicationType.message)
            .toList();
      case CommunicationFilter.video:
        return _allCommunications
            .where((item) => item.type == CommunicationType.videoCall)
            .toList();
    }
  }
  
  /// Get count for specific filter
  int getCountForFilter(CommunicationFilter filter) {
    switch (filter) {
      case CommunicationFilter.all:
        return _allCommunications.length;
      case CommunicationFilter.calls:
        return _allCommunications
            .where((item) => item.type == CommunicationType.voiceCall)
            .length;
      case CommunicationFilter.messages:
        return _allCommunications
            .where((item) => item.type == CommunicationType.message)
            .length;
      case CommunicationFilter.video:
        return _allCommunications
            .where((item) => item.type == CommunicationType.videoCall)
            .length;
    }
  }
  
  /// Set active filter
  void setFilter(CommunicationFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

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
        'duration': '5:23',
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
        'duration': '12:45',
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
      {
        'name': 'Michael Chen',
        'preview': 'Can we schedule another session?',
        'time': '5h',
        'unread': 0,
        'avatar': 'MC',
        'isOnline': true,
      },
    ];

    // Build unified communications list
    _buildUnifiedList();
    _updateUnreadCounts();
  }
  
  /// Build unified list from calls and messages
  void _buildUnifiedList() {
    _allCommunications = [];
    
    // Add messages
    for (var message in _messages) {
      _allCommunications.add(CommunicationItem.fromMessage(message));
    }
    
    // Add calls
    for (var call in _calls) {
      _allCommunications.add(CommunicationItem.fromCall(call));
    }
    
    // Add some mock video calls
    _allCommunications.add(
      CommunicationItem(
        id: 'video_1',
        type: CommunicationType.videoCall,
        contactName: 'Priya Sharma',
        avatar: 'PS',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        preview: 'Video consultation',
        status: CommunicationStatus.incoming,
        duration: '25:15',
        chargedAmount: 750.0,
      ),
    );
    
    // Sort by timestamp (newest first)
    _allCommunications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Update unread counts based on current data
  void _updateUnreadCounts() {
    // Count unread messages
    _unreadMessagesCount = _allCommunications
        .where((item) => item.type == CommunicationType.message && item.unreadCount > 0)
        .fold<int>(0, (sum, item) => sum + item.unreadCount);

    // Count missed calls
    _missedCallsCount = _allCommunications
        .where((item) => 
            item.type == CommunicationType.voiceCall && 
            item.status == CommunicationStatus.missed)
        .length;
    
    // Count missed video calls
    _missedVideoCallsCount = _allCommunications
        .where((item) => 
            item.type == CommunicationType.videoCall && 
            item.status == CommunicationStatus.missed)
        .length;

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

    // Rebuild unified list
    _buildUnifiedList();
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

    // Rebuild unified list
    _buildUnifiedList();
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

