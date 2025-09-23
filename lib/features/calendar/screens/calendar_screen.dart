import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/transition_animations.dart';
import '../../../shared/widgets/custom_refresh_indicator.dart';
import '../../../shared/widgets/simple_shimmer.dart';
import '../../consultations/models/consultation_model.dart';
import '../../consultations/services/consultations_service.dart';
import '../../consultations/screens/consultation_detail_screen.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/calendar_skeleton_widget.dart';
import '../widgets/simple_calendar_skeleton.dart';
import '../widgets/availability_management_widget.dart';
import '../widgets/holiday_management_widget.dart';
import '../models/calendar_loading_state.dart';

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
  CalendarLoadingModel _loadingState = CalendarLoadingModel.initial();
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
    setState(() {
      _loadingState = CalendarLoadingModel.loading(CalendarLoadingState.loadingAstrologerId);
    });

    try {
      final userDataString = await StorageService().getUserData();
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['id'] != null) {
          setState(() {
            _astrologerId = userData['id'].toString();
          });
          _loadConsultations();
        } else {
          setState(() {
            _loadingState = CalendarLoadingModel.error('User ID not found');
          });
        }
      } else {
        setState(() {
          _loadingState = CalendarLoadingModel.error('User data not found');
        });
      }
    } catch (e) {
      setState(() {
        _loadingState = CalendarLoadingModel.error('Error loading profile: ${e.toString()}');
      });
    }
  }

  Future<void> _loadConsultations() async {
    if (_astrologerId == null) return;
    
    setState(() {
      _loadingState = CalendarLoadingModel.loading(CalendarLoadingState.loadingConsultations);
    });

    try {
      // Load consultations from the existing API
      final consultations = await _consultationsService.getConsultations();
      setState(() {
        _consultations = consultations;
        _loadingState = CalendarLoadingModel.loaded();
      });
    } catch (e) {
      setState(() {
        _loadingState = CalendarLoadingModel.error('Failed to load consultations: ${e.toString()}');
      });
    }
  }

  Future<void> _refreshConsultations() async {
    if (_astrologerId == null) return;
    
    setState(() {
      _loadingState = CalendarLoadingModel.refreshing();
    });

    try {
      final consultations = await _consultationsService.getConsultations();
      setState(() {
        _consultations = consultations;
        _loadingState = CalendarLoadingModel.loaded();
      });
    } catch (e) {
      setState(() {
        _loadingState = CalendarLoadingModel.error('Failed to refresh consultations: ${e.toString()}');
      });
    }
  }

  void _retryLoading() {
    if (_astrologerId == null) {
      _loadAstrologerId();
    } else {
      _loadConsultations();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationDetailScreen(
          consultation: consultation,
        ),
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
        title: Row(
          children: [
            const Text(
              'Calendar & Scheduling',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_loadingState.state == CalendarLoadingState.refreshing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          if (_loadingState.isLoading && _loadingState.state != CalendarLoadingState.refreshing)
            Container(
              padding: const EdgeInsets.all(16),
              child: const LoadingIndicator(
                size: 20,
                color: Colors.white,
                message: null,
                showMessage: false,
              ),
            ),
        ],
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
    return CustomRefreshIndicator(
      onRefresh: _refreshConsultations,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Widget with Loading States
            _buildCalendarContent(),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    // Show error state
    if (_loadingState.hasError) {
      return Container(
        height: 400,
        child: ErrorStateWidget(
          title: 'Unable to Load Calendar',
          message: _loadingState.errorMessage ?? 'Something went wrong',
          onRetry: _retryLoading,
          icon: Icons.calendar_today,
          iconColor: Colors.orange,
        ),
      );
    }

    // Show skeleton while loading
    if (_loadingState.isLoading) {
      return const SimpleCalendarSkeleton(
        showConsultations: true,
        enabled: true,
      );
    }

    // Show real calendar when loaded
    return CalendarWidget(
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
