import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../consultations/models/consultation_model.dart';

class CalendarWidget extends StatefulWidget {
  final List<ConsultationModel> consultations;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(ConsultationModel) onConsultationSelected;
  final bool showConsultations;

  const CalendarWidget({
    super.key,
    required this.consultations,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onConsultationSelected,
    this.showConsultations = true,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCalendarGrid(),
          if (widget.showConsultations) ...[
            const Divider(height: 1),
            _buildConsultations(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Month/Year
          Expanded(
            child: Text(
              _getMonthYearText(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              _buildNavButton(Icons.chevron_left, () => _previousMonth()),
              const SizedBox(width: 8),
              _buildNavButton(Icons.chevron_right, () => _nextMonth()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day headers
          _buildDayHeaders(),
          const SizedBox(height: 8),
          // Calendar days
          _buildCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const dayNames = ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'];
    
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Column(
            children: [
              Text(
                days[index],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                dayNames[index],
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: List.generate(6, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstDayWeekday + 1;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: Container(height: 40));
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final hasSlots = _hasConsultations(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(date),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : isToday
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 1)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppTheme.primaryColor
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        if (hasSlots)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildConsultations() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    // Debug: Log all consultations
    print('📅 [CalendarWidget] Total consultations received: ${widget.consultations.length}');
    print('📅 [CalendarWidget] Selected date: $_selectedDate');
    for (var consultation in widget.consultations) {
      print('📅 [CalendarWidget] Consultation: ${consultation.clientName} at ${consultation.scheduledTime} (local time)');
      print('📅 [CalendarWidget] Is same day? ${_isSameDay(consultation.scheduledTime, _selectedDate)}');
    }
    
    // Show consultations for the selected date
    final dayConsultations = widget.consultations
        .where((consultation) => _isSameDay(consultation.scheduledTime, _selectedDate))
        .toList();
    
    print('📅 [CalendarWidget] Filtered consultations for selected day: ${dayConsultations.length}');
    
    // Sort consultations by time and status based on the selected date
    dayConsultations.sort((a, b) {
      // For past dates: show completed/cancelled first, then scheduled
      // For today: show scheduled first, then completed
      // For future dates: show scheduled first
      if (selectedDay.isBefore(today)) {
        // Past dates: completed/cancelled first, then scheduled
        final statusPriority = _getPastDateStatusPriority(a.status).compareTo(_getPastDateStatusPriority(b.status));
        if (statusPriority != 0) return statusPriority;
      } else if (selectedDay.isAtSameMomentAs(today)) {
        // Today: scheduled first, then completed
        final statusPriority = _getTodayStatusPriority(a.status).compareTo(_getTodayStatusPriority(b.status));
        if (statusPriority != 0) return statusPriority;
      } else {
        // Future dates: scheduled first
        final statusPriority = _getFutureDateStatusPriority(a.status).compareTo(_getFutureDateStatusPriority(b.status));
        if (statusPriority != 0) return statusPriority;
      }
      
      // Then sort by time
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    if (dayConsultations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyStateTitle(selectedDay, today),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getEmptyStateMessage(selectedDay, today),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getSectionTitle(selectedDay, today),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...dayConsultations.map((consultation) => _buildConsultationCard(consultation)).toList(),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationModel consultation) {
    return GestureDetector(
      onTap: () => widget.onConsultationSelected(consultation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getStatusColor(consultation.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(consultation.status).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(consultation.status),
              color: _getStatusColor(consultation.status),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consultation.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime(consultation.scheduledTime)} - ${consultation.duration} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    consultation.type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(consultation.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                consultation.status.displayName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthYearText() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      // Select first day of new month to trigger loading consultations for that month
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    // Notify parent to load consultations for the new month
    widget.onDateSelected(_selectedDate);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      // Select first day of new month to trigger loading consultations for that month
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    // Notify parent to load consultations for the new month
    widget.onDateSelected(_selectedDate);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _hasConsultations(DateTime date) {
    return widget.consultations.any((consultation) => _isSameDay(consultation.scheduledTime, date));
  }

  Color _getStatusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return Colors.blue;
      case ConsultationStatus.inProgress:
        return Colors.orange;
      case ConsultationStatus.completed:
        return Colors.green;
      case ConsultationStatus.cancelled:
        return Colors.red;
      case ConsultationStatus.noShow:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return Icons.schedule;
      case ConsultationStatus.inProgress:
        return Icons.play_circle;
      case ConsultationStatus.completed:
        return Icons.check_circle;
      case ConsultationStatus.cancelled:
        return Icons.cancel;
      case ConsultationStatus.noShow:
        return Icons.person_off;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  int _getStatusPriority(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 1; // First priority - upcoming/scheduled
      case ConsultationStatus.inProgress:
        return 2; // Second priority - currently in progress
      case ConsultationStatus.completed:
        return 3; // Third priority - completed
      case ConsultationStatus.cancelled:
        return 4; // Fourth priority - cancelled
      case ConsultationStatus.noShow:
        return 5; // Last priority - no show
    }
  }

  // Priority for past dates: completed/cancelled first, then scheduled
  int _getPastDateStatusPriority(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.completed:
        return 1; // First priority - completed
      case ConsultationStatus.cancelled:
        return 2; // Second priority - cancelled
      case ConsultationStatus.noShow:
        return 3; // Third priority - no show
      case ConsultationStatus.scheduled:
        return 4; // Fourth priority - scheduled (shouldn't happen for past dates)
      case ConsultationStatus.inProgress:
        return 5; // Last priority - in progress (shouldn't happen for past dates)
    }
  }

  // Priority for today: scheduled first, then completed
  int _getTodayStatusPriority(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 1; // First priority - upcoming/scheduled
      case ConsultationStatus.inProgress:
        return 2; // Second priority - currently in progress
      case ConsultationStatus.completed:
        return 3; // Third priority - completed
      case ConsultationStatus.cancelled:
        return 4; // Fourth priority - cancelled
      case ConsultationStatus.noShow:
        return 5; // Last priority - no show
    }
  }

  // Priority for future dates: scheduled first
  int _getFutureDateStatusPriority(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 1; // First priority - scheduled
      case ConsultationStatus.inProgress:
        return 2; // Second priority - in progress (shouldn't happen for future dates)
      case ConsultationStatus.completed:
        return 3; // Third priority - completed (shouldn't happen for future dates)
      case ConsultationStatus.cancelled:
        return 4; // Fourth priority - cancelled
      case ConsultationStatus.noShow:
        return 5; // Last priority - no show
    }
  }

  String _getSectionTitle(DateTime selectedDay, DateTime today) {
    if (selectedDay.isBefore(today)) {
      return 'Past Consultations';
    } else if (selectedDay.isAtSameMomentAs(today)) {
      return 'Today\'s Consultations';
    } else {
      return 'Upcoming Consultations';
    }
  }

  String _getEmptyStateTitle(DateTime selectedDay, DateTime today) {
    if (selectedDay.isBefore(today)) {
      return 'No past consultations';
    } else if (selectedDay.isAtSameMomentAs(today)) {
      return 'No consultations for today';
    } else {
      return 'No upcoming consultations';
    }
  }

  String _getEmptyStateMessage(DateTime selectedDay, DateTime today) {
    if (selectedDay.isBefore(today)) {
      return 'You have no consultations scheduled for this past date';
    } else if (selectedDay.isAtSameMomentAs(today)) {
      return 'You have no consultations scheduled for today';
    } else {
      return 'You have no consultations scheduled for this future date';
    }
  }
}
