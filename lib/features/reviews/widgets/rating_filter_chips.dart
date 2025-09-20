import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class RatingFilterChips extends StatelessWidget {
  final int? selectedRating;
  final bool showNeedsReplyOnly;
  final Function(int?) onRatingSelected;
  final Function(bool) onNeedsReplyToggle;

  const RatingFilterChips({
    Key? key,
    required this.selectedRating,
    required this.showNeedsReplyOnly,
    required this.onRatingSelected,
    required this.onNeedsReplyToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Reviews Chip
          _buildFilterChip(
            label: 'All',
            isSelected: selectedRating == null && !showNeedsReplyOnly,
            onTap: () {
              onRatingSelected(null);
              onNeedsReplyToggle(false);
            },
          ),
          const SizedBox(width: 8),
          
          // Needs Reply Chip
          _buildFilterChip(
            label: 'Needs Reply',
            isSelected: showNeedsReplyOnly,
            onTap: () {
              onNeedsReplyToggle(!showNeedsReplyOnly);
              if (showNeedsReplyOnly) {
                onRatingSelected(null);
              }
            },
            icon: Icons.reply,
          ),
          const SizedBox(width: 8),
          
          // Rating Filter Chips
          ...List.generate(5, (index) {
            int rating = 5 - index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: '$rating Star${rating > 1 ? 's' : ''}',
                isSelected: selectedRating == rating,
                onTap: () {
                  onRatingSelected(selectedRating == rating ? null : rating);
                  onNeedsReplyToggle(false);
                },
                icon: Icons.star,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
