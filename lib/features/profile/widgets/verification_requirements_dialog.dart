import 'package:flutter/material.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Dialog showing verification requirements when not met
class VerificationRequirementsDialog extends StatelessWidget {
  final String message;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> current;
  final ThemeService themeService;
  
  const VerificationRequirementsDialog({
    super.key,
    required this.message,
    required this.requirements,
    required this.current,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.orange,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Verification Requirements',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeService.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: themeService.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Requirements list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Experience requirement
                  _buildRequirement(
                    label: 'Platform Experience',
                    isMet: requirements['experience'] ?? false,
                    requiredText: 'At least 6 months on platform',
                    currentText: 'You have: ${_formatMonths(current['monthsOnPlatform'])}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Rating requirement
                  _buildRequirement(
                    label: 'Average Rating',
                    isMet: requirements['rating'] ?? false,
                    requiredText: 'Rating of 4.5 or higher',
                    currentText: 'You have: ${_formatRating(current['avgRating'])}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Consultations requirement
                  _buildRequirement(
                    label: 'Consultations',
                    isMet: requirements['consultations'] ?? false,
                    requiredText: 'At least 50 completed consultations',
                    currentText: 'You have: ${current['consultationsCount'] ?? 0} consultations',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Profile completeness requirement
                  _buildRequirement(
                    label: 'Complete Profile',
                    isMet: requirements['profileComplete'] ?? false,
                    requiredText: 'Bio, awards, and certificates filled',
                    currentText: (requirements['profileComplete'] ?? false) 
                        ? 'Profile is complete' 
                        : 'Please complete your profile',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement({
    required String label,
    required bool isMet,
    required String requiredText,
    required String currentText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isMet 
                ? Colors.green.withOpacity(0.1) 
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMet ? Icons.check : Icons.close,
            size: 16,
            color: isMet ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                requiredText,
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.textSecondary,
                ),
              ),
              Text(
                currentText,
                style: TextStyle(
                  fontSize: 12,
                  color: isMet ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMonths(dynamic months) {
    if (months == null) return '0 months';
    final monthsNum = (months is int) ? months.toDouble() : (months as double);
    if (monthsNum < 1) {
      return '${(monthsNum * 30).toInt()} days';
    }
    return '${monthsNum.toStringAsFixed(1)} months';
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return '0.0';
    final ratingNum = (rating is int) ? rating.toDouble() : (rating as double);
    return ratingNum.toStringAsFixed(1);
  }
}
