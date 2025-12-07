import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/services/theme_service.dart';
import '../../theme/models/app_theme.dart';
import 'empty_state_widget.dart';
import 'illustrations/healing_empty_illustration.dart';
import 'illustrations/consultation_empty_illustration.dart';
import 'illustrations/communication_empty_illustration.dart';
import 'illustrations/calls_empty_illustration.dart';
import 'illustrations/video_call_empty_illustration.dart';
import '../network_tower_illustration.dart';

/// Gallery screen to preview all empty states
/// Swiggy-style: Beautiful showcase with theme switcher
/// 
/// Features:
/// - Preview all 3 empty states
/// - Switch between themes in real-time
/// - Beautiful cards with labels
/// - Smooth animations
class EmptyStateGalleryScreen extends StatefulWidget {
  const EmptyStateGalleryScreen({super.key});

  @override
  State<EmptyStateGalleryScreen> createState() => _EmptyStateGalleryScreenState();
}

class _EmptyStateGalleryScreenState extends State<EmptyStateGalleryScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Empty States Gallery',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: themeService.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Theme switcher
          PopupMenuButton<AppThemeType>(
            icon: Icon(
              themeService.currentTheme.icon,
              color: Colors.white,
            ),
            onSelected: (themeType) {
              themeService.setTheme(themeType);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppThemeType.light,
                child: Row(
                  children: const [
                    Icon(Icons.light_mode, size: 20),
                    SizedBox(width: 12),
                    Text('Light Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppThemeType.dark,
                child: Row(
                  children: const [
                    Icon(Icons.dark_mode, size: 20),
                    SizedBox(width: 12),
                    Text('Dark Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppThemeType.vedic,
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 12),
                    Text('Vedic Mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Theme indicator banner
          _buildThemeBanner(themeService),
          
          // Tab indicators
          _buildTabIndicators(themeService),
          
          // Empty states carousel
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'Healing Empty State',
                  description: 'Shown when no service requests are available',
                  widget: EmptyStateWidget(
                    illustration: HealingEmptyIllustration(
                      themeService: themeService,
                    ),
                    title: 'No Service Requests',
                    message: 'Your healing journey awaits!\nWhen clients request services, they\'ll appear here.',
                    themeService: themeService,
                  ),
                ),
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'Consultation Empty State',
                  description: 'Shown when no consultations are scheduled',
                  widget: EmptyStateWidget(
                    illustration: ConsultationEmptyIllustration(
                      themeService: themeService,
                    ),
                    title: 'No Consultations Yet',
                    message: 'Your cosmic calendar is clear!\nNew consultations will shine here when booked.',
                    themeService: themeService,
                  ),
                ),
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'Communication Empty State (All/Messages)',
                  description: 'Shown when no messages exist',
                  widget: EmptyStateWidget(
                    illustration: CommunicationEmptyIllustration(
                      themeService: themeService,
                    ),
                    title: 'No Conversations',
                    message: 'Your inbox is quiet for now!\nMessages and calls will appear here.',
                    themeService: themeService,
                  ),
                ),
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'Calls Empty State',
                  description: 'Shown when no voice calls exist',
                  widget: EmptyStateWidget(
                    illustration: CallsEmptyIllustration(
                      themeService: themeService,
                    ),
                    title: 'No Voice Calls',
                    message: 'Ready to connect!\nYour call history will show up here.',
                    themeService: themeService,
                  ),
                ),
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'Video Call Empty State',
                  description: 'Shown when no video calls exist',
                  widget: EmptyStateWidget(
                    illustration: VideoCallEmptyIllustration(
                      themeService: themeService,
                    ),
                    title: 'No Video Calls',
                    message: 'Face-to-face consultations!\nVideo call history will display here.',
                    themeService: themeService,
                  ),
                ),
                _buildEmptyStatePreview(
                  themeService: themeService,
                  title: 'No Internet Connection State',
                  description: 'Shown when user loses internet connectivity',
                  widget: EmptyStateWidget(
                    illustration: const NetworkTowerIllustration(
                      size: 200,
                    ),
                    title: 'No Internet Connection',
                    message: 'Please check your WiFi or mobile data\nand try again.',
                    themeService: themeService,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation dots
          _buildPageIndicators(themeService),
        ],
      ),
    );
  }

  Widget _buildThemeBanner(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeService.primaryColor.withOpacity(0.1),
            themeService.accentColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            themeService.currentTheme.icon,
            size: 18,
            color: themeService.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Current Theme: ${themeService.currentTheme.name}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Tap icon to switch',
              style: TextStyle(
                fontSize: 11,
                color: themeService.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIndicators(ThemeService themeService) {
    final tabs = [
      {'icon': Icons.healing, 'label': 'Healing'},
      {'icon': Icons.calendar_today, 'label': 'Consult'},
      {'icon': Icons.chat_bubble, 'label': 'Chat'},
      {'icon': Icons.phone, 'label': 'Calls'},
      {'icon': Icons.videocam, 'label': 'Video'},
      {'icon': Icons.wifi_off, 'label': 'Offline'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedIndex == index;
            final tab = tabs[index];
            
            return Padding(
              padding: EdgeInsets.only(right: index < tabs.length - 1 ? 12 : 0),
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 20 : 16,
                    vertical: isSelected ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeService.primaryColor
                        : themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? themeService.primaryColor
                          : themeService.borderColor,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeService.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: isSelected ? 20 : 18,
                        color: isSelected
                            ? Colors.white
                            : themeService.textSecondary,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          tab['label'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyStatePreview({
    required ThemeService themeService,
    required String title,
    required String description,
    required Widget widget,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeService.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: themeService.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: themeService.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: themeService.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview card with shadow - Fixed height to avoid nested scroll issues
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isActive = _selectedIndex == index;
          
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? themeService.primaryColor
                    : themeService.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

