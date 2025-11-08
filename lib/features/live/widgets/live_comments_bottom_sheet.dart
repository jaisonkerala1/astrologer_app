import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../utils/gift_helper.dart';

/// Sheet height modes
enum CommentSheetHeight {
  peek,   // 35% - Shows recent comments
  half,   // 60% - Standard browsing
  full,   // 90% - Full screen for typing
}

/// Modern bottom sheet for viewing and managing live comments
/// Inspired by YouTube Live, TikTok, and Instagram Live
/// Supports peek/half/full height modes for better UX
/// Real-time updates via callback function
class LiveCommentsBottomSheet extends StatefulWidget {
  final String streamId;
  final String astrologerName;
  final List<LiveComment> Function() getComments;
  final Function(String) onCommentSend;
  final CommentSheetHeight initialHeight;

  const LiveCommentsBottomSheet({
    super.key,
    required this.streamId,
    required this.astrologerName,
    required this.getComments,
    required this.onCommentSend,
    this.initialHeight = CommentSheetHeight.half,
  });

  @override
  State<LiveCommentsBottomSheet> createState() => _LiveCommentsBottomSheetState();
  
  static Future<void> show(
    BuildContext context, {
    required String streamId,
    required String astrologerName,
    required List<LiveComment> Function() getComments,
    required Function(String) onCommentSend,
    CommentSheetHeight initialHeight = CommentSheetHeight.half,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => LiveCommentsBottomSheet(
        streamId: streamId,
        astrologerName: astrologerName,
        getComments: getComments,
        onCommentSend: onCommentSend,
        initialHeight: initialHeight,
      ),
    );
  }
}

class _LiveCommentsBottomSheetState extends State<LiveCommentsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _commentController;
  late ScrollController _scrollController;
  late CommentSheetHeight _currentHeight;
  late FocusNode _focusNode;
  late Timer _updateTimer;
  List<LiveComment> _comments = [];
  
  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _scrollController = ScrollController();
    _currentHeight = widget.initialHeight;
    _focusNode = FocusNode();
    
    // Get initial comments
    _refreshComments();
    
    // Update every second for real-time feel
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _refreshComments();
      }
    });
    
    // Auto-scroll to bottom when new comments arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    
    // Expand to full when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _currentHeight != CommentSheetHeight.full) {
        setState(() {
          _currentHeight = CommentSheetHeight.full;
        });
      }
    });
  }

  void _refreshComments() {
    setState(() {
      _comments = widget.getComments();
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  double get _sheetHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    switch (_currentHeight) {
      case CommentSheetHeight.peek:
        return screenHeight * 0.35;
      case CommentSheetHeight.half:
        return screenHeight * 0.60;
      case CommentSheetHeight.full:
        return screenHeight * 0.90;
    }
  }
  
  void _toggleHeight() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentHeight == CommentSheetHeight.peek) {
        _currentHeight = CommentSheetHeight.half;
      } else if (_currentHeight == CommentSheetHeight.half) {
        _currentHeight = CommentSheetHeight.full;
      } else {
        _currentHeight = CommentSheetHeight.half;
      }
    });
  }

  void _handleSend() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.selectionClick();
    widget.onCommentSend(text);
    _commentController.clear();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _sheetHeight,
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
                Expanded(child: _buildCommentsList(themeService)),
                _buildCommentInput(themeService),
              ],
            ),
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
          Text(
            'Comments',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_comments.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Height toggle button
          GestureDetector(
            onTap: _toggleHeight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _currentHeight == CommentSheetHeight.peek
                    ? Icons.unfold_more_rounded
                    : _currentHeight == CommentSheetHeight.half
                        ? Icons.fullscreen_rounded
                        : Icons.fullscreen_exit_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Close button
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

  Widget _buildCommentsList(ThemeService themeService) {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No comments yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        return _buildCommentItem(_comments[index], themeService);
      },
    );
  }

  Widget _buildCommentItem(LiveComment comment, ThemeService themeService) {
    // Gift notification - special design with gift-specific colors (minimal and flat)
    if (comment.isGift) {
      final giftName = GiftHelper.extractGiftName(comment.message) ?? 'Star';
      final giftColor = GiftHelper.getGiftColor(giftName);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: giftColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: giftColor.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Gift emoji (extracted from message)
              Text(
                _extractEmoji(comment.message),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              
              // Gift content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(
                            color: giftColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            comment.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Regular comment - minimal flat design
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar - minimal flat design
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Comment content - flat design
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
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

  Widget _buildCommentInput(ThemeService themeService) {
    final hasText = _commentController.text.trim().isNotEmpty;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      cursorColor: themeService.primaryColor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: 1,
                      onSubmitted: (_) => _handleSend(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  // Emoji button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // TODO: Show emoji picker
                    },
                    child: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Send button - flat design
          GestureDetector(
            onTap: hasText ? _handleSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasText
                    ? themeService.primaryColor
                    : Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Extract emoji from gift message (e.g., "🌹 sent Rose" -> "🌹")
  String _extractEmoji(String message) {
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
    
    return '🎁'; // Default gift emoji
  }
}

class LiveComment {
  final String userName;
  final String message;
  final DateTime timestamp;
  final bool isGift;

  LiveComment({
    required this.userName,
    required this.message,
    required this.timestamp,
    this.isGift = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 10) {
      return 'now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }
}

