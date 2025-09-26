import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../consultations/services/consultations_service.dart';
import '../../consultations/models/consultation_model.dart';

class CalendarCardWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const CalendarCardWidget({
    super.key,
    this.onTap,
  });

  @override
  State<CalendarCardWidget> createState() => _CalendarCardWidgetState();
}

class _CalendarCardWidgetState extends State<CalendarCardWidget> {
  final ConsultationsService _consultationsService = ConsultationsService();
  int _todayBookings = 0;
  int _upcomingBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultationData();
  }

  Future<void> _loadConsultationData() async {
    try {
      final todayConsultations = await _consultationsService.getTodaysConsultations();
      final upcomingConsultations = await _consultationsService.getUpcomingConsultations(limit: 10);
      
      setState(() {
        _todayBookings = todayConsultations.length;
        _upcomingBookings = upcomingConsultations.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading consultation data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: widget.onTap ?? () => _navigateToCalendar(context),
            borderRadius: BorderRadius.circular(16),
            splashColor: themeService.primaryColor.withOpacity(0.12),
            highlightColor: themeService.primaryColor.withOpacity(0.08),
            hoverColor: themeService.primaryColor.withOpacity(0.04),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeService.primaryColor.withOpacity(0.1),
                    themeService.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.primaryColor.withOpacity(0.2),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: themeService.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar & Scheduling',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeService.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your availability',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: themeService.textSecondary,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _isLoading 
                          ? _buildSkeletonStatItem()
                          : _buildStatItem(
                              icon: Icons.today_rounded,
                              label: 'Today',
                              value: _todayBookings.toString(),
                              color: Colors.orange,
                              themeService: themeService,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isLoading 
                          ? _buildSkeletonStatItem()
                          : _buildStatItem(
                              icon: Icons.schedule_rounded,
                              label: 'Upcoming',
                              value: _upcomingBookings.toString(),
                              color: Colors.blue,
                              themeService: themeService,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonStatItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 20,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                width: 30,
                height: 18,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              SkeletonLoader(
                width: 50,
                height: 11,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeService themeService,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _navigateToCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }
}
