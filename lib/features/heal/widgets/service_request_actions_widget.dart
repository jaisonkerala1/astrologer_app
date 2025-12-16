import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_request_model.dart';
import '../bloc/heal_bloc.dart';
import '../bloc/heal_event.dart';
import 'complete_service_bottom_sheet.dart';

class ServiceRequestActionsWidget extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestActionsWidget({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final primary = _primaryAction(context, themeService);
        final secondary = _secondaryActions(context, themeService);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeService.borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (primary != null) ...[
                SizedBox(width: double.infinity, child: primary),
              ],
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: secondary),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget? _primaryAction(BuildContext context, ThemeService themeService) {
    switch (request.status) {
      case RequestStatus.pending:
        return _primaryButton(
          context: context,
          themeService: themeService,
          label: 'Accept',
          icon: Icons.check_rounded,
          onPressed: () => _acceptRequest(context),
        );
      case RequestStatus.confirmed:
        return _primaryButton(
          context: context,
          themeService: themeService,
          label: 'Start',
          icon: Icons.play_arrow_rounded,
          onPressed: () => _startService(context),
        );
      case RequestStatus.inProgress:
        return _primaryButton(
          context: context,
          themeService: themeService,
          label: 'Complete',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () => _completeService(context),
        );
      case RequestStatus.completed:
        // No primary action for completed (keep it minimal)
        return null;
      case RequestStatus.cancelled:
        return _primaryButton(
          context: context,
          themeService: themeService,
          label: 'Reschedule',
          icon: Icons.replay_rounded,
          onPressed: () => _rescheduleService(context),
        );
    }
  }

  List<Widget> _secondaryActions(BuildContext context, ThemeService themeService) {
    final buttons = <Widget>[];

    Widget outlined({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: themeService.textSecondary,
          side: BorderSide(color: themeService.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 18, color: themeService.textSecondary),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    Widget destructive({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          // Keep destructive actions visually minimal too (no red/green/blue)
          foregroundColor: themeService.textSecondary,
          side: BorderSide(color: themeService.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 18, color: themeService.textSecondary),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    switch (request.status) {
      case RequestStatus.pending:
        buttons.add(outlined(
          label: 'Call',
          icon: Icons.phone_rounded,
          onPressed: () => _callCustomer(context),
        ));
        buttons.add(destructive(
          label: 'Reject',
          icon: Icons.close_rounded,
          onPressed: () => _confirmReject(context, themeService),
        ));
        break;
      case RequestStatus.confirmed:
        buttons.add(outlined(
          label: 'Call',
          icon: Icons.phone_rounded,
          onPressed: () => _callCustomer(context),
        ));
        buttons.add(outlined(
          label: 'Reschedule',
          icon: Icons.schedule_rounded,
          onPressed: () => _rescheduleService(context),
        ));
        buttons.add(destructive(
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          onPressed: () => _confirmCancel(context, themeService),
        ));
        break;
      case RequestStatus.inProgress:
        buttons.add(outlined(
          label: 'Pause',
          icon: Icons.pause_rounded,
          onPressed: () => _pauseService(context),
        ));
        buttons.add(outlined(
          label: 'Call',
          icon: Icons.phone_rounded,
          onPressed: () => _callCustomer(context),
        ));
        break;
      case RequestStatus.completed:
        buttons.add(outlined(
          label: 'Share',
          icon: Icons.share_rounded,
          onPressed: () => _shareService(context),
        ));
        buttons.add(outlined(
          label: 'Rate',
          icon: Icons.star_outline_rounded,
          onPressed: () => _rateService(context),
        ));
        break;
      case RequestStatus.cancelled:
        buttons.add(outlined(
          label: 'Call',
          icon: Icons.phone_rounded,
          onPressed: () => _callCustomer(context),
        ));
        break;
    }

    return buttons;
  }

  Widget _primaryButton({
    required BuildContext context,
    required ThemeService themeService,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    // Get dynamic color based on status (matching card widget behavior)
    final statusColor = _getStatusColor();
    
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: statusColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
  
  /// Get status-based color (matching card widget behavior)
  Color _getStatusColor() {
    return Color(int.parse(request.statusColor.replaceFirst('#', '0xFF')));
  }

  void _acceptRequest(BuildContext context) {
    // Dispatch event to update request status to confirmed
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.confirmed));
    // Stay on detail page - BlocListener will update the UI with new actions
  }

  void _startService(BuildContext context) {
    // Dispatch event to update request status to inProgress
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.inProgress));
    // Stay on detail page - BlocListener will update the UI with timer and complete option
  }

  void _completeService(BuildContext context) async {
    final result = await CompleteServiceBottomSheet.show(
      context: context,
      customerName: request.customerName,
      serviceName: request.serviceName,
      amount: request.price,
    );
    
    if (result != null && context.mounted) {
      // Dispatch event to update request status to completed
      context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.completed));
      
      // Pop back to list after completing - this is a terminal action
      Navigator.pop(context, true);
    }
  }

  void _pauseService(BuildContext context) {
    // Pause = back to confirmed state
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.confirmed));
    // Stay on detail page - BlocListener will update the UI
  }

  void _callCustomer(BuildContext context) {
    // TODO: Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call functionality coming soon'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _rescheduleService(BuildContext context) {
    // TODO: Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule functionality coming soon'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  void _rateService(BuildContext context) {
    // TODO: Implement rate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating functionality coming soon'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  void _shareService(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  void _confirmReject(BuildContext context, ThemeService themeService) {
    final parentContext = context; // Save parent context for BLoC access
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeService.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reject Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to reject the service request from ${request.customerName}?',
          style: TextStyle(
            fontSize: 14,
            color: themeService.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: themeService.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(dialogContext);
              
              // Dispatch event to update request status to cancelled
              parentContext.read<HealBloc>().add(
                UpdateRequestStatusEvent(request.id, RequestStatus.cancelled),
              );
              
              // Pop back to list after action
              Navigator.pop(parentContext, true);
            },
            child: Text(
              'Reject',
              style: TextStyle(
                color: themeService.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, ThemeService themeService) {
    final parentContext = context; // Save parent context for BLoC access
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeService.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancel Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel the service for ${request.customerName}?',
          style: TextStyle(
            fontSize: 14,
            color: themeService.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'No',
              style: TextStyle(
                color: themeService.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(dialogContext);
              
              // Dispatch event to update request status to cancelled
              parentContext.read<HealBloc>().add(
                UpdateRequestStatusEvent(request.id, RequestStatus.cancelled),
              );
              
              // Pop back to list after action
              Navigator.pop(parentContext, true);
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(
                color: themeService.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
