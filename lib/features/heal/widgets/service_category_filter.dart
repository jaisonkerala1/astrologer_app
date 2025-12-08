import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/generic_sliding_filter_chips.dart';
import '../models/service_model.dart';

class ServiceCategoryFilter extends StatelessWidget {
  final List<ServiceCategory> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const ServiceCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Build filter items
        final filters = <FilterItem>[
          const FilterItem(key: 'all', label: 'All', icon: '📋'),
          ...categories.map((cat) => FilterItem(
            key: cat.id,
            label: cat.name,
            icon: cat.icon,
            iconPath: cat.iconPath, // Pass iconPath for image support
          )),
        ];

        return GenericSlidingFilterChips(
          filters: filters,
          selectedKey: selectedCategory,
          themeService: themeService,
          onFilterTap: onCategorySelected,
        );
      },
    );
  }
}



















































