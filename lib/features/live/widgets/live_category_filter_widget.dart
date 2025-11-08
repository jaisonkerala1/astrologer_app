import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Minimal, flat category filter widget for live feed
class LiveCategoryFilterWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final VoidCallback onClose;
  
  const LiveCategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClose,
  });
  
  static const List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'value': null},
    {'name': 'Astrology', 'icon': Icons.star, 'value': 'Astrology'},
    {'name': 'Tarot', 'icon': Icons.style, 'value': 'Tarot'},
    {'name': 'Numerology', 'icon': Icons.calculate, 'value': 'Numerology'},
    {'name': 'Palmistry', 'icon': Icons.back_hand, 'value': 'Palmistry'},
    {'name': 'Spiritual', 'icon': Icons.self_improvement, 'value': 'Spiritual'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping the content
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeService.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by Category',
                            style: TextStyle(
                              color: themeService.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onClose();
                            },
                            child: Icon(
                              Icons.close,
                              color: themeService.textSecondary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Category grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategory == category['value'];
                          
                          return _buildCategoryItem(
                            themeService: themeService,
                            name: category['name'] as String,
                            icon: category['icon'] as IconData,
                            value: category['value'] as String?,
                            isSelected: isSelected,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryItem({
    required ThemeService themeService,
    required String name,
    required IconData icon,
    required String? value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onCategorySelected(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? themeService.primaryColor.withOpacity(0.15)
              : themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? themeService.primaryColor
                : themeService.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? themeService.primaryColor
                  : themeService.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected
                    ? themeService.primaryColor
                    : themeService.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

