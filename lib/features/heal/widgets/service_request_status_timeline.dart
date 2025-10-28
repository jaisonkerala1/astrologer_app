import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_request_model.dart';

class ServiceRequestStatusTimeline extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestStatusTimeline({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> statusEvents = _buildStatusEvents();

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statusEvents.length,
          itemBuilder: (context, index) {
            final event = statusEvents[index];
            final isLast = index == statusEvents.length - 1;
            return _TimelineTile(
              isFirst: index == 0,
              isLast: isLast,
              status: event['status'],
              timestamp: event['timestamp'],
              themeService: themeService,
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildStatusEvents() {
    List<Map<String, dynamic>> events = [];

    // Request created event (always exists)
    events.add({
      'status': RequestStatus.pending,
      'timestamp': request.createdAt,
    });

    // Started event
    if (request.startedAt != null) {
      events.add({
        'status': RequestStatus.inProgress,
        'timestamp': request.startedAt,
      });
    }

    // Completed event
    if (request.completedAt != null) {
      events.add({
        'status': RequestStatus.completed,
        'timestamp': request.completedAt,
      });
    }

    // Cancelled event
    if (request.cancelledAt != null) {
      events.add({
        'status': RequestStatus.cancelled,
        'timestamp': request.cancelledAt,
      });
    }

    // Sort events by timestamp
    events.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    return events;
  }
}

class _TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final RequestStatus status;
  final DateTime timestamp;
  final ThemeService themeService;

  const _TimelineTile({
    required this.isFirst,
    required this.isLast,
    required this.status,
    required this.timestamp,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    Color lineColor = _getStatusColor(status, themeService);
    IconData icon = _getStatusIcon(status);
    String statusText = _getStatusText(status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: themeService.borderColor,
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: lineColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: themeService.surfaceColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: lineColor.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: themeService.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isFirst ? 0 : 4, bottom: isLast ? 0 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RequestStatus status, ThemeService themeService) {
    switch (status) {
      case RequestStatus.pending:
        return themeService.primaryColor; // Match consultation 'scheduled' color
      case RequestStatus.confirmed:
        return const Color(0xFF3B82F6); // Blue like consultation 'rescheduled'
      case RequestStatus.inProgress:
        return themeService.successColor;
      case RequestStatus.completed:
        return themeService.successColor;
      case RequestStatus.cancelled:
        return themeService.errorColor;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.schedule;
      case RequestStatus.confirmed:
        return Icons.check_circle;
      case RequestStatus.inProgress:
        return Icons.play_arrow;
      case RequestStatus.completed:
        return Icons.check_circle;
      case RequestStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Request Received';
      case RequestStatus.confirmed:
        return 'Request Confirmed';
      case RequestStatus.inProgress:
        return 'Service In Progress';
      case RequestStatus.completed:
        return 'Service Completed';
      case RequestStatus.cancelled:
        return 'Service Cancelled';
    }
  }
}






































