import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  List<NotificationModel> _notifications = [];
  NotificationStats _stats = const NotificationStats(
    total: 0,
    unread: 0,
    read: 0,
    archived: 0,
    urgent: 0,
    today: 0,
  );
  
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  StreamSubscription? _notificationStream;

  // Getters
  List<NotificationModel> get notifications => List.from(_notifications);
  NotificationStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _stats.unread;
  bool get hasUnreadNotifications => _stats.unread > 0;

  // Filtered notifications
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => n.isUnread).toList();
  
  List<NotificationModel> get urgentNotifications => 
      _notifications.where((n) => n.priority == NotificationPriority.urgent).toList();
  
  List<NotificationModel> get todayNotifications => 
      _notifications.where((n) => n.age.inDays == 0).toList();

  // Initialize the service
  Future<void> initialize() async {
    await _loadCachedNotifications();
    await _loadNotifications();
    _startPeriodicRefresh();
  }

  // Load notifications from API
  Future<void> _loadNotifications() async {
    try {
      _setLoading(true);
      _setError(null);

      // For now, use mock data since API endpoints don't exist
      await _loadMockNotifications();
      
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error loading notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load mock notifications for testing
  Future<void> _loadMockNotifications() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Consultation Request',
        body: 'You have received a new consultation request from John Doe',
        type: NotificationType.consultationRequest,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isActionable: true,
        actionText: 'View Request',
        senderName: 'John Doe',
      ),
      NotificationModel(
        id: '2',
        title: 'Payment Received',
        body: 'Payment of ₹500 has been received for consultation #123',
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 1)),
        isActionable: true,
        actionText: 'View Payment',
      ),
      NotificationModel(
        id: '3',
        title: 'New Review Received',
        body: 'You received a 5-star review from Sarah Wilson',
        type: NotificationType.reviewReceived,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
        isActionable: true,
        actionText: 'View Review',
        senderName: 'Sarah Wilson',
      ),
      NotificationModel(
        id: '4',
        title: 'System Update',
        body: 'App has been updated to version 2.1.0 with new features',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
        isActionable: false,
      ),
      NotificationModel(
        id: '5',
        title: 'Urgent: Missed Call',
        body: 'You missed an important call from client. Please call back.',
        type: NotificationType.callMissed,
        priority: NotificationPriority.urgent,
        createdAt: now.subtract(const Duration(minutes: 30)),
        isActionable: true,
        actionText: 'Call Back',
        senderName: 'Client',
      ),
    ];
    
    _updateStats();
    await _cacheNotifications();
    notifyListeners();
  }

  // Load cached notifications
  Future<void> _loadCachedNotifications() async {
    try {
      final cachedData = await _storageService.getString('cached_notifications');
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        _notifications = (data['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _stats = NotificationStats.fromJson(data['stats']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached notifications: $e');
    }
  }

  // Cache notifications
  Future<void> _cacheNotifications() async {
    try {
      final data = {
        'notifications': _notifications.map((n) => n.toJson()).toList(),
        'stats': _stats.toJson(),
      };
      await _storageService.setString('cached_notifications', jsonEncode(data));
    } catch (e) {
      debugPrint('Error caching notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          status: NotificationStatus.read,
          readAt: DateTime.now(),
        );
        _updateStats();
        await _cacheNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _notifications = _notifications.map((n) => n.copyWith(
        status: NotificationStatus.read,
        readAt: DateTime.now(),
      )).toList();
      _updateStats();
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          status: NotificationStatus.archived,
        );
        _updateStats();
        await _cacheNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error archiving notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateStats();
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      _stats = const NotificationStats(
        total: 0,
        unread: 0,
        read: 0,
        archived: 0,
        urgent: 0,
        today: 0,
      );
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // Refresh notifications
  Future<void> refresh() async {
    await _loadNotifications();
  }

  // Update stats
  void _updateStats() {
    final now = DateTime.now();
    final today = now.subtract(Duration(hours: now.hour, minutes: now.minute, seconds: now.second));
    
    _stats = NotificationStats(
      total: _notifications.length,
      unread: _notifications.where((n) => n.isUnread).length,
      read: _notifications.where((n) => n.isRead).length,
      archived: _notifications.where((n) => n.isArchived).length,
      urgent: _notifications.where((n) => n.priority == NotificationPriority.urgent).length,
      today: _notifications.where((n) => n.createdAt.isAfter(today)).length,
    );
  }

  // Start periodic refresh
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadNotifications();
    });
  }

  // Stop periodic refresh
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Create a test notification (for development)
  void addTestNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.systemUpdate,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      priority: priority,
      createdAt: DateTime.now(),
    );
    
    _notifications.insert(0, notification);
    _updateStats();
    notifyListeners();
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get notifications by priority
  List<NotificationModel> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;
    
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((n) =>
      n.title.toLowerCase().contains(lowercaseQuery) ||
      n.body.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    _notificationStream?.cancel();
    super.dispose();
  }
}
