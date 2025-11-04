import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../models/consultation_model.dart';
import '../screens/consultation_analytics_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../screens/consultation_detail_screen.dart';
import '../../earnings/screens/earnings_screen.dart';

class ConsultationStatsWidget extends StatelessWidget {
  final int todayCount;
  final double todayEarnings;
  final ConsultationModel? nextConsultation;
  final bool isLoading;

  const ConsultationStatsWidget({
    super.key,
    required this.todayCount,
    required this.todayEarnings,
    required this.nextConsultation,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Today's stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Today',
                      todayCount.toString(),
                      'Consultations',
                      Icons.today,
                      themeService.primaryColor,
                      themeService,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Today',
                      '₹${todayEarnings.toStringAsFixed(0)}',
                      'Earnings',
                      Icons.currency_rupee,
                      themeService.successColor,
                      themeService,
                    ),
                  ),
                ],
              ),
              if (nextConsultation != null) ...[
                const SizedBox(height: 16),
                _buildNextConsultationCard(context, themeService),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    ThemeService themeService,
  ) {
    return Material(
      color: themeService.cardColor,
      elevation: 2,
      borderRadius: themeService.borderRadius,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: isLoading ? null : () {
          _handleCardTap(context, subtitle);
        },
        borderRadius: themeService.borderRadius,
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeService.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                SkeletonLoader(
                  width: 60,
                  height: 28,
                  borderRadius: BorderRadius.circular(4),
                )
              else
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeService.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextConsultationCard(BuildContext context, ThemeService themeService) {
    return Material(
      color: themeService.primaryColor.withOpacity(0.08),
      elevation: 1,
      borderRadius: themeService.borderRadius,
      shadowColor: themeService.primaryColor.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsultationDetailScreen(
                consultation: nextConsultation!,
              ),
            ),
          );
        },
        borderRadius: themeService.borderRadius,
        splashColor: themeService.primaryColor.withOpacity(0.15),
        highlightColor: themeService.primaryColor.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: themeService.borderRadius,
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.2),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: themeService.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Next Consultation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nextConsultation!.clientName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _getTypeIcon(nextConsultation!.type),
                size: 16,
                color: themeService.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                nextConsultation!.type.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeService.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: themeService.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(nextConsultation!.scheduledTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeService.textSecondary,
                ),
              ),
            ],
          ),
        ],
        ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ConsultationType type) {
    switch (type) {
      case ConsultationType.phone:
        return Icons.phone;
      case ConsultationType.video:
        return Icons.videocam;
      case ConsultationType.inPerson:
        return Icons.person;
      case ConsultationType.chat:
        return Icons.chat;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  void _handleCardTap(BuildContext context, String subtitle) {
    if (subtitle == 'Consultations') {
      // Navigate to Calendar module instead of Analytics
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CalendarScreen(),
        ),
      );
    } else if (subtitle == 'Earnings') {
      // Navigate to earnings screen directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EarningsScreen(),
        ),
      );
    }
  }
}
