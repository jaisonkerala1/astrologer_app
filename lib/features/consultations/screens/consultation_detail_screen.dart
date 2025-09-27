import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../bloc/consultations_state.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_timer_widget.dart';
import '../widgets/consultation_notes_widget.dart';
import '../widgets/consultation_actions_widget.dart';
import '../widgets/consultation_info_widget.dart';
import '../../../shared/theme/services/theme_service.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final ConsultationModel consultation;

  const ConsultationDetailScreen({
    super.key,
    required this.consultation,
  });

  @override
  State<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late ConsultationModel _currentConsultation;

  @override
  void initState() {
    super.initState();
    _currentConsultation = widget.consultation;
    
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConsultationsBloc, ConsultationsState>(
      listener: (context, state) {
        if (state is ConsultationsLoaded) {
          final updatedConsultation = state.allConsultations.firstWhere(
            (c) => c.id == _currentConsultation.id,
            orElse: () => _currentConsultation,
          );
          if (updatedConsultation != _currentConsultation) {
            setState(() {
              _currentConsultation = updatedConsultation;
            });
          }
        } else if (state is ConsultationUpdated) {
          if (state.consultation.id == _currentConsultation.id) {
            setState(() {
              _currentConsultation = state.consultation;
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
                            // Consultation Info Card
                            ConsultationInfoWidget(consultation: _currentConsultation),
                            const SizedBox(height: 24),
                            
                            // Timer Widget (if in progress)
                            if (_currentConsultation.status == ConsultationStatus.inProgress)
                              ConsultationTimerWidget(consultation: _currentConsultation),
                            
                            if (_currentConsultation.status == ConsultationStatus.inProgress)
                              const SizedBox(height: 24),
                            
                            // Notes Section
                            ConsultationNotesWidget(consultation: _currentConsultation),
                            const SizedBox(height: 24),
                            
                            // Actions Section
                            ConsultationActionsWidget(consultation: _currentConsultation),
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
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
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
                  'Consultation Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                Text(
                  _currentConsultation.clientName,
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
              HapticFeedback.lightImpact();
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
    );
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
          _buildStatusTimeline(themeService),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(ThemeService themeService) {
    // Use status history if available, otherwise fallback to current status
    final statusHistory = _currentConsultation.statusHistory;
    
    if (statusHistory.isEmpty) {
      // Fallback for consultations without status history
      final statuses = [
        {
          'status': 'Scheduled',
          'time': _currentConsultation.scheduledTime,
          'icon': Icons.schedule,
          'color': themeService.primaryColor,
          'notes': 'Consultation scheduled',
        },
        if (_currentConsultation.startedAt != null)
          {
            'status': 'Started',
            'time': _currentConsultation.startedAt!,
            'icon': Icons.play_arrow,
            'color': themeService.successColor,
            'notes': 'Consultation started',
          },
        if (_currentConsultation.status == ConsultationStatus.completed)
          {
            'status': 'Completed',
            'time': _currentConsultation.completedAt ?? DateTime.now(),
            'icon': Icons.check_circle,
            'color': themeService.successColor,
            'notes': 'Consultation completed',
          },
        if (_currentConsultation.status == ConsultationStatus.cancelled)
          {
            'status': 'Cancelled',
            'time': _currentConsultation.cancelledAt ?? DateTime.now(),
            'icon': Icons.cancel,
            'color': themeService.errorColor,
            'notes': 'Consultation cancelled',
          },
      ];
      
      return _buildTimelineFromStatuses(statuses, themeService);
    }
    
    // Build timeline from status history
    final statuses = statusHistory.map((entry) {
      IconData icon;
      Color color;
      
      switch (entry.status) {
        case 'scheduled':
          icon = Icons.schedule;
          color = themeService.primaryColor;
          break;
        case 'rescheduled':
          icon = Icons.schedule_send;
          color = const Color(0xFF3B82F6);
          break;
        case 'inProgress':
          icon = Icons.play_arrow;
          color = themeService.successColor;
          break;
        case 'completed':
          icon = Icons.check_circle;
          color = themeService.successColor;
          break;
        case 'cancelled':
          icon = Icons.cancel;
          color = themeService.errorColor;
          break;
        default:
          icon = Icons.info;
          color = themeService.textSecondary;
      }
      
      return {
        'status': entry.status,
        'time': entry.timestamp,
        'icon': icon,
        'color': color,
        'notes': entry.notes,
        'scheduledTime': entry.scheduledTime,
      };
    }).toList();
    
    return _buildTimelineFromStatuses(statuses, themeService);
  }

  Widget _buildTimelineFromStatuses(List<Map<String, dynamic>> statuses, ThemeService themeService) {

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isLast = index == statuses.length - 1;

        return Row(
          children: [
            // Timeline line
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: status['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: themeService.borderColor,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatStatusName(status['status'] as String),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(status['time'] as DateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.textSecondary,
                    ),
                  ),
                  if (status['notes'] != null && (status['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      status['notes'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeService.textSecondary.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (status['scheduledTime'] != null && status['status'] == 'rescheduled') ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'New time: ${DateFormat('MMM dd, hh:mm a').format(status['scheduledTime'] as DateTime)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatStatusName(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'rescheduled':
        return 'Rescheduled';
      case 'inprogress':
        return 'Started';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'noshow':
        return 'No Show';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
              title: 'Edit Consultation',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                // TODO: Duplicate consultation
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share Details',
              onTap: () {
                Navigator.pop(context);
                // TODO: Share consultation
              },
              themeService: themeService,
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
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
          'Delete Consultation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this consultation? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: themeService.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
              // TODO: Delete consultation
              context.read<ConsultationsBloc>().add(
                DeleteConsultationEvent(consultationId: _currentConsultation.id),
              );
              Navigator.pop(context);
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
