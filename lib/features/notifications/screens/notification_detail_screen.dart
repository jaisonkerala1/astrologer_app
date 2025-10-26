import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/notification_model.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark notification as read when opened
    if (widget.notification.isUnread) {
      context.read<NotificationsBloc>().add(
        MarkAsReadEvent(widget.notification.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(l10n),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Header
            _buildNotificationHeader(),
            const SizedBox(height: 24),
            
            // Notification Content
            _buildNotificationContent(),
            const SizedBox(height: 24),
            
            // Notification Details
            _buildNotificationDetails(),
            const SizedBox(height: 24),
            
            // Action Buttons
            if (widget.notification.isActionable) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        'Notification Details',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: AppTheme.textColor,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (widget.notification.isUnread)
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    const Icon(Icons.done, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text('Mark as Read'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  const Icon(Icons.archive, color: AppTheme.warningColor),
                  const SizedBox(width: 12),
                  const Text('Archive'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppTheme.errorColor),
                  const SizedBox(width: 12),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and Priority
          Row(
            children: [
              _buildTypeChip(),
              const SizedBox(width: 8),
              _buildPriorityChip(),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            widget.notification.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Time and Sender
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textColor.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                widget.notification.timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              if (widget.notification.senderName != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.notification.senderName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    final typeColor = _getTypeColor(widget.notification.type);
    final typeIcon = _getTypeIcon(widget.notification.type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon, size: 16, color: typeColor),
          const SizedBox(width: 4),
          Text(
            _getTypeLabel(widget.notification.type),
            style: TextStyle(
              color: typeColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip() {
    final priorityColor = _getPriorityColor(widget.notification.priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(widget.notification.priority),
            size: 16,
            color: priorityColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getPriorityLabel(widget.notification.priority),
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusColor = widget.notification.isRead ? Colors.green : AppTheme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.notification.isRead ? Icons.done : Icons.circle,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            widget.notification.isRead ? 'Read' : 'Unread',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.notification.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textColor,
              height: 1.5,
            ),
          ),
          if (widget.notification.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.notification.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Created', widget.notification.createdAt.toString()),
          if (widget.notification.readAt != null)
            _buildDetailRow('Read', widget.notification.readAt!.toString()),
          _buildDetailRow('Type', _getTypeLabel(widget.notification.type)),
          _buildDetailRow('Priority', _getPriorityLabel(widget.notification.priority)),
          if (widget.notification.senderId != null)
            _buildDetailRow('Sender ID', widget.notification.senderId!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.notification.actionText != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAction,
                icon: const Icon(Icons.open_in_new),
                label: Text(widget.notification.actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final notificationsBloc = context.read<NotificationsBloc>();
    
    switch (action) {
      case 'mark_read':
        if (widget.notification.isUnread) {
          notificationsBloc.add(MarkAsReadEvent(widget.notification.id));
        }
        break;
      case 'archive':
        notificationsBloc.add(ArchiveNotificationEvent(widget.notification.id));
        Navigator.pop(context);
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
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
              context.read<NotificationsBloc>().add(DeleteNotificationEvent(widget.notification.id));
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleAction() {
    if (widget.notification.actionUrl != null) {
      // Handle action URL - could be deep link or external URL
      // Implementation depends on your app's navigation structure
    }
  }

  // Helper methods for styling
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
        return 'Consultation Request';
      case NotificationType.consultationAccepted:
        return 'Consultation Accepted';
      case NotificationType.consultationCancelled:
        return 'Consultation Cancelled';
      case NotificationType.consultationCompleted:
        return 'Consultation Completed';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.reviewReceived:
        return 'Review Received';
      case NotificationType.messageReceived:
        return 'Message Received';
      case NotificationType.callMissed:
        return 'Missed Call';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.emergency:
        return 'Emergency';
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case NotificationPriority.normal:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}
