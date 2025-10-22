import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Language selection mockup for onboarding
/// Interactive mockup where users can select English or Hindi
class LanguageSelectionMockup extends StatefulWidget {
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectionMockup({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionMockup> createState() => _LanguageSelectionMockupState();
}

class _LanguageSelectionMockupState extends State<LanguageSelectionMockup> {
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
                '🌐',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'भाषा',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Language',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 32),
          
          // Language options
          _buildLanguageOption(
            languageCode: 'en',
            primaryText: 'English',
            secondaryText: 'Default',
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 16),
          
          _buildLanguageOption(
            languageCode: 'hi',
            primaryText: 'हिंदी',
            secondaryText: 'Hindi',
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: -0.2, end: 0),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String languageCode,
    required String primaryText,
    required String secondaryText,
  }) {
    final isSelected = widget.selectedLanguage == languageCode;
    
    return GestureDetector(
      onTap: () => widget.onLanguageSelected(languageCode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4285F4).withOpacity(0.15)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF4285F4)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF4285F4)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected 
                    ? const Color(0xFF4285F4)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Language text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    secondaryText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

