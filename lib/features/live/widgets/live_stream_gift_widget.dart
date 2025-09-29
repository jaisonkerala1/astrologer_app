import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_gift_model.dart';
import '../services/live_stream_service.dart';

class LiveStreamGiftWidget extends StatefulWidget {
  final String liveStreamId;
  final VoidCallback onClose;

  const LiveStreamGiftWidget({
    super.key,
    required this.liveStreamId,
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

  Future<void> _sendGift(GiftItem gift) async {
    HapticFeedback.mediumImpact();
    
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
            content: Text('Sent ${gift.emoji} ${gift.name}'),
            backgroundColor: gift.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send gift: $e')),
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
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Send Gifts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
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
                                    Text(
                                      gift.giftEmoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
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
      onTap: () => _sendGift(gift),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animationController.value * 0.1),
            child: Container(
              decoration: BoxDecoration(
                color: gift.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gift.color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gift.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${gift.value}',
                    style: TextStyle(
                      color: gift.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
















