import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/custom_refresh_indicator.dart';
import '../../consultations/models/consultation_model.dart';
import '../../consultations/screens/consultation_detail_screen.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/simple_calendar_skeleton.dart';
import '../widgets/availability_management_widget.dart';
import '../widgets/holiday_management_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load calendar data for the entire current month (not just today)
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    context.read<CalendarBloc>().add(
      LoadConsultationsForDateRangeEvent(
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final themeService = Provider.of<ThemeService>(context);
    
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
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
                if (state is CalendarLoading && !state.isInitialLoad) ...[
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
            backgroundColor: themeService.primaryColor,
            elevation: 0,
            actions: [
              if (state is CalendarLoading && state.isInitialLoad)
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
              _buildCalendarTab(state),
              _buildAvailabilityTab(state),
              _buildHolidaysTab(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab(CalendarState state) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return CustomRefreshIndicator(
      onRefresh: () async {
        context.read<CalendarBloc>().add(const RefreshCalendarEvent());
        // Wait a bit for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Widget with Loading States
            _buildCalendarContent(state),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(themeService),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent(CalendarState state) {
    // Show error state
    if (state is CalendarErrorState) {
      return SizedBox(
        height: 400,
        child: ErrorStateWidget(
          title: 'Unable to Load Calendar',
          message: state.message,
          onRetry: () {
            context.read<CalendarBloc>().add(LoadConsultationsForDateEvent(DateTime.now()));
          },
          icon: Icons.calendar_today,
          iconColor: Colors.orange,
        ),
      );
    }

    // Show skeleton while loading
    if (state is CalendarLoading && state.isInitialLoad) {
      return const SimpleCalendarSkeleton(
        showConsultations: true,
        enabled: true,
      );
    }

    // Show real calendar when loaded
    if (state is CalendarLoadedState) {
      return CalendarWidget(
        consultations: state.consultations,
        selectedDate: state.selectedDate,
        onDateSelected: (date) {
          context.read<CalendarBloc>().add(ChangeSelectedDateEvent(date));
        },
        onConsultationSelected: (consultation) {
          _showConsultationDetails(consultation);
        },
      );
    }

    // Show skeleton as fallback
    return const SimpleCalendarSkeleton(
      showConsultations: true,
      enabled: true,
    );
  }

  Widget _buildAvailabilityTab(CalendarState state) {
    // For now, availability widget manages its own state
    // We'll migrate it in Phase 2
    return const AvailabilityManagementWidget();
  }

  Widget _buildHolidaysTab(CalendarState state) {
    // For now, holiday widget manages its own state
    // We'll migrate it in Phase 3
    return const HolidayManagementWidget();
  }

  Widget _buildQuickActions(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
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
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
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
                  themeService: themeService,
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
                  themeService: themeService,
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
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: themeService.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: themeService.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: themeService.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
