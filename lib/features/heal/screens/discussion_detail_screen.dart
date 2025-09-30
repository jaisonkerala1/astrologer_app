import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
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
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _commentController.addListener(_onTextChanged);
    _loadComments();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _commentController.text.trim().isNotEmpty;
    });
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
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.primaryColor,
          appBar: AppBar(
            title: Text(
              'Discussion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
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
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: _sharePost,
              ),
            ],
          ),
          body: Column(
            children: [
              // Main Post
              _buildMainPost(l10n, themeService),
              // Comments Section
              Expanded(
                child: Container(
                  color: themeService.primaryColor,
                  child: _comments.isEmpty
                      ? _buildEmptyComments(l10n, themeService)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentCard(comment, l10n, themeService);
                          },
                        ),
                ),
              ),
              // Comment Input
              _buildCommentInput(l10n, themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainPost(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
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
                  backgroundColor: themeService.accentColor,
                  radius: 20,
                  child: Text(
                    widget.post.authorInitial,
                    style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.post.timeAgo} • ${widget.post.category}',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : themeService.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.post.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.content,
              style: TextStyle(
                fontSize: 16,
                color: themeService.textPrimary.withOpacity(0.87),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : themeService.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_likeCount likes',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 24),
                Icon(
                  Icons.chat_bubble_outline,
                  color: themeService.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_comments.length} comments',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textSecondary,
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

  Widget _buildCommentCard(DiscussionComment comment, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeService.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeService.borderColor,
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
              backgroundColor: themeService.primaryColor,
              radius: 14,
              child: Text(
                comment.authorInitial,
                style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeService.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(
                          fontSize: 10,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Comment text
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeService.textPrimary.withOpacity(0.87),
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
                              color: comment.isLiked ? Colors.red : themeService.textSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes > 0 ? comment.likes.toString() : '',
                              style: TextStyle(
                                fontSize: 11,
                                color: comment.isLiked ? Colors.red : themeService.textSecondary,
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
                              color: themeService.textSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 11,
                                color: themeService.textSecondary,
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

  Widget _buildEmptyComments(AppLocalizations l10n, ThemeService themeService) {
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
            style: TextStyle(
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

  Widget _buildCommentInput(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        border: Border(
          top: BorderSide(
            color: themeService.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(
                    color: themeService.textSecondary.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: themeService.surfaceColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: themeService.borderColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: themeService.borderColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: themeService.primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: themeService.textPrimary,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isComposing ? _addComment : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isComposing
                      ? LinearGradient(
                          colors: [
                            themeService.primaryColor,
                            themeService.primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            themeService.textSecondary.withOpacity(0.3),
                            themeService.textSecondary.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _isComposing
                      ? [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isComposing
                      ? Colors.white
                      : themeService.textSecondary.withOpacity(0.5),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
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
      _isComposing = false;
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
