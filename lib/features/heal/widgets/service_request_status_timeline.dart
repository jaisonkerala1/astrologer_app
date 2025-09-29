import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';

class ServiceRequestStatusTimeline extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestStatusTimeline({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> statusEvents = _buildStatusEvents();

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
            'Status History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
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
              );
            },
          ),
        ],
      ),
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

  const _TimelineTile({
    required this.isFirst,
    required this.isLast,
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    Color lineColor = _getStatusColor(status);
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
                    color: lineColor.withOpacity(0.5),
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: lineColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
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
                    color: lineColor.withOpacity(0.5),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return const Color(0xFFFFA500); // Orange
      case RequestStatus.confirmed:
        return AppTheme.primaryColor;
      case RequestStatus.inProgress:
        return AppTheme.successColor;
      case RequestStatus.completed:
        return AppTheme.successColor;
      case RequestStatus.cancelled:
        return AppTheme.errorColor;
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






































