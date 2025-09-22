import 'package:flutter/material.dart';
import '../models/live_comment_model.dart';
import '../services/live_stream_service.dart';

class LiveCommentsList extends StatefulWidget {
  const LiveCommentsList({super.key});

  @override
  State<LiveCommentsList> createState() => _LiveCommentsListState();
}

class _LiveCommentsListState extends State<LiveCommentsList> {
  final LiveStreamService _liveService = LiveStreamService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _liveService.addListener(_onCommentsUpdated);
  }

  @override
  void dispose() {
    _liveService.removeListener(_onCommentsUpdated);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCommentsUpdated() {
    if (mounted) {
      setState(() {});
      // Auto-scroll to bottom when new comments arrive
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = _liveService.comments;

    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No comments yet\nBe the first to comment!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(LiveCommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: comment.isFromHost
            ? Border.all(color: Colors.red.withOpacity(0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: comment.isFromHost
                  ? Colors.red
                  : Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                comment.userName.isNotEmpty
                    ? comment.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Name and Time
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(
                        color: comment.isFromHost
                            ? Colors.red
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.isFromHost) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                
                // Comment Message
                if (comment.isComment) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.message ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ] else if (comment.isReaction) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getReactionIcon(comment.reaction),
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.userName} reacted',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ] else if (comment.isGift) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (comment.giftIcon != null)
                        Text(
                          comment.giftIcon!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        comment.displayText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.displayText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReactionIcon(LiveReactionType? reaction) {
    switch (reaction) {
      case LiveReactionType.heart:
        return Icons.favorite;
      case LiveReactionType.fire:
        return Icons.local_fire_department;
      case LiveReactionType.clap:
        return Icons.thumb_up;
      case LiveReactionType.laugh:
        return Icons.emoji_emotions;
      case LiveReactionType.wow:
        return Icons.sentiment_satisfied;
      case LiveReactionType.love:
        return Icons.favorite_border;
      case null:
        return Icons.favorite;
    }
  }
}
