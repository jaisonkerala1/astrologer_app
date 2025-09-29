import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';

class ServiceRequestActionsWidget extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestActionsWidget({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (request.status) {
      case RequestStatus.pending:
        return Column(
          children: [
            _buildActionButton(
              context,
              label: 'Accept Request',
              icon: Icons.check_circle_outline,
              color: AppTheme.successColor,
              onPressed: () => _acceptRequest(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'Reject Request',
              icon: Icons.cancel_outlined,
              color: AppTheme.errorColor,
              onPressed: () => _confirmReject(context),
            ),
          ],
        );
      case RequestStatus.confirmed:
        return Column(
          children: [
            _buildActionButton(
              context,
              label: 'Start Service',
              icon: Icons.play_arrow,
              color: AppTheme.primaryColor,
              onPressed: () => _startService(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'Cancel Service',
              icon: Icons.cancel_outlined,
              color: AppTheme.errorColor,
              onPressed: () => _confirmCancel(context),
            ),
          ],
        );
      case RequestStatus.inProgress:
        return Column(
          children: [
            _buildActionButton(
              context,
              label: 'Mark as Complete',
              icon: Icons.check_circle_outline,
              color: AppTheme.successColor,
              onPressed: () => _completeService(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'End Service',
              icon: Icons.stop_circle_outlined,
              color: AppTheme.errorColor,
              onPressed: () => _confirmCancel(context), // Can be used to end prematurely
            ),
          ],
        );
      case RequestStatus.completed:
        return Column(
          children: [
            _buildActionButton(
              context,
              label: 'View Feedback',
              icon: Icons.star_outline,
              color: AppTheme.ratingColor,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View feedback not implemented yet')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'Archive Service',
              icon: Icons.archive_outlined,
              color: AppTheme.infoColor,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Archive not implemented yet')),
                );
              },
            ),
          ],
        );
      case RequestStatus.cancelled:
        return Column(
          children: [
            _buildActionButton(
              context,
              label: 'Reschedule Service',
              icon: Icons.event_repeat,
              color: AppTheme.primaryColor,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reschedule not implemented yet')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'Delete Service',
              icon: Icons.delete_forever,
              color: AppTheme.errorColor,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete action from here not implemented yet')),
                );
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _acceptRequest(BuildContext context) {
    // TODO: Implement accept request functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _startService(BuildContext context) {
    // TODO: Implement start service functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service started successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _completeService(BuildContext context) {
    // TODO: Implement complete service functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service completed successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: Text('Are you sure you want to reject the service request from ${request.customerName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement reject functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service request rejected'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
              child: const Text('Yes', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        );
      },
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: Text('Are you sure you want to cancel the service for ${request.customerName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement cancel functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service cancelled'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
              child: const Text('Yes', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        );
      },
    );
  }
}






































