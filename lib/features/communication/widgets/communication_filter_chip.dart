import 'package:flutter/material.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/communication_item.dart';

/// Minimal, beautiful filter chip for communication types
class CommunicationFilterChip extends StatelessWidget {
  final CommunicationFilter filter;
  final bool isActive;
  final int count;
  final VoidCallback onTap;
  final ThemeService themeService;

  const CommunicationFilterChip({
    super.key,
    required this.filter,
    required this.isActive,
    required this.count,
    required this.onTap,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? themeService.primaryColor 
              : themeService.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? themeService.primaryColor 
                : themeService.borderColor,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: themeService.primaryColor.withOpacity(0.3),
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
              filter.label,
              style: TextStyle(
                color: isActive 
                    ? Colors.white 
                    : themeService.textPrimary,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Colors.white.withOpacity(0.25) 
                      : themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isActive 
                        ? Colors.white 
                        : themeService.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


