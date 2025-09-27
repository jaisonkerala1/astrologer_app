import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/consultation_model.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../services/consultations_service.dart';

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
              icon: Icons.replay,
              label: 'Reschedule',
              description: 'Schedule another session',
              color: const Color(0xFF3B82F6),
              onTap: () => _rescheduleConsultation(context),
            ),
            const SizedBox(height: 12),
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
        HapticFeedback.lightImpact();
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

  void _completeConsultation(BuildContext context) {
    context.read<ConsultationsBloc>().add(
      CompleteConsultationEvent(consultationId: consultation.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation completed successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
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

  void _rescheduleConsultation(BuildContext context) {
    _showRescheduleDialog(context);
  }

  void _showRescheduleDialog(BuildContext context) {
    DateTime selectedDate = consultation.scheduledTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(consultation.scheduledTime);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reschedule Consultation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select new date and time for the consultation',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              
              // Date picker
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time picker
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
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
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              onPressed: () async {
                Navigator.pop(context);
                await _performReschedule(context, selectedDate, selectedTime);
              },
              child: const Text(
                'Reschedule',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performReschedule(BuildContext context, DateTime selectedDate, TimeOfDay selectedTime) async {
    try {
      // Combine date and time
      final newScheduledTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Check if the new time is in the future
      if (newScheduledTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a future date and time'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Rescheduling consultation...'),
            ],
          ),
          backgroundColor: Color(0xFF3B82F6),
          duration: Duration(seconds: 2),
        ),
      );

      // Import the consultations service
      final consultationsService = ConsultationsService();
      
      // Update consultation with new scheduled time
      await consultationsService.updateConsultationById(
        consultation.id,
        {
          'scheduledTime': newScheduledTime.toIso8601String(),
          'status': 'scheduled', // Ensure status is scheduled after reschedule
        },
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation rescheduled successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      // Refresh the consultation data
      if (context.mounted) {
        // Trigger a refresh of the consultation data
        // The parent widget should listen to this and update accordingly
      }

    } catch (e) {
      print('Error rescheduling consultation: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _rateConsultation(BuildContext context) {
    // TODO: Implement rating functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating functionality coming soon'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  void _shareConsultation(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }
}
