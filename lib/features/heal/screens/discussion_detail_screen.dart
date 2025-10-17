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
  bool _isSaved = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _isSaved = false; // Will be loaded from saved posts
    _commentController.addListener(_onTextChanged);
    _loadComments();
    _checkIfSaved();
  }
  
  Future<void> _checkIfSaved() async {
    // Check if this post is in saved posts
    final savedPosts = await DiscussionService.getSavedPosts();
    setState(() {
      _isSaved = savedPosts.any((post) => post.id == widget.post.id);
    });
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
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text(
              'Discussion',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A2E),
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: const Color(0xFF6B6B8D),
                ),
                onPressed: _sharePost,
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF6B6B8D),
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Main Post
              _buildMainPost(l10n, themeService),
              
              // Comments Label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                color: const Color(0xFFF5F5F5),
                child: Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              
              // Comments Section
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: _comments.isEmpty
                      ? _buildEmptyComments(l10n, themeService)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: themeService.primaryColor.withOpacity(0.1),
                  radius: 22,
                  child: Text(
                    widget.post.authorInitial,
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
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
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.post.timeAgo} • ${widget.post.category}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B6B8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Post Title
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
                height: 1.4,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            
            // Post Content
            Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3A3A4E),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFE5E5E5),
            ),
            const SizedBox(height: 12),
            
            // Single line: Stats + Actions (Facebook style)
            Row(
              children: [
                // Stats on the left
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: _isLiked ? Colors.red : const Color(0xFF6B6B8D),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likeCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble,
                        color: Color(0xFF6B6B8D),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_comments.length} comments',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions on the right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _toggleSave,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: _isSaved ? const Color(0xFF1A1A2E) : const Color(0xFF6B6B8D),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sharePost,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: Color(0xFF6B6B8D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFE5E5E5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(DiscussionComment comment, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author avatar
            CircleAvatar(
              backgroundColor: themeService.primaryColor.withOpacity(0.1),
              radius: 18,
              child: Text(
                comment.authorInitial,
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6B8D),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Comment text
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF3A3A4E),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Actions
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment.id),
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: comment.isLiked ? Colors.red : const Color(0xFF6B6B8D),
                              size: 16,
                            ),
                            if (comment.likes > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                comment.likes.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: comment.isLiked ? Colors.red : const Color(0xFF6B6B8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Reply button
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement reply functionality
                        },
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B6B8D),
                            fontWeight: FontWeight.w500,
                          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Color(0xFF6B6B8D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share your thoughts!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6B8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: themeService.primaryColor.withOpacity(0.1),
              radius: 18,
              child: Text(
                'Y',
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6B6B8D),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: themeService.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isComposing ? _addComment : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isComposing
                      ? themeService.primaryColor
                      : const Color(0xFFE5E5E5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isComposing
                      ? Colors.white
                      : const Color(0xFF6B6B8D),
                  size: 20,
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
  
  void _toggleSave() async {
    final newSaveStatus = !_isSaved;
    
    setState(() {
      _isSaved = newSaveStatus;
    });
    
    // Save to database
    if (newSaveStatus) {
      await DiscussionService.savePost(widget.post.id);
    } else {
      await DiscussionService.unsavePost(widget.post.id);
    }
    
    // Save astrologer activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: newSaveStatus ? 'post_saved' : 'post_unsaved',
        discussionId: widget.post.id,
        content: newSaveStatus ? 'Saved post: ${widget.post.title}' : 'Unsaved post: ${widget.post.title}',
        timestamp: DateTime.now(),
      ),
    );
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newSaveStatus ? 'Post saved' : 'Post removed from saved'),
        duration: const Duration(seconds: 2),
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

