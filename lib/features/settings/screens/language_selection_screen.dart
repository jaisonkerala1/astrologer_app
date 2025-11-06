import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/app_restart_service.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    setState(() {
      _selectedLanguage = languageService.currentLanguageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(l10n.selectLanguage),
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
                  child: _buildLanguageList(themeService),
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
      'Choose your preferred language',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: themeService.textPrimary,
      ),
    );
  }

  Widget _buildLanguageList(ThemeService themeService) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final languages = languageService.getAvailableLanguages();
        
        return ListView.separated(
          itemCount: languages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = _selectedLanguage == language['code'];
            
            return _buildLanguageOption(language, isSelected, themeService);
          },
        );
      },
    );
  }

  Widget _buildLanguageOption(Map<String, String> language, bool isSelected, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedLanguage = language['code']!;
        });
        _saveLanguage();
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
            // Language Flag
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getLanguageFlag(language['code']!),
                  style: TextStyle(
                    fontSize: 18,
                    color: themeService.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Language Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeService.textPrimary,
                    ),
                  ),
                  Text(
                    language['nativeName']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Selection Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeService.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'hi':
        return '🇮🇳';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'ru':
        return '🇷🇺';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'zh':
        return '🇨🇳';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌐';
    }
  }

  Future<void> _saveLanguage() async {
    try {
      HapticFeedback.selectionClick();
      
      final languageService = Provider.of<LanguageService>(context, listen: false);
      
      await languageService.setLanguage(_selectedLanguage);
      
      // Restart the app to apply language changes
      RestartWidget.restartApp(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.languageChanged),
            backgroundColor: Provider.of<ThemeService>(context, listen: false).successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Provider.of<ThemeService>(context, listen: false).errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}