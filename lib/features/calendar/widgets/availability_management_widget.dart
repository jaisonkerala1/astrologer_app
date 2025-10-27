import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/availability_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import 'dart:convert';

class AvailabilityManagementWidget extends StatefulWidget {
  const AvailabilityManagementWidget({super.key});

  @override
  State<AvailabilityManagementWidget> createState() => _AvailabilityManagementWidgetState();
}

class _AvailabilityManagementWidgetState extends State<AvailabilityManagementWidget> {
  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    // Get astrologer ID and load availability using BLoC
    try {
      final storageService = StorageService();
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null && mounted) {
          context.read<CalendarBloc>().add(LoadAvailabilityEvent(astrologerId));
        }
      }
    } catch (e) {
      print('❌ [AvailabilityWidget] Error getting astrologer ID: $e');
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

            // Get availabilities from BLoC state
            final availabilities = state is CalendarLoadedState 
                ? state.availabilities 
                : <AvailabilityModel>[];

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
                          'Your Availability',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _addAvailability,
                        icon: const Icon(Icons.add_circle_outline),
                        color: themeService.primaryColor,
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 16),
              
                  // Availability List
                  if (availabilities.isEmpty)
                    _buildEmptyState(themeService)
                  else
                    ...availabilities.map((avail) => _buildAvailabilityCard(avail, themeService)),
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
              'Loading availability...',
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
              'Error Loading Availability',
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
              onPressed: _loadAvailability,
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
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Availability Set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your working hours to start receiving bookings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addAvailability,
            icon: const Icon(Icons.add),
            label: const Text('Add Availability'),
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

  Widget _buildAvailabilityCard(AvailabilityModel availability, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          // Day header
          Row(
            children: [
              Expanded(
                child: Text(
                  availability.dayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: availability.isActive,
                onChanged: (value) => _toggleAvailability(availability, value),
                activeColor: themeService.primaryColor,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Time range
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: themeService.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${availability.startTime} - ${availability.endTime}',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Breaks
          if (availability.breaks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...availability.breaks.map((breakTime) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    size: 14,
                    color: themeService.textSecondary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${breakTime.startTime} - ${breakTime.endTime} (${breakTime.reason})',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          // Actions
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _editAvailability(availability),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: themeService.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteAvailability(availability),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: themeService.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addAvailability() {
    showDialog(
      context: context,
      builder: (context) => _AvailabilityDialog(
        onSave: (availability) {
          // Dispatch BLoC event instead of setState
          context.read<CalendarBloc>().add(CreateAvailabilityEvent(availability));
        },
      ),
    );
  }

  void _editAvailability(AvailabilityModel availability) {
    showDialog(
      context: context,
      builder: (context) => _AvailabilityDialog(
        availability: availability,
        onSave: (updatedAvailability) {
          // Dispatch BLoC event instead of setState
          context.read<CalendarBloc>().add(
            UpdateAvailabilityEvent(
              id: availability.id,
              availability: updatedAvailability,
            ),
          );
        },
      ),
    );
  }

  void _deleteAvailability(AvailabilityModel availability) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Availability'),
        content: Text('Are you sure you want to delete availability for ${availability.dayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Dispatch BLoC event instead of setState
              context.read<CalendarBloc>().add(DeleteAvailabilityEvent(availability.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(AvailabilityModel availability, bool isActive) {
    // Dispatch BLoC event instead of setState
    final updatedAvailability = availability.copyWith(isActive: isActive);
    context.read<CalendarBloc>().add(
      UpdateAvailabilityEvent(
        id: availability.id,
        availability: updatedAvailability,
      ),
    );
  }
}

class _AvailabilityDialog extends StatefulWidget {
  final AvailabilityModel? availability;
  final Function(AvailabilityModel) onSave;

  const _AvailabilityDialog({
    this.availability,
    required this.onSave,
  });

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  late int _selectedDay;
  late String _startTime;
  late String _endTime;
  final List<BreakTime> _breaks = [];

  @override
  void initState() {
    super.initState();
    if (widget.availability != null) {
      _selectedDay = widget.availability!.dayOfWeek;
      _startTime = widget.availability!.startTime;
      _endTime = widget.availability!.endTime;
      _breaks.addAll(widget.availability!.breaks);
    } else {
      _selectedDay = 1; // Monday
      _startTime = '09:00';
      _endTime = '18:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.availability != null ? 'Edit Availability' : 'Add Availability'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day selection
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day of Week',
                border: OutlineInputBorder(),
              ),
              items: List.generate(7, (index) {
                const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                return DropdownMenuItem(
                  value: index,
                  child: Text(days[index]),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Time selection
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _startTime,
                    onChanged: (value) => _startTime = value,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _endTime,
                    onChanged: (value) => _endTime = value,
                  ),
                ),
              ],
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
          onPressed: _saveAvailability,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveAvailability() {
    final availability = AvailabilityModel(
      id: widget.availability?.id ?? 'avail_${DateTime.now().millisecondsSinceEpoch}',
      astrologerId: 'current_astrologer',
      dayOfWeek: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      isActive: true,
      breaks: _breaks,
      createdAt: widget.availability?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(availability);
    Navigator.pop(context);
  }
}
