import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
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
  NotificationType? _selectedType;
  
  // Search animation state
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    // Load notifications using BLoC
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
        context.read<NotificationsBloc>().add(const ClearSearchEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      appBar: _buildAppBar(l10n, themeService),
      body: Column(
        children: [
          // Filter Chips
          NotificationFilterChips(
            onTypeChanged: (type) => setState(() => _selectedType = type),
            selectedType: _selectedType,
          ),
          
          // Tab Bar
          Container(
            color: themeService.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: themeService.primaryColor,
              unselectedLabelColor: themeService.textSecondary,
              indicatorColor: themeService.primaryColor,
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

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, ThemeService themeService) {
    return AppBar(
      backgroundColor: themeService.primaryColor,
      elevation: 0,
      titleSpacing: 16,
      title: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Row(
            children: [
              if (!_isSearching)
                Opacity(
                  opacity: 1.0 - _searchAnimation.value,
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              if (_isSearching)
                Expanded(
                  child: FadeTransition(
                    opacity: _searchAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search notifications...',
                              hintStyle: TextStyle(
                                color: Colors.black45,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 6),
                                child: Icon(Icons.search, color: Colors.black45, size: 20),
                              ),
                              prefixIconConstraints: BoxConstraints(minWidth: 36),
                            ),
                            onChanged: (value) {
                              context.read<NotificationsBloc>().add(
                                SearchNotificationsEvent(value),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        // Search Button/Close
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          color: Colors.white,
          tooltip: _isSearching ? 'Close search' : 'Search',
        ),
        // More Options
        if (!_isSearching)
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: themeService.primaryColor),
                    const SizedBox(width: 12),
                    const Text('Mark All as Read'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: themeService.errorColor),
                    const SizedBox(width: 12),
                    const Text('Clear All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: themeService.textPrimary),
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
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        // Loading state
        if (state is NotificationsLoading) {
          return _buildSkeletonList();
        }

        // Error state
        if (state is NotificationsErrorState) {
          return _buildErrorState(state.message);
        }

        // Loaded state
        if (state is NotificationsLoadedState) {
          final filteredNotifications = _getFilteredNotifications(
            state.notifications,
            filter,
            state.searchQuery,
          );

          if (filteredNotifications.isEmpty) {
            return NotificationEmptyState(filter: filter);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationsBloc>().add(const RefreshNotificationsEvent());
              // Wait for refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () => _openNotificationDetail(notification),
                  onMarkAsRead: () => context.read<NotificationsBloc>().add(
                    MarkAsReadEvent(notification.id),
                  ),
                  onArchive: () => context.read<NotificationsBloc>().add(
                    ArchiveNotificationEvent(notification.id),
                  ),
                  onDelete: () => context.read<NotificationsBloc>().add(
                    DeleteNotificationEvent(notification.id),
                  ),
                );
              },
            ),
          );
        }

        // Initial state
        return _buildSkeletonList();
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
    final themeService = Provider.of<ThemeService>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeService.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: themeService.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeService.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<NotificationsBloc>().add(const RefreshNotificationsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        
        // Only show FAB if there are unread notifications
        if (state is! NotificationsLoadedState || state.stats?.unread == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () => context.read<NotificationsBloc>().add(const MarkAllAsReadEvent()),
          backgroundColor: themeService.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.done_all),
        );
      },
    );
  }

  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> notifications,
    NotificationFilter filter,
    String searchQuery,
  ) {
    List<NotificationModel> filtered = notifications;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
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

  void _handleMenuAction(String action) {
    final notificationsBloc = context.read<NotificationsBloc>();
    
    switch (action) {
      case 'mark_all_read':
        notificationsBloc.add(const MarkAllAsReadEvent());
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
              context.read<NotificationsBloc>().add(const DeleteAllNotificationsEvent());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Provider.of<ThemeService>(context, listen: false).errorColor,
            ),
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

