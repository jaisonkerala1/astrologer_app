import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

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
  int _selectedQuantity = 1;
  
  final int _walletBalance = 5000; // Mock balance

  final List<GiftCategory> _categories = [
    GiftCategory(
      name: 'Popular',
      icon: Icons.star,
      gifts: [
        GiftData(name: 'Rose', emoji: '🌹', value: 10, color: Color(0xFFFF4458)),
        GiftData(name: 'Star', emoji: '⭐', value: 25, color: Color(0xFFFFC107)),
        GiftData(name: 'Heart', emoji: '💖', value: 50, color: Color(0xFFE91E63)),
        GiftData(name: 'Crown', emoji: '👑', value: 100, color: Color(0xFF9C27B0)),
      ],
    ),
    GiftCategory(
      name: 'Premium',
      icon: Icons.diamond,
      gifts: [
        GiftData(name: 'Diamond', emoji: '💎', value: 200, color: Color(0xFF2196F3)),
        GiftData(name: 'Rocket', emoji: '🚀', value: 500, color: Color(0xFFFF5722)),
        GiftData(name: 'Rainbow', emoji: '🌈', value: 1000, color: Color(0xFF4CAF50)),
        GiftData(name: 'Trophy', emoji: '🏆', value: 2000, color: Color(0xFFFFD700)),
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
        _selectedQuantity = 1;
      } else {
        _selectedGift = gift;
        _selectedQuantity = 1;
      }
    });
  }

  void _handleSend() {
    if (_selectedGift == null) return;
    
    HapticFeedback.mediumImpact();
    widget.onGiftSend(_selectedGift!);
    Navigator.pop(context);
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
              if (_selectedGift != null) _buildSendButton(themeService),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Support ${widget.astrologerName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
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
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeService.primaryColor,
              themeService.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        tabs: _categories.map((category) {
          return Tab(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 20),
                const SizedBox(width: 8),
                Text(category.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGiftGrid(ThemeService themeService) {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
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
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gift.color.withOpacity(0.4),
                    gift.color.withOpacity(0.2),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? gift.color.withOpacity(0.8)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gift.color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Text(
                        gift.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
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
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? gift.color
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₹${gift.value}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
    if (_selectedGift == null) return const SizedBox.shrink();
    
    final totalCost = _selectedGift!.value * _selectedQuantity;
    final canAfford = totalCost <= _walletBalance;

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
          // Quantity selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (_selectedQuantity > 1) {
                          setState(() => _selectedQuantity--);
                        }
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_selectedQuantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        if (_selectedQuantity < 99) {
                          setState(() => _selectedQuantity++);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Send button
          GestureDetector(
            onTap: canAfford ? _handleSend : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: canAfford
                    ? LinearGradient(
                        colors: [
                          _selectedGift!.color,
                          _selectedGift!.color.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.5),
                          Colors.grey.withOpacity(0.3),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: canAfford
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
                  Text(
                    _selectedGift!.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
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
                ],
              ),
            ),
          ),
          if (!canAfford)
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

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
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

