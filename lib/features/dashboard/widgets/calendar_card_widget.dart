import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../calendar/screens/calendar_screen.dart';

class CalendarCardWidget extends StatelessWidget {
  final int todayBookings;
  final int upcomingBookings;
  final VoidCallback? onTap;

  const CalendarCardWidget({
    super.key,
    required this.todayBookings,
    required this.upcomingBookings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToCalendar(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
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
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calendar & Scheduling',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your availability',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.today_rounded,
                    label: 'Today',
                    value: todayBookings.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.schedule_rounded,
                    label: 'Upcoming',
                    value: upcomingBookings.toString(),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add_rounded,
                    label: 'Set Availability',
                    onTap: () => _navigateToCalendar(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.event_busy_rounded,
                    label: 'Add Holiday',
                    onTap: () => _navigateToCalendar(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
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
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
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
