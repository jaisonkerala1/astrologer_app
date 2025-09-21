import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../consultations/models/consultation_model.dart';
import '../../consultations/services/consultations_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/availability_management_widget.dart';
import '../widgets/holiday_management_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<ConsultationModel> _consultations = [];
  String? _astrologerId;
  bool _isLoading = false;
  final ConsultationsService _consultationsService = ConsultationsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAstrologerId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAstrologerId() async {
    try {
      final userDataString = await StorageService().getUserData();
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['id'] != null) {
          setState(() {
            _astrologerId = userData['id'].toString();
          });
          _loadConsultations();
        }
      }
    } catch (e) {
      print('Error loading astrologer ID: $e');
    }
  }

  Future<void> _loadConsultations() async {
    if (_astrologerId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load consultations from the existing API
      final consultations = await _consultationsService.getConsultations();
      setState(() {
        _consultations = consultations;
      });
    } catch (e) {
      print('Error loading consultations: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load consultations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ConsultationModel> _getConsultationsForDate(DateTime date) {
    return _consultations.where((consultation) {
      final consultationDate = DateTime(
        consultation.scheduledTime.year,
        consultation.scheduledTime.month,
        consultation.scheduledTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return consultationDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  void _showConsultationDetails(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consultation.clientName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${consultation.clientPhone}'),
            Text('Time: ${_formatTime(consultation.scheduledTime)}'),
            Text('Duration: ${consultation.duration} minutes'),
            Text('Type: ${consultation.type.displayName}'),
            Text('Status: ${consultation.status.displayName}'),
            if (consultation.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${consultation.notes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Calendar & Scheduling',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today, size: 20)),
            Tab(text: 'Availability', icon: Icon(Icons.schedule, size: 20)),
            Tab(text: 'Holidays', icon: Icon(Icons.event_busy, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildAvailabilityTab(),
          _buildHolidaysTab(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return RefreshIndicator(
      onRefresh: _loadConsultations,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Widget
            CalendarWidget(
              consultations: _consultations,
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              onConsultationSelected: (consultation) {
                _showConsultationDetails(consultation);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return const AvailabilityManagementWidget();
  }

  Widget _buildHolidaysTab() {
    return const HolidayManagementWidget();
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Add Availability',
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.event_busy,
                  label: 'Add Holiday',
                  onTap: () {
                    _tabController.animateTo(2);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
