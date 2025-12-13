import 'package:flutter/material.dart';
import '../models/live_comment_model.dart';
import '../utils/gift_helper.dart';

/// Live Floating Comments Widget
/// Displays last 4-5 comments with animations (Instagram/TikTok style)
class LiveFloatingCommentsWidget extends StatelessWidget {
  final List<LiveCommentModel> comments;
  final VoidCallback onTap;
  
  const LiveFloatingCommentsWidget({
    super.key,
    required this.comments,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 16,
      right: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: comments.asMap().entries.map((entry) {
          final index = entry.key;
          final comment = entry.value;
          final opacity = 1.0 - ((comments.length - 1 - index) * 0.15);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CommentBubble(
              key: ValueKey(comment.id),
              comment: comment,
              opacity: opacity,
              onTap: onTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual Comment Bubble with Animation
class _CommentBubble extends StatefulWidget {
  final LiveCommentModel comment;
  final double opacity;
  final VoidCallback onTap;
  
  const _CommentBubble({
    super.key,
    required this.comment,
    required this.opacity,
    required this.onTap,
  });
  
  @override
  State<_CommentBubble> createState() => _CommentBubbleState();
}

class _CommentBubbleState extends State<_CommentBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value * widget.opacity,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.comment.isGift
                ? _getGiftColor(widget.comment).withOpacity(0.15)
                : Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.comment.isGift
                  ? _getGiftColor(widget.comment).withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              width: widget.comment.isGift ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gift emoji for gift notifications
              if (widget.comment.isGift) ...[
                Text(
                  _extractGiftEmoji(widget.comment.message),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.comment.userName} ',
                        style: TextStyle(
                          color: widget.comment.isGift
                              ? _getGiftColor(widget.comment)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextSpan(
                        text: widget.comment.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get gift color from message
  Color _getGiftColor(LiveCommentModel comment) {
    final giftName = GiftHelper.extractGiftName(comment.message);
    if (giftName != null) {
      return GiftHelper.getGiftColor(giftName);
    }
    return Colors.amber;
  }
  
  /// Extract emoji from gift message
  String _extractGiftEmoji(String message) {
    final emojiMap = {
      'rose': '🌹',
      'star': '⭐',
      'heart': '💖',
      'diamond': '💎',
      'rainbow': '🌈',
      'crown': '👑',
    };
    
    for (final entry in emojiMap.entries) {
      if (message.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If emoji is already in the message, extract it
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
    final match = emojiRegex.firstMatch(message);
    if (match != null) {
      return match.group(0) ?? '🎁';
    }
    
    return '💬'; // Default comment emoji
  }
}

