import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_card_widget.dart';

class ConsultationAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String period;
  final List<ConsultationModel> consultations;

  const ConsultationAnalyticsWidget({
    super.key,
    required this.stats,
    required this.period,
    required this.consultations,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final totalConsultations = stats['totalConsultations'] ?? 0;
        final totalEarnings = stats['totalEarnings'] ?? 0.0;
        final completedConsultations = stats['completedConsultations'] ?? 0;
        final cancelledConsultations = stats['cancelledConsultations'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(themeService),
              const SizedBox(height: 24),
              
              // Main Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Consultations',
                      totalConsultations.toString(),
                      Icons.event_note,
                      themeService.primaryColor,
                      themeService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Earnings',
                      '₹${totalEarnings.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      themeService.successColor,
                      themeService,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status Breakdown Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Completed',
                      completedConsultations.toString(),
                      Icons.check_circle,
                      themeService.successColor,
                      themeService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Cancelled',
                      cancelledConsultations.toString(),
                      Icons.cancel,
                      themeService.errorColor,
                      themeService,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Period Summary Card
              _buildPeriodSummaryCard(context, themeService),
              
              const SizedBox(height: 24),
              
              // Consultations List Section
              _buildConsultationsSection(context, themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    String title = '';
    String subtitle = '';
    
    switch (period) {
      case 'week':
        title = 'This Week';
        subtitle = 'Consultation summary for the current week';
        break;
      case 'month':
        title = 'This Month';
        subtitle = 'Consultation summary for the current month';
        break;
      case 'all':
        title = 'All Time';
        subtitle = 'Total consultation statistics';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: themeService.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeService themeService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummaryCard(BuildContext context, ThemeService themeService) {
    final totalConsultations = stats['totalConsultations'] ?? 0;
    final totalEarnings = stats['totalEarnings'] ?? 0.0;
    final averageEarningsPerConsultation = totalConsultations > 0 
        ? totalEarnings / totalConsultations 
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
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
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: themeService.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            'Total Consultations',
            totalConsultations.toString(),
            themeService,
          ),
          _buildSummaryRow(
            'Total Earnings',
            '₹${totalEarnings.toStringAsFixed(0)}',
            themeService,
          ),
          _buildSummaryRow(
            'Average per Consultation',
            '₹${averageEarningsPerConsultation.toStringAsFixed(0)}',
            themeService,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsSection(BuildContext context, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.event_note,
              color: themeService.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Consultations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${consultations.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeService.primaryColor,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Consultations List
        if (consultations.isEmpty)
          _buildEmptyState(context, themeService)
        else
          _buildConsultationsList(context, themeService),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeService themeService) {
    String emptyMessage = '';
    String emptySubtitle = '';
    
    switch (period) {
      case 'week':
        emptyMessage = 'No consultations this week';
        emptySubtitle = 'Consultations scheduled for this week will appear here';
        break;
      case 'month':
        emptyMessage = 'No consultations this month';
        emptySubtitle = 'Consultations scheduled for this month will appear here';
        break;
      case 'all':
        emptyMessage = 'No consultations yet';
        emptySubtitle = 'Your consultation history will appear here';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 48,
            color: themeService.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            emptySubtitle,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList(BuildContext context, ThemeService themeService) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: consultations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return ConsultationCardWidget(
          key: ValueKey(consultation.id),
          consultation: consultation,
          onStart: () => _handleStartConsultation(context, consultation.id),
          onComplete: () => _handleCompleteConsultation(context, consultation),
          onCancel: () => _handleCancelConsultation(context, consultation.id),
        );
      },
    );
  }

  void _handleStartConsultation(BuildContext context, String consultationId) {
    HapticFeedback.lightImpact();
    // TODO: Implement start consultation logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting consultation...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCompleteConsultation(BuildContext context, ConsultationModel consultation) {
    HapticFeedback.lightImpact();
    // TODO: Implement complete consultation logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completing consultation with ${consultation.clientName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCancelConsultation(BuildContext context, String consultationId) {
    HapticFeedback.mediumImpact();
    // TODO: Implement cancel consultation logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cancelling consultation...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
