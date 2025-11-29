import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/generic_sliding_filter_chips.dart';
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
        // Build filter items
        final filters = <FilterItem>[
          FilterItem(key: 'all', label: 'All', count: totalCount),
          ...ConsultationStatus.values.map((status) => FilterItem(
            key: status.name,
            label: status.displayName,
            count: statusCounts[status] ?? 0,
            color: Color(int.parse(status.colorCode.substring(1), radix: 16) + 0xFF000000),
          )),
        ];

        // Build clear button if filter is active
        Widget? clearButton;
        if (selectedStatus != null) {
          clearButton = GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onClearFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: themeService.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
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
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GenericSlidingFilterChips(
          filters: filters,
          selectedKey: selectedStatus?.name ?? 'all',
          themeService: themeService,
          onFilterTap: (key) {
            if (key == 'all') {
              onStatusChanged(null);
            } else {
              final status = ConsultationStatus.values.firstWhere(
                (s) => s.name == key,
                orElse: () => ConsultationStatus.scheduled,
              );
              onStatusChanged(status);
            }
          },
          trailing: clearButton,
        );
      },
    );
  }
}
