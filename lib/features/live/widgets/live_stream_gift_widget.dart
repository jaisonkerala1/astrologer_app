import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_gift_model.dart';
import '../services/live_stream_service.dart';
import '../utils/gift_helper.dart';

class LiveStreamGiftWidget extends StatefulWidget {
  final String liveStreamId;
  final String astrologerName;
  final VoidCallback onClose;

  const LiveStreamGiftWidget({
    super.key,
    required this.liveStreamId,
    required this.astrologerName,
    required this.onClose,
  });

  @override
  State<LiveStreamGiftWidget> createState() => _LiveStreamGiftWidgetState();
}

class _LiveStreamGiftWidgetState extends State<LiveStreamGiftWidget>
    with TickerProviderStateMixin {
  final LiveStreamService _liveStreamService = LiveStreamService();
  List<LiveGiftModel> _gifts = [];
  bool _isLoading = false;
  late AnimationController _animationController;

  final List<GiftItem> _availableGifts = [
    GiftItem(name: 'Rose', emoji: '🌹', value: 10, color: Colors.red),
    GiftItem(name: 'Star', emoji: '⭐', value: 25, color: Colors.amber),
    GiftItem(name: 'Heart', emoji: '💖', value: 50, color: Colors.pink),
    GiftItem(name: 'Crown', emoji: '👑', value: 100, color: Colors.purple),
    GiftItem(name: 'Diamond', emoji: '💎', value: 200, color: Colors.blue),
    GiftItem(name: 'Rocket', emoji: '🚀', value: 500, color: Colors.orange),
    GiftItem(name: 'Rainbow', emoji: '🌈', value: 1000, color: Colors.green),
    GiftItem(name: 'Trophy', emoji: '🏆', value: 2000, color: Colors.yellow),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadGifts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gifts = await _liveStreamService.getGifts(widget.liveStreamId);
      if (mounted) {
        setState(() {
          _gifts = gifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showGiftConfirmation(GiftItem gift) async {
    HapticFeedback.selectionClick();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            GiftHelper.buildGiftImage(gift.name, gift.emoji, 64),
            const SizedBox(height: 12),
            Text(
              'Send ${gift.name}?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To: ${widget.astrologerName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: gift.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gift.color,
                  width: 2,
                ),
              ),
              child: Text(
                '₹${gift.value}',
                style: TextStyle(
                  color: gift.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: gift.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GiftHelper.buildGiftImage(gift.name, gift.emoji, 20),
              ],
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _sendGift(gift);
    }
  }

  Future<void> _sendGift(GiftItem gift) async {
    HapticFeedback.selectionClick();
    
    try {
      final giftModel = LiveGiftModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        streamId: widget.liveStreamId,
        userId: 'current_user',
        userName: 'You',
        giftName: gift.name,
        giftEmoji: gift.emoji,
        giftValue: gift.value,
        timestamp: DateTime.now(),
      );
      
      await _liveStreamService.sendGift(widget.liveStreamId, giftModel);
      await _loadGifts();
      
      // Show animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                GiftHelper.buildGiftImage(gift.name, gift.emoji, 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sent ${gift.name} to ${widget.astrologerName}!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: gift.color,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Close gift panel after sending
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send gift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeService.primaryColor.withOpacity(0.2),
                      themeService.secondaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber,
                                Colors.orange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Send a Gift',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Support ${widget.astrologerName}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Gifts grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _availableGifts.length,
                          itemBuilder: (context, index) {
                            final gift = _availableGifts[index];
                            return _buildGiftButton(gift, themeService);
                          },
                        ),
                      ),
              ),
              
              // Recent gifts
              if (_gifts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Gifts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _gifts.take(5).length,
                          itemBuilder: (context, index) {
                            final gift = _gifts[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GiftHelper.buildGiftImage(gift.giftName, gift.giftEmoji, 16),
                                    const SizedBox(width: 6),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gift.userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${gift.giftEmoji} ${gift.giftName}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftButton(GiftItem gift, ThemeService themeService) {
    return GestureDetector(
      onTap: () => _showGiftConfirmation(gift),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animationController.value * 0.1),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gift.color.withOpacity(0.3),
                    gift.color.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: gift.color.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gift.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GiftHelper.buildGiftImage(gift.name, gift.emoji, 42),
                  const SizedBox(height: 6),
                  Text(
                    gift.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: gift.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${gift.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GiftItem {
  final String name;
  final String emoji;
  final int value;
  final Color color;

  GiftItem({
    required this.name,
    required this.emoji,
    required this.value,
    required this.color,
  });
}
















