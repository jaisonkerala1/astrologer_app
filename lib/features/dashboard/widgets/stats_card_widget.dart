import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../../../shared/widgets/transition_animations.dart';

class StatsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return TransitionAnimations.fadeIn(
          duration: const Duration(milliseconds: 300),
          child: onTap != null
              ? Material(
                  color: themeService.cardColor,
                  elevation: 2,
                  borderRadius: themeService.borderRadius,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: themeService.borderRadius,
                    splashColor: color.withOpacity(0.15),
                    highlightColor: color.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: _buildCardContent(context, themeService),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: themeService.borderRadius,
                    boxShadow: [themeService.cardShadow],
                  ),
                  child: _buildCardContent(context, themeService),
                ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            Icon(
              Icons.trending_up,
              color: themeService.successColor,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: themeService.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeService.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}