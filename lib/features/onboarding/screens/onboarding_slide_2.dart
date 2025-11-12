import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/device_mockup_widget.dart';
import '../widgets/astroguru_chat_mockup.dart';

/// Second onboarding slide - AstroGuru healing platform introduction
/// Shows a device mockup with chat interface and detailed feature description
/// Content only - navigation handled by parent
class OnboardingSlide2 extends StatefulWidget {
  final double bottomPadding;

  const OnboardingSlide2({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  State<OnboardingSlide2> createState() => _OnboardingSlide2State();
}

class _OnboardingSlide2State extends State<OnboardingSlide2>
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
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
              left: 24,
              right: 24,
              top: 32,
              bottom: widget.bottomPadding + 16,
            ),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64), // Spacing to maintain mockup position
                    
                    // Device mockup
                    Center(
                      child: DeviceMockupWidget(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                        borderColor: const Color(0xFF404040),
                        child: const AstroGuruChatMockup(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content section
                    Text(
                      AppLocalizations.of(context)!.onboardingAstroGuruTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      AppLocalizations.of(context)!.onboardingAstroGuruDescription,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Learn more link
                    GestureDetector(
                      onTap: () {
                        // Could open a web link or show more info
                      },
                      child: Text(
                        AppLocalizations.of(context)!.learnMore,
                        style: const TextStyle(
                          color: Color(0xFF89B4F8),
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF89B4F8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Instruction card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.howToHelpOthers,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep(context, 1, AppLocalizations.of(context)!.helpStep1),
                          _buildInstructionStep(context, 2, AppLocalizations.of(context)!.helpStep2),
                          _buildInstructionStep(context, 3, AppLocalizations.of(context)!.helpStep3),
                          _buildInstructionStep(context, 4, AppLocalizations.of(context)!.helpStep4),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer disclaimer
                    Text(
                      AppLocalizations.of(context)!.astroGuruDisclaimer,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

