import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/consultation_model.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../services/consultations_service.dart';
import 'rating_dialog.dart';
import 'complete_consultation_bottom_sheet.dart';

class ConsultationActionsWidget extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationActionsWidget({
    super.key,
    required this.consultation,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header
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
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action buttons based on status
          if (consultation.status == ConsultationStatus.scheduled) ...[
            _buildActionButton(
              context: context,
              icon: Icons.play_arrow,
              label: 'Start Consultation',
              description: 'Begin the session',
              color: const Color(0xFF10B981),
              onTap: () => _startConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.schedule,
              label: 'Reschedule',
              description: 'Change the appointment time',
              color: const Color(0xFF3B82F6),
              onTap: () => _rescheduleConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.phone,
              label: 'Call Client',
              description: 'Make a voice call',
              color: const Color(0xFF3B82F6),
              onTap: () => _callClient(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.message,
              label: 'Send Message',
              description: 'Send a text message',
              color: const Color(0xFF8B5CF6),
              onTap: () => _sendMessage(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.cancel_outlined,
              label: 'Cancel',
              description: 'Cancel this consultation',
              color: const Color(0xFFEF4444),
              onTap: () => _cancelConsultation(context),
            ),
          ] else if (consultation.status == ConsultationStatus.inProgress) ...[
            _buildActionButton(
              context: context,
              icon: Icons.stop,
              label: 'Complete Session',
              description: 'End the consultation',
              color: const Color(0xFF10B981),
              onTap: () => _completeConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.pause,
              label: 'Pause Session',
              description: 'Temporarily pause',
              color: const Color(0xFFF59E0B),
              onTap: () => _pauseConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.phone,
              label: 'Call Client',
              description: 'Make a voice call',
              color: const Color(0xFF3B82F6),
              onTap: () => _callClient(context),
            ),
          ] else if (consultation.status == ConsultationStatus.completed) ...[
            _buildActionButton(
              context: context,
              icon: Icons.star_outline,
              label: 'Rate Session',
              description: 'Rate this consultation',
              color: const Color(0xFFF59E0B),
              onTap: () => _rateConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.share,
              label: 'Share Details',
              description: 'Share consultation info',
              color: const Color(0xFF8B5CF6),
              onTap: () => _shareConsultation(context),
            ),
          ] else if (consultation.status == ConsultationStatus.cancelled) ...[
            _buildActionButton(
              context: context,
              icon: Icons.replay,
              label: 'Reschedule',
              description: 'Schedule a new session',
              color: const Color(0xFF3B82F6),
              onTap: () => _rescheduleConsultation(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              icon: Icons.phone,
              label: 'Call Client',
              description: 'Make a voice call',
              color: const Color(0xFF10B981),
              onTap: () => _callClient(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
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

  void _startConsultation(BuildContext context) {
    context.read<ConsultationsBloc>().add(
      StartConsultationEvent(consultationId: consultation.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation started successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _completeConsultation(BuildContext context) async {
    final result = await CompleteConsultationBottomSheet.show(
      context: context,
      clientName: consultation.clientName,
      duration: consultation.duration,
      amount: consultation.amount,
    );
    
    if (result != null && context.mounted) {
      context.read<ConsultationsBloc>().add(
        CompleteConsultationEvent(
          consultationId: consultation.id,
          notes: result['notes'] as String?,
          review: result['review'] as String?,
          rating: result['rating'] as int?,
        ),
      );
    }
  }

  void _pauseConsultation(BuildContext context) {
    // TODO: Implement pause functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pause functionality coming soon'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  void _cancelConsultation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Consultation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this consultation?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ConsultationsBloc>().add(
                CancelConsultationEvent(consultationId: consultation.id),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consultation cancelled'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            child: const Text(
              'Yes, Cancel',
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

  void _callClient(BuildContext context) {
    // TODO: Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call functionality coming soon'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    // TODO: Implement message functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message functionality coming soon'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  void _rescheduleConsultation(BuildContext context) async {
    // Show confirmation dialog first
    final bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reschedule Consultation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Schedule:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(consultation.scheduledTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to select a new date and time?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Select New Time',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldProceed == true && context.mounted) {
      await _showDateTimePicker(context);
    }
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    // Step 1: Select Date
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: consultation.scheduledTime.isAfter(DateTime.now()) 
          ? consultation.scheduledTime 
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select New Date',
      confirmText: 'Next',
      cancelText: 'Cancel',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      // Step 2: Select Time
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(consultation.scheduledTime),
        helpText: 'Select New Time',
        confirmText: 'Confirm',
        cancelText: 'Back',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3B82F6),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1E293B),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null && context.mounted) {
        // Step 3: Show confirmation dialog
        await _showRescheduleConfirmation(context, selectedDate, selectedTime);
      }
    }
  }

  Future<void> _showRescheduleConfirmation(BuildContext context, DateTime selectedDate, TimeOfDay selectedTime) async {
    final newScheduledTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Reschedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New Schedule',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(newScheduledTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(newScheduledTime),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to reschedule this consultation?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reschedule',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _performReschedule(context, selectedDate, selectedTime);
    }
  }

  Future<void> _performReschedule(BuildContext context, DateTime selectedDate, TimeOfDay selectedTime) async {
    try {
      final newScheduledTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (newScheduledTime.isBefore(DateTime.now())) {
        if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
              content: Text('Cannot schedule consultation in the past'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Show loading dialog with better UX
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 16),
              Text(
                'Rescheduling consultation...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we update your schedule',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );

      final consultationsService = ConsultationsService();
      await consultationsService.rescheduleConsultation(
        consultation.id,
        newScheduledTime,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Successfully Rescheduled!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation has been rescheduled to:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(newScheduledTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        
        // Refresh consultations
        context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reschedule Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Failed to reschedule consultation: ${e.toString()}',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  void _rateConsultation(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RatingDialog(
        consultationId: consultation.id,
        clientName: consultation.clientName,
        currentRating: consultation.astrologerRating,
        currentFeedback: consultation.astrologerFeedback,
      ),
    );

    if (result != null) {
      try {
        final consultationsService = ConsultationsService();
        await consultationsService.addAstrologerRating(
          consultation.id,
          result['rating'] as int,
          result['feedback'] as String?,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Refresh consultations
        context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _shareConsultation(BuildContext context) async {
    try {
      // Create share content
      final shareContent = _createShareContent();
      
      // Use native share functionality
      await Share.share(
        shareContent,
        subject: 'Consultation Details - ${consultation.clientName}',
      );

      // Track the share
      final consultationsService = ConsultationsService();
      await consultationsService.trackConsultationShare(consultation.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation shared successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // Refresh consultations to update share count
      context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share consultation: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  String _createShareContent() {
    final date = DateFormat('MMM dd, yyyy').format(consultation.scheduledTime);
    final time = DateFormat('hh:mm a').format(consultation.scheduledTime);
    
    return '''
🌟 Consultation Details

👤 Client: ${consultation.clientName}
📅 Date: $date
⏰ Time: $time
⏱️ Duration: ${consultation.duration} minutes
💰 Amount: ₹${consultation.amount.toStringAsFixed(0)}
📱 Type: ${consultation.type.toString().split('.').last.toUpperCase()}
📊 Status: ${consultation.status.displayName}

${consultation.notes != null && consultation.notes!.isNotEmpty ? '📝 Notes: ${consultation.notes}' : ''}

Shared via Astrologer App
    ''';
  }
}
