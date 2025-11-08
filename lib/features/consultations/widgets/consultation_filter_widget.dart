import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/consultation_model.dart';

class ConsultationFilterWidget extends StatelessWidget {
  final ConsultationStatus? selectedStatus;
  final Function(ConsultationStatus?) onStatusChanged;
  final VoidCallback onClearFilters;
  final Map<ConsultationStatus, int> statusCounts;
  final int totalCount;

  const ConsultationFilterWidget({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
    required onClearFilters,
    required this.statusCounts,
    required this.totalCount,
  }) : onClearFilters = onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: 60, // Match heal tab height
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Match heal tab padding
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            border: Border(
              bottom: BorderSide(color: themeService.borderColor),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(
                context,
                'All',
                selectedStatus == null,
                () => onStatusChanged(null),
                themeService,
                count: totalCount,
              ),
              ...ConsultationStatus.values.map(
                (status) => _buildFilterChip(
                  context,
                  status.displayName,
                  selectedStatus == status,
                  () => onStatusChanged(status),
                  themeService,
                  color: Color(int.parse(status.colorCode.substring(1), radix: 16) + 0xFF000000),
                  count: statusCounts[status] ?? 0,
                ),
              ),
              if (selectedStatus != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onClearFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Match heal tab padding
                      decoration: BoxDecoration(
                        color: themeService.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20), // Match heal tab radius
                        border: Border.all(
                          color: themeService.errorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
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
                              fontSize: 15, // Match heal tab font size
                              letterSpacing: 0.2, // Match heal tab
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
    int count = 0,
  }) {
    final chipColor = color ?? themeService.primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(right: 8), // Match heal tab margin
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer( // Match heal tab animation
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Match heal tab padding
          decoration: BoxDecoration(
            color: isSelected ? chipColor : themeService.surfaceColor,
            borderRadius: BorderRadius.circular(20), // Match heal tab radius
            border: Border.all(
              color: isSelected ? chipColor : themeService.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15, // Match heal tab font size
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2, // Match heal tab
                  color: isSelected
                      ? Colors.white
                      : themeService.textPrimary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : chipColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : chipColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
