import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_timer_widget.dart';
import '../widgets/consultation_notes_widget.dart';
import '../widgets/consultation_actions_widget.dart';
import '../widgets/consultation_info_widget.dart';

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

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and actions
            _buildHeader(),
            
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
                        ConsultationInfoWidget(consultation: widget.consultation),
                        const SizedBox(height: 24),
                        
                        // Timer Widget (if in progress)
                        if (widget.consultation.status == ConsultationStatus.inProgress)
                          ConsultationTimerWidget(consultation: widget.consultation),
                        
                        if (widget.consultation.status == ConsultationStatus.inProgress)
                          const SizedBox(height: 24),
                        
                        // Notes Section
                        ConsultationNotesWidget(consultation: widget.consultation),
                        const SizedBox(height: 24),
                        
                        // Actions Section
                        ConsultationActionsWidget(consultation: widget.consultation),
                        const SizedBox(height: 24),
                        
                        // Status History
                        _buildStatusHistory(),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF475569),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  widget.consultation.clientName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          // More actions
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showMoreOptions();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Status History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status timeline
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {
        'status': 'Scheduled',
        'time': widget.consultation.scheduledTime,
        'icon': Icons.schedule,
        'color': const Color(0xFF3B82F6),
      },
      if (widget.consultation.startedAt != null)
        {
          'status': 'Started',
          'time': widget.consultation.startedAt!,
          'icon': Icons.play_arrow,
          'color': const Color(0xFF10B981),
        },
      if (widget.consultation.status == ConsultationStatus.completed)
        {
          'status': 'Completed',
          'time': widget.consultation.completedAt ?? DateTime.now(),
          'icon': Icons.check_circle,
          'color': const Color(0xFF059669),
        },
      if (widget.consultation.status == ConsultationStatus.cancelled)
        {
          'status': 'Cancelled',
          'time': widget.consultation.cancelledAt ?? DateTime.now(),
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444),
        },
    ];

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
                    color: const Color(0xFFE2E8F0),
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
                    status['status'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(status['time'] as DateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                color: const Color(0xFFE2E8F0),
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
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                // TODO: Duplicate consultation
              },
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share Details',
              onTap: () {
                Navigator.pop(context);
                // TODO: Share consultation
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
              isDestructive: true,
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
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive 
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive 
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Consultation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this consultation? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete consultation
              context.read<ConsultationsBloc>().add(
                DeleteConsultationEvent(consultationId: widget.consultation.id),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
