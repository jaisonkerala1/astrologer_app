import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class ThemeDefinitions {
  static const List<AppTheme> themes = [
    _lightTheme,
    _darkTheme,
    _vedicTheme,
  ];

  static const AppTheme _lightTheme = AppTheme(
    type: AppThemeType.light,
    name: 'Light Mode',
    description: 'Clean and bright interface',
    primaryColor: Color(0xFF1E40AF), // Original blue
    secondaryColor: Color(0xFF3B82F6), // Blue variant
    accentColor: Color(0xFF06B6D4), // Cyan
    backgroundColor: Color(0xFFFAFAFA), // Light gray
    surfaceColor: Color(0xFFFFFFFF), // White
    cardColor: Color(0xFFFFFFFF), // White
    textPrimary: Color(0xFF1F2937), // Dark gray
    textSecondary: Color(0xFF6B7280), // Medium gray
    textHint: Color(0xFF9CA3AF), // Light gray
    borderColor: Color(0xFFE5E7EB), // Very light gray
    errorColor: Color(0xFFEF4444), // Red
    successColor: Color(0xFF10B981), // Green
    warningColor: Color(0xFFF59E0B), // Amber
    infoColor: Color(0xFF3B82F6), // Blue
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)], // Original blue gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardShadow: BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
    icon: Icons.light_mode,
  );

  static const AppTheme _darkTheme = AppTheme(
    type: AppThemeType.dark,
    name: 'Dark Mode',
    description: 'Minimal dark interface',
    primaryColor: Color(0xFF8B5CF6), // Purple
    secondaryColor: Color(0xFF06B6D4), // Cyan
    accentColor: Color(0xFF10B981), // Green
    backgroundColor: Color(0xFF0F0F0F), // Very dark
    surfaceColor: Color(0xFF1A1A1A), // Dark gray
    cardColor: Color(0xFF262626), // Darker gray
    textPrimary: Color(0xFFF9FAFB), // Light gray
    textSecondary: Color(0xFFD1D5DB), // Medium light gray
    textHint: Color(0xFF9CA3AF), // Gray
    borderColor: Color(0xFF374151), // Dark border
    errorColor: Color(0xFFEF4444), // Red
    successColor: Color(0xFF10B981), // Green
    warningColor: Color(0xFFF59E0B), // Amber
    infoColor: Color(0xFF3B82F6), // Blue
    primaryGradient: LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF374151)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardShadow: BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
    icon: Icons.dark_mode,
  );

  static const AppTheme _vedicTheme = AppTheme(
    type: AppThemeType.vedic,
    name: 'Vedic Mode',
    description: 'Sacred saffron and spiritual colors',
    primaryColor: Color(0xFFD97706), // Saffron
    secondaryColor: Color(0xFFB45309), // Dark saffron
    accentColor: Color(0xFFF59E0B), // Golden
    backgroundColor: Color(0xFFFFF7ED), // Cream
    surfaceColor: Color(0xFFFFFBF5), // Light cream
    cardColor: Color(0xFFFFFFFF), // White
    textPrimary: Color(0xFF451A03), // Dark brown
    textSecondary: Color(0xFF92400E), // Brown
    textHint: Color(0xFFA16207), // Light brown
    borderColor: Color(0xFFFED7AA), // Light saffron
    errorColor: Color(0xFFDC2626), // Red
    successColor: Color(0xFF059669), // Green
    warningColor: Color(0xFFD97706), // Saffron
    infoColor: Color(0xFF2563EB), // Blue
    primaryGradient: LinearGradient(
      colors: [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF92400E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFFFF7ED), Color(0xFFFFFBF5), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardShadow: BoxShadow(
      color: Color(0x1AD97706),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    icon: Icons.temple_hindu,
  );


  static AppTheme getThemeByType(AppThemeType type) {
    return themes.firstWhere((theme) => theme.type == type);
  }

  static AppTheme getDefaultTheme() {
    return _lightTheme;
  }
}
