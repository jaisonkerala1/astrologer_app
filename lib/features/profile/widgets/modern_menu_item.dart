import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

class ModernMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final ThemeService themeService;
  final bool isDanger;

  const ModernMenuItem({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.themeService,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeService.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with circular background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? Colors.red.withOpacity(0.1)
                        : iconBackgroundColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDanger ? Colors.red : iconBackgroundColor,
                  ),
                ),

                const SizedBox(width: 14),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDanger ? Colors.red : themeService.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: themeService.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: themeService.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

