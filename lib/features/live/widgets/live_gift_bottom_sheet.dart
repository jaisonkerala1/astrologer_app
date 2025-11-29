import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/utils/gift_haptics.dart';

/// Modern bottom sheet for sending gifts in live streams
/// Inspired by YouTube, TikTok, and Instagram Live
class LiveGiftBottomSheet extends StatefulWidget {
  final String streamId;
  final String astrologerName;
  final Function(GiftData) onGiftSend;

  const LiveGiftBottomSheet({
    super.key,
    required this.streamId,
    required this.astrologerName,
    required this.onGiftSend,
  });

  @override
  State<LiveGiftBottomSheet> createState() => _LiveGiftBottomSheetState();
  
  static Future<void> show(
    BuildContext context, {
    required String streamId,
    required String astrologerName,
    required Function(GiftData) onGiftSend,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => LiveGiftBottomSheet(
        streamId: streamId,
        astrologerName: astrologerName,
        onGiftSend: onGiftSend,
      ),
    );
  }
}

class _LiveGiftBottomSheetState extends State<LiveGiftBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  GiftData? _selectedGift;
  
  final int _walletBalance = 5000; // Mock balance

  final List<GiftCategory> _categories = [
    GiftCategory(
      name: 'Popular',
      icon: Icons.star,
      gifts: [
        GiftData(name: 'Rose', emoji: '🌹', value: 10, color: Color(0xFFFF4458)),
        GiftData(name: 'Star', emoji: '⭐', value: 25, color: Color(0xFFFFC107)),
        GiftData(name: 'Heart', emoji: '💖', value: 50, color: Color(0xFFE91E63)),
      ],
    ),
    GiftCategory(
      name: 'Premium',
      icon: Icons.diamond,
      gifts: [
        GiftData(name: 'Diamond', emoji: '💎', value: 150, color: Color(0xFF2196F3)),
        GiftData(name: 'Rainbow', emoji: '🌈', value: 300, color: Color(0xFF4CAF50)),
        GiftData(name: 'Crown', emoji: '👑', value: 500, color: Color(0xFF9C27B0)),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleGiftTap(GiftData gift) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedGift == gift) {
        _selectedGift = null;
      } else {
        _selectedGift = gift;
      }
    });
  }

  void _handleSend() async {
    if (_selectedGift == null) return;
    
    // Play gift-specific haptic feedback
    await GiftHaptics.playGiftHaptic(_selectedGift!.name);
    
    widget.onGiftSend(_selectedGift!);
    Navigator.pop(context);
  }

  /// Helper to build gift image or emoji
  Widget _buildGiftImage(String name, String emoji, double size) {
    final giftName = name.toLowerCase();
    final Map<String, String> giftImages = {
      'rose': 'rose.png',
      'star': 'assets/images/star.png',
      'heart': 'assets/images/heart.png',
      'diamond': 'assets/images/diamond.png',
      'rainbow': 'assets/images/rainbow.png',
      'crown': 'assets/images/crown.png',
    };
    
    if (giftImages.containsKey(giftName)) {
      return Image.asset(
        giftImages[giftName]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF0F0F1E),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(themeService),
              _buildWalletInfo(),
              _buildCategoryTabs(themeService),
              Expanded(child: _buildGiftGrid(themeService)),
              _buildSendButton(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Send Gift',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2C2C3E).withOpacity(0.8),
            Color(0xFF1F1F2E).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹$_walletBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              // TODO: Add money
            },
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFFFD700).withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '+ Add',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final animValue = _tabController.animation!.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _categories.length;
              return Stack(
                children: [
                  // Sliding pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: animValue * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeService.primaryColor,
                            themeService.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab labels
                  Row(
                    children: List.generate(_categories.length, (index) {
                      final category = _categories[index];
                      final isSelected = _tabController.index == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _tabController.animateTo(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.icon, 
                                        size: 18,
                                        color: isSelected 
                                            ? Colors.white 
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(category.name),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGiftGrid(ThemeService themeService) {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.78,
          ),
          itemCount: category.gifts.length,
          itemBuilder: (context, index) {
            return _buildGiftItem(category.gifts[index], themeService);
          },
        );
      }).toList(),
    );
  }

  Widget _buildGiftItem(GiftData gift, ThemeService themeService) {
    final isSelected = _selectedGift == gift;
    
    return GestureDetector(
      onTap: () => _handleGiftTap(gift),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? gift.color.withOpacity(0.14)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? gift.color.withOpacity(0.7)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gift.color.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Center all content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: _buildGiftImage(gift.name, gift.emoji, 44),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gift.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? gift.color
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${gift.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: gift.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeService themeService) {
    final hasSelection = _selectedGift != null;
    final totalCost = hasSelection ? _selectedGift!.value : 0;
    final canAfford = hasSelection && totalCost <= _walletBalance;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF1A1A2E).withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Send button - always visible
          GestureDetector(
            onTap: hasSelection && canAfford ? _handleSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: hasSelection && canAfford
                    ? LinearGradient(
                        colors: [
                          _selectedGift!.color,
                          _selectedGift!.color.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: hasSelection
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: hasSelection && canAfford
                    ? [
                        BoxShadow(
                          color: _selectedGift!.color.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasSelection) ...[
                    _buildGiftImage(_selectedGift!.name, _selectedGift!.emoji, 24),
                    const SizedBox(width: 12),
                    Text(
                      'Send ${_selectedGift!.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ₹$totalCost',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.white.withOpacity(0.3),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Select a gift to send',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasSelection && !canAfford)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Insufficient balance. Please add money to wallet.',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GiftData {
  final String name;
  final String emoji;
  final int value;
  final Color color;

  GiftData({
    required this.name,
    required this.emoji,
    required this.value,
    required this.color,
  });
}

class GiftCategory {
  final String name;
  final IconData icon;
  final List<GiftData> gifts;

  GiftCategory({
    required this.name,
    required this.icon,
    required this.gifts,
  });
}

