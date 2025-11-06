import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/consultation_model.dart';

class ConsultationFilterWidget extends StatelessWidget {
  final ConsultationStatus? selectedStatus;
  final Function(ConsultationStatus?) onStatusChanged;
  final VoidCallback onClearFilters;

  const ConsultationFilterWidget({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
    required onClearFilters,
  }) : onClearFilters = onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: 50, // Reduced height for better proportions
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip(
                context,
                'All',
                selectedStatus == null,
                () => onStatusChanged(null),
                themeService,
              ),
              const SizedBox(width: 8),
              ...ConsultationStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    context,
                    status.displayName,
                    selectedStatus == status,
                    () => onStatusChanged(status),
                    themeService,
                    color: Color(int.parse(status.colorCode.substring(1), radix: 16) + 0xFF000000),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (selectedStatus != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onClearFilters();
                  },
                  child: Container(
                    height: 36, // Match other chips
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: themeService.errorColor.withOpacity(0.1),
                      borderRadius: themeService.borderRadius,
                      border: Border.all(
                        color: themeService.errorColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeService.errorColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center( // Center the content
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear,
                            size: 16,
                            color: themeService.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: themeService.errorColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13, // Match other chips
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeService themeService, {
    Color? color,
  }) {
    final chipColor = color ?? themeService.primaryColor;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 36, // Fixed height for consistent alignment
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : themeService.cardColor,
          borderRadius: themeService.borderRadius,
          border: Border.all(
            color: isSelected ? chipColor : themeService.borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: themeService.cardShadow.color,
                    blurRadius: themeService.cardShadow.blurRadius,
                    offset: themeService.cardShadow.offset,
                  ),
                ],
        ),
        child: Center( // Center the text vertically and horizontally
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : themeService.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13, // Slightly larger for better readability
              height: 1.2, // Better line height
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
