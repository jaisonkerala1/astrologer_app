import 'package:flutter/material.dart';
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
            title: const Text('Theme Settings'),
            backgroundColor: themeService.surfaceColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeService.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(themeService),
                  const SizedBox(height: 24),
                  _buildThemeGrid(themeService),
                  const SizedBox(height: 32),
                  _buildPreviewSection(themeService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Theme',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a theme that matches your style and preferences',
          style: TextStyle(
            fontSize: 16,
            color: themeService.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeGrid(ThemeService themeService) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: ThemeDefinitions.themes.length,
      itemBuilder: (context, index) {
        final theme = ThemeDefinitions.themes[index];
        final isSelected = themeService.currentTheme.type == theme.type;
        
        return _buildThemeCard(theme, isSelected, themeService);
      },
    );
  }

  Widget _buildThemeCard(AppTheme theme, bool isSelected, ThemeService themeService) {
    return GestureDetector(
      onTap: () => themeService.setTheme(theme.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            theme.cardShadow,
            if (isSelected)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: theme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  theme.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              
              // Theme Name
              Text(
                theme.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              
              // Theme Description
              Text(
                theme.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Color Palette Preview
              _buildColorPalette(theme),
              const SizedBox(height: 12),
              
              // Selection Indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette(AppTheme theme) {
    return Row(
      children: [
        _buildColorDot(theme.primaryColor),
        const SizedBox(width: 4),
        _buildColorDot(theme.secondaryColor),
        const SizedBox(width: 4),
        _buildColorDot(theme.accentColor),
        const SizedBox(width: 4),
        _buildColorDot(theme.backgroundColor),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildPreviewSection(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildPreviewCard(themeService),
      ],
    );
  }

  Widget _buildPreviewCard(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        border: Border.all(color: themeService.borderColor),
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: themeService.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeService.textPrimary,
                      ),
                    ),
                    Text(
                      'This is how your app will look',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Preview Content
          Text(
            'This theme provides a beautiful and consistent design experience across your astrologer app.',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Preview Buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Primary Button'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeService.primaryColor,
                  side: BorderSide(color: themeService.primaryColor),
                ),
                child: const Text('Secondary Button'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


