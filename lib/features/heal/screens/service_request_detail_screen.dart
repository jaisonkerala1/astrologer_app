import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeService.primaryColor,
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
                onPressed: () => _showMoreOptions(context, themeService),
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
      },
    );
  }

  void _showMoreOptions(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit, color: themeService.textPrimary),
                title: Text('Edit Service Request', style: TextStyle(color: themeService.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: themeService.errorColor),
                title: Text('Delete Service Request', style: TextStyle(color: themeService.errorColor)),
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
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeService.surfaceColor,
          title: Text('Confirm Delete', style: TextStyle(color: themeService.textPrimary)),
          content: Text(
            'Are you sure you want to delete the service request for ${widget.request.customerName}?',
            style: TextStyle(color: themeService.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: themeService.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
                Navigator.pop(context); // Pop the detail screen after deletion
              },
              child: Text(
                'Delete',
                style: TextStyle(color: themeService.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}















