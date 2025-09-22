import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';
import '../widgets/service_request_info_widget.dart';
import '../widgets/service_request_timer_widget.dart';
import '../widgets/service_request_notes_widget.dart';
import '../widgets/service_request_actions_widget.dart';
import '../widgets/service_request_status_timeline.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final ServiceRequest request;

  const ServiceRequestDetailScreen({super.key, required this.request});

  @override
  State<ServiceRequestDetailScreen> createState() => _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState extends State<ServiceRequestDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          widget.request.customerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceRequestInfoWidget(request: widget.request),
            const SizedBox(height: 24),
            ServiceRequestTimerWidget(request: widget.request),
            const SizedBox(height: 24),
            ServiceRequestNotesWidget(request: widget.request),
            const SizedBox(height: 24),
            ServiceRequestActionsWidget(request: widget.request),
            const SizedBox(height: 24),
            ServiceRequestStatusTimeline(request: widget.request),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Service Request'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
                title: const Text('Delete Service Request', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the service request for ${widget.request.customerName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
                Navigator.pop(context); // Pop the detail screen after deletion
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}





