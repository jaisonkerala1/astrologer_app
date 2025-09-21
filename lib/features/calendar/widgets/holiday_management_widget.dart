import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/holiday_model.dart';

class HolidayManagementWidget extends StatefulWidget {
  const HolidayManagementWidget({super.key});

  @override
  State<HolidayManagementWidget> createState() => _HolidayManagementWidgetState();
}

class _HolidayManagementWidgetState extends State<HolidayManagementWidget> {
  List<HolidayModel> _holidays = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from API
      _generateSampleHolidays();
    } catch (e) {
      print('Error loading holidays: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateSampleHolidays() {
    final holidays = <HolidayModel>[];
    
    // Add some sample holidays
    holidays.addAll([
      HolidayModel(
        id: 'holiday_1',
        astrologerId: 'current_astrologer',
        date: DateTime(2025, 1, 26), // Republic Day
        reason: 'Republic Day',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
      HolidayModel(
        id: 'holiday_2',
        astrologerId: 'current_astrologer',
        date: DateTime(2025, 3, 8), // Holi
        reason: 'Holi',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
      HolidayModel(
        id: 'holiday_3',
        astrologerId: 'current_astrologer',
        date: DateTime(2025, 4, 14), // Ambedkar Jayanti
        reason: 'Ambedkar Jayanti',
        isRecurring: true,
        recurringPattern: 'yearly',
        createdAt: DateTime.now(),
      ),
    ]);
    
    setState(() {
      _holidays = holidays;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Holidays & Unavailable Days',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _addHoliday,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Holidays List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_holidays.isEmpty)
            _buildEmptyState()
          else
            ..._holidays.map((holiday) => _buildHolidayCard(holiday)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Holidays Set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add holidays and unavailable days to manage your schedule',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addHoliday,
            icon: const Icon(Icons.add),
            label: const Text('Add Holiday'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(HolidayModel holiday) {
    final isToday = holiday.isToday;
    final isPast = holiday.isPast;
    final isFuture = holiday.isFuture;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday 
            ? Border.all(color: AppTheme.primaryColor, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holiday header
          Row(
            children: [
              Expanded(
                child: Text(
                  holiday.reason,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Date and status
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isToday ? AppTheme.primaryColor : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                holiday.formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: isToday ? AppTheme.primaryColor : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPast 
                      ? Colors.grey[200]
                      : isToday
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPast 
                      ? 'Past'
                      : isToday
                          ? 'Today'
                          : 'Upcoming',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isPast 
                        ? Colors.grey[600]
                        : isToday
                            ? AppTheme.primaryColor
                            : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          
          // Recurring info
          if (holiday.isRecurring) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  'Recurring ${holiday.recurringPattern}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          
          // Actions
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _editHoliday(holiday),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteHoliday(holiday),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addHoliday() {
    showDialog(
      context: context,
      builder: (context) => _HolidayDialog(
        onSave: (holiday) {
          setState(() {
            _holidays.add(holiday);
          });
        },
      ),
    );
  }

  void _editHoliday(HolidayModel holiday) {
    showDialog(
      context: context,
      builder: (context) => _HolidayDialog(
        holiday: holiday,
        onSave: (updatedHoliday) {
          setState(() {
            final index = _holidays.indexWhere((h) => h.id == holiday.id);
            if (index != -1) {
              _holidays[index] = updatedHoliday;
            }
          });
        },
      ),
    );
  }

  void _deleteHoliday(HolidayModel holiday) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "${holiday.reason}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _holidays.removeWhere((h) => h.id == holiday.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HolidayDialog extends StatefulWidget {
  final HolidayModel? holiday;
  final Function(HolidayModel) onSave;

  const _HolidayDialog({
    this.holiday,
    required this.onSave,
  });

  @override
  State<_HolidayDialog> createState() => _HolidayDialogState();
}

class _HolidayDialogState extends State<_HolidayDialog> {
  late DateTime _selectedDate;
  late String _reason;
  late bool _isRecurring;
  late String _recurringPattern;

  @override
  void initState() {
    super.initState();
    if (widget.holiday != null) {
      _selectedDate = widget.holiday!.date;
      _reason = widget.holiday!.reason;
      _isRecurring = widget.holiday!.isRecurring;
      _recurringPattern = widget.holiday!.recurringPattern ?? 'yearly';
    } else {
      _selectedDate = DateTime.now();
      _reason = '';
      _isRecurring = false;
      _recurringPattern = 'yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.holiday != null ? 'Edit Holiday' : 'Add Holiday'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              onTap: _selectDate,
            ),
            
            const SizedBox(height: 16),
            
            // Reason
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              initialValue: _reason,
              onChanged: (value) => _reason = value,
            ),
            
            const SizedBox(height: 16),
            
            // Recurring checkbox
            CheckboxListTile(
              title: const Text('Recurring'),
              subtitle: const Text('Repeat this holiday every year'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveHoliday,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveHoliday() {
    if (_reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }
    
    final holiday = HolidayModel(
      id: widget.holiday?.id ?? 'holiday_${DateTime.now().millisecondsSinceEpoch}',
      astrologerId: 'current_astrologer',
      date: _selectedDate,
      reason: _reason,
      isRecurring: _isRecurring,
      recurringPattern: _isRecurring ? _recurringPattern : null,
      createdAt: widget.holiday?.createdAt ?? DateTime.now(),
    );
    
    widget.onSave(holiday);
    Navigator.pop(context);
  }
}

