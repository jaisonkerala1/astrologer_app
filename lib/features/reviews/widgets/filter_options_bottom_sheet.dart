import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';

class FilterOptionsBottomSheet extends StatefulWidget {
  final int? selectedRating;
  final bool showNeedsReplyOnly;
  final String selectedSort;
  final Function(int?, bool, String) onApply;

  const FilterOptionsBottomSheet({
    Key? key,
    required this.selectedRating,
    required this.showNeedsReplyOnly,
    required this.selectedSort,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterOptionsBottomSheet> createState() => _FilterOptionsBottomSheetState();
}

class _FilterOptionsBottomSheetState extends State<FilterOptionsBottomSheet> {
  late int? _selectedRating;
  late bool _showNeedsReplyOnly;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.selectedRating;
    _showNeedsReplyOnly = widget.showNeedsReplyOnly;
    _selectedSort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Rating Filter
          const Text(
            'Filter by Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildRatingChip('All', null),
              ...List.generate(5, (index) {
                int rating = 5 - index;
                return _buildRatingChip('$rating Star${rating > 1 ? 's' : ''}', rating);
              }),
            ],
          ),
          const SizedBox(height: 20),
          
          // Needs Reply Filter
          Row(
            children: [
              Checkbox(
                value: _showNeedsReplyOnly,
                onChanged: (value) {
                  setState(() {
                    _showNeedsReplyOnly = value ?? false;
                    if (_showNeedsReplyOnly) {
                      _selectedRating = null;
                    }
                  });
                },
              ),
              const Text('Show only reviews that need reply'),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sort Options
          const Text(
            'Sort by',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...['newest', 'oldest', 'rating_high', 'rating_low'].map((sort) {
            return RadioListTile<String>(
              title: Text(_getSortLabel(sort)),
              value: sort,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
          
          const SizedBox(height: 20),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onApply(_selectedRating, _showNeedsReplyOnly, _selectedSort);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(String label, int? rating) {
    final isSelected = _selectedRating == rating;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = isSelected ? null : rating;
          if (rating != null) {
            _showNeedsReplyOnly = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'rating_high':
        return 'Highest Rating';
      case 'rating_low':
        return 'Lowest Rating';
      default:
        return sort;
    }
  }
}
