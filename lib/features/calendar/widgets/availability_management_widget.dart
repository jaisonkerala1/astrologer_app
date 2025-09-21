import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/availability_model.dart';

class AvailabilityManagementWidget extends StatefulWidget {
  const AvailabilityManagementWidget({super.key});

  @override
  State<AvailabilityManagementWidget> createState() => _AvailabilityManagementWidgetState();
}

class _AvailabilityManagementWidgetState extends State<AvailabilityManagementWidget> {
  List<AvailabilityModel> _availability = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from API
      _generateSampleAvailability();
    } catch (e) {
      print('Error loading availability: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateSampleAvailability() {
    final availability = <AvailabilityModel>[];
    
    // Generate availability for Monday to Friday
    for (int day = 1; day <= 5; day++) {
      availability.add(AvailabilityModel(
        id: 'avail_$day',
        astrologerId: 'current_astrologer',
        dayOfWeek: day,
        startTime: '09:00',
        endTime: '18:00',
        isActive: true,
        breaks: [
          BreakTime(
            startTime: '13:00',
            endTime: '14:00',
            reason: 'Lunch Break',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    setState(() {
      _availability = availability;
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
                  'Your Availability',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _addAvailability,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Availability List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availability.isEmpty)
            _buildEmptyState()
          else
            ..._availability.map((avail) => _buildAvailabilityCard(avail)),
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
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(AvailabilityModel availability) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: availability.isActive,
                onChanged: (value) => _toggleAvailability(availability, value),
                activeColor: AppTheme.primaryColor,
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
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '${availability.startTime} - ${availability.endTime}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
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
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${breakTime.startTime} - ${breakTime.endTime} (${breakTime.reason})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteAvailability(availability),
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

  void _addAvailability() {
    showDialog(
      context: context,
      builder: (context) => _AvailabilityDialog(
        onSave: (availability) {
          setState(() {
            _availability.add(availability);
          });
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
          setState(() {
            final index = _availability.indexWhere((a) => a.id == availability.id);
            if (index != -1) {
              _availability[index] = updatedAvailability;
            }
          });
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
              setState(() {
                _availability.removeWhere((a) => a.id == availability.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(AvailabilityModel availability, bool isActive) {
    setState(() {
      final index = _availability.indexWhere((a) => a.id == availability.id);
      if (index != -1) {
        _availability[index] = availability.copyWith(isActive: isActive);
      }
    });
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

