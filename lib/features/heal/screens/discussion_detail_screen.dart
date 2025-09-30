import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../services/discussion_service.dart';
import '../models/discussion_models.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final DiscussionPost post;

  const DiscussionDetailScreen({super.key, required this.post});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<DiscussionComment> _comments = [];
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await DiscussionService.getComments(widget.post.id);
    if (comments.isEmpty) {
      _loadSampleComments();
    } else {
      setState(() {
        _comments.addAll(comments);
      });
    }
  }

  void _loadSampleComments() {
    // Sample comments for demonstration
    setState(() {
      _comments.addAll([
        DiscussionComment(
          id: '1',
          discussionId: widget.post.id,
          author: 'sarah',
          authorInitial: 'S',
          content: 'This is really helpful! I\'ve been looking for this information.',
          timeAgo: '2 hours ago',
          likes: 5,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        DiscussionComment(
          id: '2',
          discussionId: widget.post.id,
          author: 'mike',
          authorInitial: 'M',
          content: 'Great post! I have a similar experience to share.',
          timeAgo: '1 hour ago',
          likes: 3,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        DiscussionComment(
          id: '3',
          discussionId: widget.post.id,
          author: 'priya',
          authorInitial: 'P',
          content: 'Thank you for sharing this wisdom. It resonates with me.',
          timeAgo: '30 minutes ago',
          likes: 8,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF6B46C1),
      appBar: AppBar(
        title: Text(
          'Discussion',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Post
          _buildMainPost(l10n),
          // Comments Section
          Expanded(
            child: Container(
              color: const Color(0xFF6B46C1),
              child: _comments.isEmpty
                  ? _buildEmptyComments(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _buildCommentCard(comment, l10n);
                      },
                    ),
            ),
          ),
          // Comment Input
          _buildCommentInput(l10n),
        ],
      ),
    );
  }

  Widget _buildMainPost(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF8B4513),
                  radius: 20,
                  child: Text(
                    widget.post.authorInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${widget.post.timeAgo} • ${widget.post.category}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_likeCount likes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_comments.length} comments',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(DiscussionComment comment, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Light gray background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author avatar
            CircleAvatar(
              backgroundColor: const Color(0xFF6B46C1), // Purple background
              radius: 14,
              child: Text(
                comment.authorInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Comment content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author name and time
                  Row(
                    children: [
                      Text(
                        comment.author,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Comment text
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Like button and count
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment.id),
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: comment.isLiked ? Colors.red : Colors.grey.shade600,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes > 0 ? comment.likes.toString() : '',
                              style: TextStyle(
                                fontSize: 11,
                                color: comment.isLiked ? Colors.red : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reply button (placeholder)
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement reply functionality
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply_outlined,
                              color: Colors.grey.shade600,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyComments(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B46C1),
                  const Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF718096).withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) => _addComment(),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SimpleTouchFeedback(
            onTap: _addComment,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B46C1),
                    const Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B46C1).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike() async {
    final newLikeStatus = !_isLiked;
    
    setState(() {
      _isLiked = newLikeStatus;
      _likeCount += newLikeStatus ? 1 : -1;
    });
    
    // Save to database
    await DiscussionService.toggleLike(widget.post.id, newLikeStatus);
    
    // Add to favorites if liked
    if (newLikeStatus) {
      await DiscussionService.addToFavorites(widget.post.id);
    } else {
      await DiscussionService.removeFromFavorites(widget.post.id);
    }
    
    // Save astrologer activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'post_liked',
        discussionId: widget.post.id,
        content: newLikeStatus ? 'Liked post: ${widget.post.title}' : 'Unliked post: ${widget.post.title}',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _toggleCommentLike(String commentId) async {
    final commentIndex = _comments.indexWhere((c) => c.id == commentId);
    if (commentIndex != -1) {
      final comment = _comments[commentIndex];
      final newLikeStatus = !comment.isLiked;
      
      setState(() {
        comment.isLiked = newLikeStatus;
        comment.likes += newLikeStatus ? 1 : -1;
      });
      
      // Save to database
      await DiscussionService.toggleCommentLike(widget.post.id, commentId, newLikeStatus);
      
      // Save astrologer activity
      await DiscussionService.saveAstrologerActivity(
        AstrologerActivity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'comment_liked',
          discussionId: widget.post.id,
          commentId: commentId,
          content: newLikeStatus ? 'Liked comment' : 'Unliked comment',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = DiscussionComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      discussionId: widget.post.id,
      author: 'You',
      authorInitial: 'Y',
      content: _commentController.text.trim(),
      timeAgo: 'Just now',
      likes: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, newComment);
      _commentController.clear();
    });
    
    // Save to database
    await DiscussionService.saveComment(widget.post.id, newComment);
    
    // Save astrologer activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'comment_added',
        discussionId: widget.post.id,
        commentId: newComment.id,
        content: 'Added comment: ${newComment.content}',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sharePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
