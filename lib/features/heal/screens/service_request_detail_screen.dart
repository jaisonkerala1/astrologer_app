import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_request_model.dart';
import '../widgets/service_request_info_widget.dart';
import '../widgets/service_request_timer_widget.dart';
import '../widgets/service_request_notes_widget.dart';
import '../widgets/service_request_actions_widget.dart';
import '../widgets/service_request_status_timeline.dart';
import '../bloc/heal_bloc.dart';
import '../bloc/heal_state.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final ServiceRequest request;

  const ServiceRequestDetailScreen({super.key, required this.request});

  @override
  State<ServiceRequestDetailScreen> createState() => _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState extends State<ServiceRequestDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late ServiceRequest _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Find the next pending/confirmed request after the current one
  ServiceRequest? _findNextRequest() {
    final bloc = context.read<HealBloc>();
    final state = bloc.state;
    
    if (state is! HealLoadedState) return null;
    
    final now = DateTime.now();
    
    // Find requests that are pending or confirmed and created after the current one
    final upcomingRequests = state.serviceRequests
        .where((request) =>
            request.id != _currentRequest.id &&
            (request.status == RequestStatus.pending || 
             request.status == RequestStatus.confirmed) &&
            request.createdAt.isAfter(_currentRequest.createdAt))
        .toList();
    
    if (upcomingRequests.isEmpty) return null;
    
    // Sort by created time and return the earliest
    upcomingRequests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return upcomingRequests.first;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HealBloc, HealState>(
      listener: (context, state) {
        if (state is HealLoadedState) {
          final updatedRequest = state.serviceRequests.firstWhere(
            (r) => r.id == _currentRequest.id,
            orElse: () => _currentRequest,
          );
          if (updatedRequest != _currentRequest) {
            setState(() {
              _currentRequest = updatedRequest;
            });
          }
        }
      },
      child: Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Header with back button and actions
                  _buildHeader(themeService),
                  
                  // Main content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service Request Info Card
                              ServiceRequestInfoWidget(request: _currentRequest),
                              const SizedBox(height: 24),
                              
                              // Timer Widget (if in progress)
                              if (_currentRequest.status == RequestStatus.inProgress)
                                ServiceRequestTimerWidget(request: _currentRequest),
                              
                              if (_currentRequest.status == RequestStatus.inProgress)
                                const SizedBox(height: 24),
                              
                              // Notes Section
                              ServiceRequestNotesWidget(request: _currentRequest),
                              const SizedBox(height: 24),
                              
                              // Actions Section
                              ServiceRequestActionsWidget(request: _currentRequest),
                              const SizedBox(height: 24),
                              
                              // Status History
                              _buildStatusHistory(themeService),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    final nextRequest = _findNextRequest();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: themeService.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: themeService.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Request Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeService.textPrimary,
                      ),
                    ),
                    Text(
                      _currentRequest.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // More actions
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showMoreOptions(themeService);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: themeService.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          
          // Next Request Button
          if (nextRequest != null) ...[
            const SizedBox(height: 12),
            _buildNextRequestButton(nextRequest, themeService),
          ],
        ],
      ),
    );
  }

  Widget _buildNextRequestButton(ServiceRequest nextRequest, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final healBloc = context.read<HealBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => BlocProvider.value(
              value: healBloc,
              child: ServiceRequestDetailScreen(request: nextRequest),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeService.primaryColor.withOpacity(0.1),
              themeService.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule,
                size: 16,
                color: themeService.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Request',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: themeService.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextRequest.customerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getStatusText(nextRequest.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeService.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(nextRequest.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: themeService.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.confirmed:
        return 'Confirmed';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7 && difference > 0) {
      return 'In $difference days';
    } else if (difference < 0 && difference > -7) {
      return '${difference.abs()} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildStatusHistory(ThemeService themeService) {
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
                'Status History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status timeline
          ServiceRequestStatusTimeline(request: _currentRequest),
        ],
      ),
    );
  }

  void _showMoreOptions(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeService.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Options
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Edit Request',
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.selectionClick();
                // TODO: Navigate to edit screen
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.selectionClick();
                // TODO: Duplicate request
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share Details',
                onTap: () {
                  Navigator.pop(context);
                HapticFeedback.selectionClick();
                // TODO: Share request
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                HapticFeedback.selectionClick();
                _showDeleteConfirmation(themeService);
              },
              isDestructive: true,
              themeService: themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeService themeService,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? themeService.errorColor.withOpacity(0.1)
                    : themeService.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive 
                    ? themeService.errorColor
                    : themeService.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive 
                    ? themeService.errorColor
                    : themeService.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: themeService.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Service Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
          content: Text(
          'Are you sure you want to delete the request from ${_currentRequest.customerName}? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: themeService.textSecondary,
          ),
        ),
        actions: [
            TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
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
                Navigator.pop(context);
              // TODO: Delete request using BLoC
              // context.read<HealBloc>().add(DeleteServiceRequestEvent(...));
              Navigator.pop(context); // Pop the detail screen
              },
              child: Text(
                'Delete',
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
