import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

class LiveStreamCategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const LiveStreamCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16), // Start from exact left position like search bar
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8), // Space between tabs
                child: _buildCategoryTab(
                  context,
                  themeService,
                  category,
                  isSelected,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab(
    BuildContext context,
    ThemeService themeService,
    String category,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onCategorySelected(category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeService.primaryColor 
              : themeService.surfaceColor,
          borderRadius: BorderRadius.circular(30), // More rounded like YouTube
          border: isSelected ? null : Border.all(
            color: themeService.borderColor,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: themeService.primaryColor.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon
            _getCategoryIcon(category, isSelected, themeService),
            
            const SizedBox(width: 6),
            
            // Category name
            Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : themeService.textPrimary,
                fontWeight: isSelected 
                    ? FontWeight.w500 
                    : FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category, bool isSelected, ThemeService themeService) {
    IconData iconData;
    Color iconColor = isSelected ? Colors.white : themeService.textSecondary;
    
    switch (category.toLowerCase()) {
      case 'all':
        iconData = Icons.live_tv;
        break;
      case 'vedic':
        iconData = Icons.auto_awesome;
        break;
      case 'tarot':
        iconData = Icons.casino;
        break;
      case 'numerology':
        iconData = Icons.numbers;
        break;
      case 'palmistry':
        iconData = Icons.pan_tool;
        break;
      case 'crystal':
        iconData = Icons.diamond;
        break;
      case 'vastu':
        iconData = Icons.home;
        break;
      case 'astrology':
        iconData = Icons.star;
        break;
      default:
        iconData = Icons.category;
    }
    
    return Icon(
      iconData,
      size: 18,
      color: iconColor,
    );
  }
}
