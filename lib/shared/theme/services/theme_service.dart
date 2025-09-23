import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';
import '../themes/theme_definitions.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppTheme _currentTheme = ThemeDefinitions.getDefaultTheme();
  bool _isInitialized = false;

  AppTheme get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      
      if (themeIndex >= 0 && themeIndex < ThemeDefinitions.themes.length) {
        _currentTheme = ThemeDefinitions.themes[themeIndex];
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _currentTheme = ThemeDefinitions.getDefaultTheme();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType themeType) async {
    if (_currentTheme.type == themeType) return;
    
    try {
      _currentTheme = ThemeDefinitions.getThemeByType(themeType);
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = ThemeDefinitions.themes.indexWhere(
        (theme) => theme.type == themeType,
      );
      await prefs.setInt(_themeKey, themeIndex);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> setThemeByIndex(int index) async {
    if (index < 0 || index >= ThemeDefinitions.themes.length) return;
    
    final theme = ThemeDefinitions.themes[index];
    await setTheme(theme.type);
  }

  AppTheme getThemeByType(AppThemeType type) {
    return ThemeDefinitions.getThemeByType(type);
  }

  List<AppTheme> get allThemes => ThemeDefinitions.themes;

  bool isDarkMode() {
    return _currentTheme.type == AppThemeType.dark;
  }

  bool isVedicMode() {
    return _currentTheme.type == AppThemeType.vedic;
  }


  bool isLightMode() {
    return _currentTheme.type == AppThemeType.light;
  }

  // Helper methods for common theme operations
  Color get primaryColor => _currentTheme.primaryColor;
  Color get secondaryColor => _currentTheme.secondaryColor;
  Color get accentColor => _currentTheme.accentColor;
  Color get backgroundColor => _currentTheme.backgroundColor;
  Color get surfaceColor => _currentTheme.surfaceColor;
  Color get cardColor => _currentTheme.cardColor;
  Color get textPrimary => _currentTheme.textPrimary;
  Color get textSecondary => _currentTheme.textSecondary;
  Color get textHint => _currentTheme.textHint;
  Color get borderColor => _currentTheme.borderColor;
  Color get errorColor => _currentTheme.errorColor;
  Color get successColor => _currentTheme.successColor;
  Color get warningColor => _currentTheme.warningColor;
  Color get infoColor => _currentTheme.infoColor;
  Gradient get primaryGradient => _currentTheme.primaryGradient;
  Gradient get backgroundGradient => _currentTheme.backgroundGradient;
  BoxShadow get cardShadow => _currentTheme.cardShadow;
  BorderRadius get borderRadius => _currentTheme.borderRadius;
}
