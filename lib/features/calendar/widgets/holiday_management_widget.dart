import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/holiday_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import 'dart:convert';

class HolidayManagementWidget extends StatefulWidget {
  const HolidayManagementWidget({super.key});

  @override
  State<HolidayManagementWidget> createState() => _HolidayManagementWidgetState();
}

class _HolidayManagementWidgetState extends State<HolidayManagementWidget> {
  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    // Get astrologer ID and load holidays using BLoC
    try {
      final storageService = StorageService();
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null && mounted) {
          context.read<CalendarBloc>().add(LoadHolidaysEvent(astrologerId));
        }
      }
    } catch (e) {
      print('❌ [HolidayWidget] Error getting astrologer ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            // Show loading skeleton
            if (state is CalendarLoading && state.isInitialLoad) {
              return _buildLoadingSkeleton(themeService);
            }

            // Show error state
            if (state is CalendarErrorState) {
              return _buildErrorState(themeService, state.message);
            }

            // Get holidays from BLoC state
            final holidays = state is CalendarLoadedState 
                ? state.holidays 
                : <HolidayModel>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Holidays & Unavailable Days',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _addHoliday,
                        icon: const Icon(Icons.add_circle_outline),
                        color: themeService.primaryColor,
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 16),
              
                  // Holidays List
                  if (holidays.isEmpty)
                    _buildEmptyState(themeService)
                  else
                    ...holidays.map((holiday) => _buildHolidayCard(holiday, themeService)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: themeService.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading holidays...',
              style: TextStyle(color: themeService.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeService themeService, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: themeService.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error Loading Holidays',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: themeService.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHolidays,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
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
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(HolidayModel holiday, ThemeService themeService) {
    final isToday = holiday.isToday;
    final isPast = holiday.isPast;
    final isFuture = holiday.isFuture;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? themeService.primaryColor.withOpacity(0.1)
            : themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: isToday 
            ? Border.all(color: themeService.primaryColor, width: 1)
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
                child:                   Text(
                    holiday.reason,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isToday ? themeService.primaryColor : themeService.textPrimary,
                    ),
                  ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor,
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
                color: isToday ? themeService.primaryColor : themeService.textSecondary,
              ),
              const SizedBox(width: 8),
                Text(
                  holiday.formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: isToday ? themeService.primaryColor : themeService.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPast 
                      ? themeService.borderColor.withOpacity(0.3)
                      : isToday
                          ? themeService.primaryColor.withOpacity(0.2)
                          : themeService.primaryColor.withOpacity(0.1),
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
                        ? themeService.textSecondary
                        : isToday
                            ? themeService.primaryColor
                            : themeService.primaryColor,
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
                  foregroundColor: themeService.primaryColor,
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
          // Dispatch BLoC event instead of setState
          context.read<CalendarBloc>().add(CreateHolidayEvent(holiday));
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
          // Dispatch BLoC event instead of setState
          context.read<CalendarBloc>().add(
            UpdateHolidayEvent(
              id: holiday.id,
              holiday: updatedHoliday,
            ),
          );
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
              // Dispatch BLoC event instead of setState
              context.read<CalendarBloc>().add(DeleteHolidayEvent(holiday.id));
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

  Future<void> _saveHoliday() async {
    if (_reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }
    
    try {
      // Get astrologer ID from storage
      final storageService = StorageService();
      final userData = await storageService.getUserData();
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get user data. Please login again.')),
          );
        }
        return;
      }

      final userDataMap = jsonDecode(userData);
      final astrologerId = (userDataMap['id'] ?? userDataMap['_id']) as String?;
      
      if (astrologerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get astrologer ID. Please login again.')),
          );
        }
        return;
      }

      final holiday = HolidayModel(
        id: widget.holiday?.id ?? 'holiday_${DateTime.now().millisecondsSinceEpoch}',
        astrologerId: astrologerId,
        date: _selectedDate,
        reason: _reason,
        isRecurring: _isRecurring,
        recurringPattern: _isRecurring ? _recurringPattern : null,
        createdAt: widget.holiday?.createdAt ?? DateTime.now(),
      );
      
      widget.onSave(holiday);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ [HolidayWidget] Error saving holiday: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving holiday: $e')),
        );
      }
    }
  }
}
