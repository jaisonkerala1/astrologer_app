import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/notification_filter.dart';

class NotificationEmptyState extends StatelessWidget {
  final NotificationFilter filter;

  const NotificationEmptyState({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEmptyStateIcon(),
                    size: 48,
                    color: AppTheme.primaryColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _getEmptyStateTitle(l10n),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  _getEmptyStateDescription(l10n),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Action Button
                ElevatedButton.icon(
                  onPressed: () => _handleAction(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(_getActionText(l10n)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (filter) {
      case NotificationFilter.all:
        return Icons.notifications_none;
      case NotificationFilter.unread:
        return Icons.mark_email_unread;
      case NotificationFilter.today:
        return Icons.today;
    }
  }

  String _getEmptyStateTitle(AppLocalizations l10n) {
    switch (filter) {
      case NotificationFilter.all:
        return 'No notifications yet';
      case NotificationFilter.unread:
        return 'All caught up!';
      case NotificationFilter.today:
        return 'No notifications today';
    }
  }

  String _getEmptyStateDescription(AppLocalizations l10n) {
    switch (filter) {
      case NotificationFilter.all:
        return 'You don\'t have any notifications yet. When you receive notifications, they\'ll appear here.';
      case NotificationFilter.unread:
        return 'You\'ve read all your notifications. Great job staying on top of things!';
      case NotificationFilter.today:
        return 'No notifications received today. Check back later for updates.';
    }
  }

  String _getActionText(AppLocalizations l10n) {
    switch (filter) {
      case NotificationFilter.all:
        return 'Refresh';
      case NotificationFilter.unread:
        return 'View All';
      case NotificationFilter.today:
        return 'Refresh';
    }
  }

  void _handleAction(BuildContext context) {
    switch (filter) {
      case NotificationFilter.all:
      case NotificationFilter.today:
        // Refresh notifications
        // This would typically call a refresh method
        break;
      case NotificationFilter.unread:
        // Switch to all notifications tab
        // This would typically switch tabs
        break;
    }
  }
}
