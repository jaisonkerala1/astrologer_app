import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/notification_filter.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_empty_state.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  NotificationType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          // Filter Chips
          NotificationFilterChips(
            onTypeChanged: (type) => setState(() => _selectedType = type),
            selectedType: _selectedType,
          ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textColor.withOpacity(0.6),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Today'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(NotificationFilter.all),
                _buildNotificationsList(NotificationFilter.unread),
                _buildNotificationsList(NotificationFilter.today),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: AppTheme.textColor,
      actions: [
        // Search Button
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: 'Search',
        ),
        // More Options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  const Icon(Icons.done_all, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  const Text('Mark All as Read'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  const Icon(Icons.clear_all, color: AppTheme.errorColor),
                  const SizedBox(width: 12),
                  const Text('Clear All'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings, color: AppTheme.textColor),
                  const SizedBox(width: 12),
                  const Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsList(NotificationFilter filter) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        if (notificationService.isLoading && notificationService.notifications.isEmpty) {
          return _buildSkeletonList();
        }

        if (notificationService.error != null) {
          return _buildErrorState(notificationService.error!);
        }

        final filteredNotifications = _getFilteredNotifications(
          notificationService.notifications,
          filter,
        );

        if (filteredNotifications.isEmpty) {
          return NotificationEmptyState(filter: filter);
        }

        return RefreshIndicator(
          onRefresh: () => notificationService.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _openNotificationDetail(notification),
                onMarkAsRead: () => notificationService.markAsRead(notification.id),
                onArchive: () => notificationService.archiveNotification(notification.id),
                onDelete: () => notificationService.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<NotificationService>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        if (notificationService.unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () => notificationService.markAllAsRead(),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.done_all),
        );
      },
    );
  }

  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> notifications,
    NotificationFilter filter,
  ) {
    List<NotificationModel> filtered = notifications;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) =>
        n.title.toLowerCase().contains(query) ||
        n.body.toLowerCase().contains(query)
      ).toList();
    }

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered.where((n) => n.type == _selectedType).toList();
    }



    // Apply tab filter
    switch (filter) {
      case NotificationFilter.all:
        break;
      case NotificationFilter.unread:
        filtered = filtered.where((n) => n.isUnread).toList();
        break;
      case NotificationFilter.today:
        final today = DateTime.now();
        filtered = filtered.where((n) => 
          n.createdAt.year == today.year &&
          n.createdAt.month == today.month &&
          n.createdAt.day == today.day
        ).toList();
        break;
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notifications'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search in notifications...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final notificationService = context.read<NotificationService>();
    
    switch (action) {
      case 'mark_all_read':
        notificationService.markAllAsRead();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        // Navigate to notification settings
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationService>().clearAllNotifications();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _openNotificationDetail(NotificationModel notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }
}

