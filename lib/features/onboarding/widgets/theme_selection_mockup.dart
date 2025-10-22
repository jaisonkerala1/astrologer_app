import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/models/app_theme.dart';

/// Theme selection mockup for onboarding
/// Interactive mockup where users can select Light, Dark, or Vedic theme
class ThemeSelectionMockup extends StatefulWidget {
  final AppThemeType selectedTheme;
  final Function(AppThemeType) onThemeSelected;

  const ThemeSelectionMockup({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  State<ThemeSelectionMockup> createState() => _ThemeSelectionMockupState();
}

class _ThemeSelectionMockupState extends State<ThemeSelectionMockup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎨',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'थीम',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Theme',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 24),
          
          // Theme options (vertical list like language selection)
          _buildThemeOption(
            themeType: AppThemeType.light,
            icon: '☀️',
            primaryText: AppLocalizations.of(context)!.lightTheme,
            secondaryText: 'Bright & Clean',
            accentColor: const Color(0xFF4285F4),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildThemeOption(
            themeType: AppThemeType.dark,
            icon: '🌙',
            primaryText: AppLocalizations.of(context)!.darkTheme,
            secondaryText: 'Easy on Eyes',
            accentColor: const Color(0xFF8AB4F8),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildThemeOption(
            themeType: AppThemeType.vedic,
            icon: '🕉️',
            primaryText: AppLocalizations.of(context)!.vedicTheme,
            secondaryText: 'Spiritual',
            accentColor: const Color(0xFFFF9933),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.2, end: 0),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeType themeType,
    required String icon,
    required String primaryText,
    required String secondaryText,
    required Color accentColor,
  }) {
    final isSelected = widget.selectedTheme == themeType;
    
    return GestureDetector(
      onTap: () => widget.onThemeSelected(themeType),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? accentColor.withOpacity(0.15)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? accentColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? accentColor
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected 
                    ? accentColor
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Icon
            Text(
              icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            // Theme text (removed secondary text)
            Expanded(
              child: Text(
                primaryText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

