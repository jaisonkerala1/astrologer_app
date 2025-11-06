import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/models/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/themes/theme_definitions.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Theme'),
            backgroundColor: themeService.surfaceColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(themeService),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildThemeList(themeService),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Text(
      'Choose your preferred theme',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: themeService.textPrimary,
      ),
    );
  }

  Widget _buildThemeList(ThemeService themeService) {
    return ListView.separated(
      itemCount: ThemeDefinitions.themes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final theme = ThemeDefinitions.themes[index];
        final isSelected = themeService.currentTheme.type == theme.type;
        
        return _buildThemeOption(theme, isSelected, themeService);
      },
    );
  }

  Widget _buildThemeOption(AppTheme theme, bool isSelected, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        themeService.setTheme(theme.type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: themeService.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeService.primaryColor : themeService.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Theme color indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.borderColor,
                  width: 2,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Theme name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: themeService.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.borderColor,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

