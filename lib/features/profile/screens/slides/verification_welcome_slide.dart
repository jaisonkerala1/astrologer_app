import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/services/theme_service.dart';
import '../../../../shared/widgets/verification_badge.dart';
import '../../../auth/models/astrologer_model.dart';

/// Welcome slide for verification flow - shows benefits and requirements
class VerificationWelcomeSlide extends StatefulWidget {
  final AstrologerModel astrologer;
  final bool isResubmission;

  const VerificationWelcomeSlide({
    super.key,
    required this.astrologer,
    this.isResubmission = false,
  });

  @override
  State<VerificationWelcomeSlide> createState() => _VerificationWelcomeSlideState();
}

class _VerificationWelcomeSlideState extends State<VerificationWelcomeSlide>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _autoScrollController;
  late Animation<double> _scrollAnimation;
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoScrollController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start auto-scroll after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  Future<void> _startAutoScroll() async {
    // Wait for user to see top content
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted || _hasAutoScrolled || !_scrollController.hasClients) return;

    // Check if content is scrollable
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 50) return; // Not enough content to scroll

    // Calculate scroll distance (30% of content or max 200px)
    final targetScroll = (maxScroll * 0.3).clamp(100.0, 200.0);

    // Create scroll animation
    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: targetScroll,
    ).animate(CurvedAnimation(
      parent: _autoScrollController,
      curve: Curves.easeInOutCubic,
    ));

    _scrollAnimation.addListener(_scrollListener);

    // Animate down
    await _autoScrollController.forward();

    // Small pause
    await Future.delayed(const Duration(milliseconds: 400));

    // Animate back up
    if (mounted) {
      await _autoScrollController.reverse();
    }

    _hasAutoScrolled = true;
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollAnimation.value);
    }
  }

  void _onUserScroll() {
    // Stop auto-scroll if user manually scrolls
    if (_autoScrollController.isAnimating) {
      _autoScrollController.stop();
      _scrollAnimation.removeListener(_scrollListener);
      _hasAutoScrolled = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollController.dispose();
    _scrollAnimation.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Responsive sizing
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenHeight < 700;
        final horizontalPadding = screenWidth > 600 ? 48.0 : 24.0;

        return SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) {
                _onUserScroll();
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: isSmallScreen ? 24 : 40,
                bottom: 120, // Space for navigation
              ),
              child: Column(
              children: [
                // Badge Icon - Minimal & Clean
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 28),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: VerificationBadge(
                    size: isSmallScreen ? 44 : 52,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 28 : 36),

                // Title - Larger & Bolder
                Text(
                  widget.isResubmission
                      ? 'Re-submit Verification'
                      : 'Become a Verified\nAstrologer',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 32,
                    fontWeight: FontWeight.w700,
                    color: themeService.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Subtitle
                Text(
                  'Build trust and credibility with your clients',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 17,
                    color: themeService.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isSmallScreen ? 32 : 40),

                // Rejection reason (if resubmission)
                if (widget.isResubmission &&
                    widget.astrologer.verificationRejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Previous Rejection Reason',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.astrologer.verificationRejectionReason!,
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
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],

                // Why Get Verified?
                _buildBenefitsCard(themeService, isSmallScreen),

                SizedBox(height: isSmallScreen ? 28 : 36),

                // What You'll Need
                _buildRequirementsCard(themeService, isSmallScreen),

                SizedBox(height: isSmallScreen ? 28 : 36),

                // Time estimate - Minimal info badges
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: isSmallScreen ? 16 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: themeService.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '2-3 minutes',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          color: themeService.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: themeService.textSecondary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.verified_user_rounded,
                        size: 18,
                        color: themeService.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '24-48 hours review',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          color: themeService.textPrimary,
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
      },
    );
  }

  Widget _buildBenefitsCard(ThemeService themeService, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Why Get Verified?',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        // Benefits Grid
        _buildBenefitItem(
          Icons.verified_rounded,
          'Build Trust',
          'Verified badge shows you\'re authenticated',
          themeService,
          isSmallScreen,
        ),
        _buildBenefitItem(
          Icons.trending_up_rounded,
          'Higher Visibility',
          'Rank higher in search results',
          themeService,
          isSmallScreen,
        ),
        _buildBenefitItem(
          Icons.people_rounded,
          'More Bookings',
          'Clients prefer verified astrologers',
          themeService,
          isSmallScreen,
        ),
        _buildBenefitItem(
          Icons.workspace_premium_rounded,
          'Professional Badge',
          'Show commitment to quality',
          themeService,
          isSmallScreen,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    ThemeService themeService,
    bool isSmallScreen, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : (isSmallScreen ? 12 : 14)),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
      decoration: BoxDecoration(
        color: themeService.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: themeService.primaryColor,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: themeService.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(ThemeService themeService, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'What You\'ll Need',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        // Requirements List
        _buildRequirementItem(
          Icons.badge_outlined,
          'Government ID Proof',
          true,
          themeService,
          isSmallScreen,
        ),
        _buildRequirementItem(
          Icons.workspace_premium_outlined,
          'Astrology Certificate',
          false,
          themeService,
          isSmallScreen,
        ),
        _buildRequirementItem(
          Icons.store_outlined,
          'Storefront/Workspace Photo',
          false,
          themeService,
          isSmallScreen,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildRequirementItem(
    IconData icon,
    String title,
    bool isRequired,
    ThemeService themeService,
    bool isSmallScreen, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : (isSmallScreen ? 10 : 12)),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 18,
        vertical: isSmallScreen ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeService.primaryColor,
            size: isSmallScreen ? 20 : 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w500,
                color: themeService.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isRequired
                  ? Colors.red.withOpacity(0.08)
                  : themeService.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isRequired ? Colors.red.shade700 : themeService.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

