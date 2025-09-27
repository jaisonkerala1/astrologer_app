import 'package:flutter/material.dart';
import '../models/consultation_model.dart';

class ConsultationInfoWidget extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationInfoWidget({
    super.key,
    required this.consultation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          // Header with status
          Row(
            children: [
              Expanded(
                child: Text(
                  consultation.clientName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Client info
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Client',
            value: consultation.clientName,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: consultation.clientPhone,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Scheduled',
            value: _formatDateTime(consultation.scheduledTime),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: consultation.type.displayName,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.attach_money_outlined,
            label: 'Amount',
            value: '₹${consultation.amount}',
          ),
          
          if (consultation.notes != null && consultation.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              consultation.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
          
          // Astrologer Rating (if rated)
          if (consultation.astrologerRating != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            _buildRatingRow(),
          ],
          
          // Share Count (if shared)
          if (consultation.shareCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            _buildShareRow(),
          ],
          
          // Reschedule Count (if rescheduled)
          if (consultation.rescheduleCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            _buildRescheduleRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (consultation.status) {
      case ConsultationStatus.scheduled:
        backgroundColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF2563EB);
        statusText = 'Scheduled';
        break;
      case ConsultationStatus.inProgress:
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        statusText = 'In Progress';
        break;
      case ConsultationStatus.completed:
        backgroundColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF16A34A);
        statusText = 'Completed';
        break;
      case ConsultationStatus.cancelled:
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        statusText = 'Cancelled';
        break;
      case ConsultationStatus.noShow:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        statusText = 'No Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
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
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(dateTime.weekday)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 8),
        Text(
          'Astrologer Rating',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < consultation.astrologerRating! ? Icons.star : Icons.star_border,
              size: 16,
              color: const Color(0xFFF59E0B),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '${consultation.astrologerRating}/5',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildShareRow() {
    return Row(
      children: [
        Icon(
          Icons.share,
          size: 16,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 8),
        Text(
          'Shared ${consultation.shareCount} time${consultation.shareCount == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        if (consultation.lastSharedAt != null) ...[
          const Spacer(),
          Text(
            _formatDateTime(consultation.lastSharedAt!),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRescheduleRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_send,
              size: 16,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            Text(
              'Rescheduled ${consultation.rescheduleCount} time${consultation.rescheduleCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            if (consultation.lastRescheduledAt != null) ...[
              const Spacer(),
              Text(
                _formatDateTime(consultation.lastRescheduledAt!),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
        if (consultation.originalScheduledTime != null) ...[
          const SizedBox(height: 4),
          Text(
            'Original time: ${_formatDateTime(consultation.originalScheduledTime!)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
