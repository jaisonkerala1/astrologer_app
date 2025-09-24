import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/app_restart_service.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentLanguage();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _loadCurrentLanguage() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    setState(() {
      _selectedLanguage = languageService.currentLanguageCode;
    });
    print('LanguageSelectionScreen: Current language loaded: $_selectedLanguage');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeService.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: themeService.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.selectLanguage,
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, themeService),
          const SizedBox(height: 24),
          _buildLanguageOptions(l10n, themeService),
          const SizedBox(height: 32),
          _buildSaveButton(l10n, themeService),
        ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.1),
            themeService.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language,
              size: 32,
              color: themeService.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectLanguage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred language for the app',
            style: TextStyle(
              fontSize: 16,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageOptions(AppLocalizations l10n, ThemeService themeService) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final languages = languageService.getAvailableLanguages();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.availableLanguages,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((language) => _buildLanguageOption(language, themeService)),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(Map<String, String> language, ThemeService themeService) {
    final isSelected = _selectedLanguage == language['code'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedLanguage = language['code']!;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? themeService.primaryColor.withOpacity(0.1)
                  : themeService.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? themeService.primaryColor
                    : themeService.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? themeService.primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  spreadRadius: isSelected ? 1 : 0,
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Flag
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? themeService.primaryColor.withOpacity(0.1)
                        : themeService.borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Language Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['nativeName']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? themeService.primaryColor
                              : themeService.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language['name']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected 
                              ? themeService.primaryColor.withOpacity(0.7)
                              : themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? themeService.primaryColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? themeService.primaryColor
                          : themeService.borderColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, ThemeService themeService) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final hasChanged = _selectedLanguage != languageService.currentLanguageCode;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: hasChanged ? _saveLanguage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasChanged 
                  ? themeService.primaryColor
                  : Colors.grey.withOpacity(0.3),
              foregroundColor: Colors.white,
              elevation: hasChanged ? 4 : 0,
              shadowColor: hasChanged 
                  ? themeService.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasChanged) ...[
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  hasChanged ? l10n.save : l10n.currentLanguage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveLanguage() async {
    try {
      HapticFeedback.mediumImpact();
      
      final languageService = Provider.of<LanguageService>(context, listen: false);
      
      print('LanguageSelectionScreen: Saving language change to $_selectedLanguage');
      await languageService.setLanguage(_selectedLanguage);
      print('LanguageSelectionScreen: Language change completed');
      
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
      print('LanguageSelectionScreen: Error saving language: $e');
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
