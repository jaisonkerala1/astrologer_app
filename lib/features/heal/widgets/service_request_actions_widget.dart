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
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeService.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Action buttons based on status
              if (request.status == RequestStatus.pending) ...[
                _buildActionButton(
                  context: context,
                  icon: Icons.check_circle,
                  label: 'Accept Request',
                  description: 'Confirm and schedule',
                  color: const Color(0xFF10B981),
                  onTap: () => _acceptRequest(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.phone,
                  label: 'Call Customer',
                  description: 'Make a voice call',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _callCustomer(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.cancel_outlined,
                  label: 'Reject',
                  description: 'Decline this request',
                  color: const Color(0xFFEF4444),
                  onTap: () => _confirmReject(context, themeService),
                  themeService: themeService,
                ),
              ] else if (request.status == RequestStatus.confirmed) ...[
                _buildActionButton(
                  context: context,
                  icon: Icons.play_arrow,
                  label: 'Start Service',
                  description: 'Begin the session',
                  color: const Color(0xFF10B981),
                  onTap: () => _startService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.phone,
                  label: 'Call Customer',
                  description: 'Make a voice call',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _callCustomer(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.schedule,
                  label: 'Reschedule',
                  description: 'Change the service time',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _rescheduleService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.cancel_outlined,
                  label: 'Cancel',
                  description: 'Cancel this service',
                  color: const Color(0xFFEF4444),
                  onTap: () => _confirmCancel(context, themeService),
                  themeService: themeService,
                ),
              ] else if (request.status == RequestStatus.inProgress) ...[
                _buildActionButton(
                  context: context,
                  icon: Icons.stop,
                  label: 'Complete Service',
                  description: 'Mark as completed',
                  color: const Color(0xFF10B981),
                  onTap: () => _completeService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.pause,
                  label: 'Pause Service',
                  description: 'Temporarily pause',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _pauseService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.phone,
                  label: 'Call Customer',
                  description: 'Make a voice call',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _callCustomer(context),
                  themeService: themeService,
                ),
              ] else if (request.status == RequestStatus.completed) ...[
                _buildActionButton(
                  context: context,
                  icon: Icons.star_outline,
                  label: 'Rate Service',
                  description: 'Rate this service',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _rateService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.share,
                  label: 'Share Details',
                  description: 'Share service info',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _shareService(context),
                  themeService: themeService,
                ),
              ] else if (request.status == RequestStatus.cancelled) ...[
                _buildActionButton(
                  context: context,
                  icon: Icons.replay,
                  label: 'Reschedule',
                  description: 'Schedule a new service',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _rescheduleService(context),
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  icon: Icons.phone,
                  label: 'Call Customer',
                  description: 'Make a voice call',
                  color: const Color(0xFF10B981),
                  onTap: () => _callCustomer(context),
                  themeService: themeService,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(BuildContext context) {
    // Dispatch event to update request status to confirmed
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.confirmed));
    
    // Pop back to list after action
    Navigator.pop(context, true);
  }

  void _startService(BuildContext context) {
    // Dispatch event to update request status to inProgress
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.inProgress));
    
    // Pop back to list after action
    Navigator.pop(context, true);
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
      
      // Pop back to list after action
      Navigator.pop(context, true);
    }
  }

  void _pauseService(BuildContext context) {
    // Pause = back to confirmed state
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, RequestStatus.confirmed));
    
    // Pop back to list after action
    Navigator.pop(context, true);
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
