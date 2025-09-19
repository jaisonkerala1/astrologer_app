import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
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
                color: Color(int.parse(status.colorCode.substring(1), radix: 16) + 0xFF000000),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (selectedStatus != null)
            GestureDetector(
              onTap: onClearFilters,
              child: Container(
                height: 36, // Match other chips
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18), // Match other chips
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
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
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
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
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36, // Fixed height for consistent alignment
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(18), // More rounded
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.textColor.withOpacity(0.2),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Center( // Center the text vertically and horizontally
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textColor,
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
