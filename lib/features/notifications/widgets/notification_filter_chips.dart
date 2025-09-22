import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/notification_model.dart';

class NotificationFilterChips extends StatelessWidget {
  final Function(NotificationType?) onTypeChanged;
  final NotificationType? selectedType;

  const NotificationFilterChips({
    super.key,
    required this.onTypeChanged,
    this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Filter Chips
          Text(
            'Type',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(context, null, 'All'),
                const SizedBox(width: 8),
                ...NotificationType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTypeChip(context, type, _getTypeLabel(type)),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, NotificationType? type, String label) {
    final isSelected = selectedType == type;
    final color = type != null ? _getTypeColor(type) : AppTheme.primaryColor;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onTypeChanged(selected ? type : null);
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppTheme.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: 1,
        ),
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
