import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: notification.isUnread
            ? Border.all(color: themeService.primaryColor.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: themeService.textPrimary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Icon
                  _buildNotificationIcon(),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            child:                             Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: notification.isUnread 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: notification.isRead 
                                    ? themeService.textSecondary
                                    : themeService.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityIndicator(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Body
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: notification.isRead 
                              ? themeService.textHint
                              : themeService.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Footer
                      Row(
                        children: [
                          // Time
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Type
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notification.isRead 
                                  ? Colors.grey.withOpacity(0.1)
                                  : _getTypeColor(notification.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(notification.type),
                              style: TextStyle(
                                color: notification.isRead 
                                    ? Colors.black
                                    : _getTypeColor(notification.type),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Unread indicator
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, value),
                  itemBuilder: (context) => [
                    if (notification.isUnread)
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.done, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text('Mark as Read'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(Icons.archive, size: 16, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          const Text('Archive'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final iconColor = notification.isRead 
        ? Colors.black 
        : _getTypeColor(notification.type);
    final backgroundColor = notification.isRead 
        ? Colors.grey.withOpacity(0.1) 
        : _getTypeColor(notification.type).withOpacity(0.1);
    final borderColor = notification.isRead 
        ? Colors.grey.withOpacity(0.3) 
        : _getTypeColor(notification.type).withOpacity(0.3);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Icon(
        _getTypeIcon(notification.type),
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    if (notification.priority == NotificationPriority.urgent) {
      final backgroundColor = notification.isRead ? Colors.grey : Colors.red;
      final textColor = notification.isRead ? Colors.black : Colors.white;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'URGENT',
          style: TextStyle(
            color: textColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (notification.priority == NotificationPriority.high) {
      final backgroundColor = notification.isRead ? Colors.grey : Colors.orange;
      final textColor = notification.isRead ? Colors.black : Colors.white;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'HIGH',
          style: TextStyle(
            color: textColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'mark_read':
        onMarkAsRead?.call();
        break;
      case 'archive':
        onArchive?.call();
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return AppTheme.primaryColor;
      case NotificationType.consultationAccepted:
        return Colors.green;
      case NotificationType.consultationCancelled:
        return Colors.red;
      case NotificationType.consultationCompleted:
        return Colors.blue;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.reviewReceived:
        return Colors.orange;
      case NotificationType.messageReceived:
        return AppTheme.primaryColor;
      case NotificationType.callMissed:
        return Colors.red;
      case NotificationType.systemUpdate:
        return Colors.grey;
      case NotificationType.promotional:
        return Colors.purple;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.emergency:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return Icons.event_available;
      case NotificationType.consultationAccepted:
        return Icons.check_circle;
      case NotificationType.consultationCancelled:
        return Icons.cancel;
      case NotificationType.consultationCompleted:
        return Icons.done_all;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.messageReceived:
        return Icons.message;
      case NotificationType.callMissed:
        return Icons.phone_missed;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.promotional:
        return Icons.campaign;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.emergency:
        return Icons.warning;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return 'Consultation';
      case NotificationType.consultationAccepted:
        return 'Accepted';
      case NotificationType.consultationCancelled:
        return 'Cancelled';
      case NotificationType.consultationCompleted:
        return 'Completed';
      case NotificationType.paymentReceived:
        return 'Payment';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.reviewReceived:
        return 'Review';
      case NotificationType.messageReceived:
        return 'Message';
      case NotificationType.callMissed:
        return 'Missed Call';
      case NotificationType.systemUpdate:
        return 'System';
      case NotificationType.promotional:
        return 'Promo';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.emergency:
        return 'Emergency';
    }
  }
}
