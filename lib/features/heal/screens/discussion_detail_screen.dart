import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../services/discussion_service.dart';
import '../models/discussion_models.dart';
import '../../auth/models/astrologer_model.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final DiscussionPost post;

  const DiscussionDetailScreen({super.key, required this.post});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final List<DiscussionComment> _comments = [];
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isSaved = false;
  bool _isComposing = false;
  bool _isNotificationSubscribed = false; // Track notification subscription
  DiscussionComment? _replyingTo; // Track which comment we're replying to
  
  // Current user info
  String _currentUserName = 'You';
  String _currentUserInitial = 'Y';
  String? _currentUserPhoto;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _isSaved = false; // Will be loaded from saved posts
    _isNotificationSubscribed = false; // Will be loaded from preferences
    _commentController.addListener(_onTextChanged);
    _loadCurrentUser();
    _loadComments();
    _checkIfSaved();
    _checkNotificationStatus();
  }
  
  /// Load current user's profile information
  Future<void> _loadCurrentUser() async {
    try {
      final storageService = StorageService();
      final userDataJson = await storageService.getUserData();
      
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        final astrologer = AstrologerModel.fromJson(userData);
        
        setState(() {
          _currentUserName = astrologer.name;
          _currentUserInitial = astrologer.name.isNotEmpty 
              ? astrologer.name[0].toUpperCase() 
              : 'Y';
          _currentUserPhoto = astrologer.profilePicture;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      // Keep default values if error
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    // Check if this post is in saved posts
    final savedPosts = await DiscussionService.getSavedPosts();
    setState(() {
      _isSaved = savedPosts.any((post) => post.id == widget.post.id);
    });
  }

  Future<void> _checkNotificationStatus() async {
    // Check if user is subscribed to notifications for this post
    final isSubscribed = await DiscussionService.isNotificationSubscribed(widget.post.id);
    setState(() {
      _isNotificationSubscribed = isSubscribed;
    });
  }

  Future<void> _toggleNotifications() async {
    HapticFeedback.selectionClick();
    
    final newStatus = !_isNotificationSubscribed;
    setState(() {
      _isNotificationSubscribed = newStatus;
    });
    
    if (newStatus) {
      await DiscussionService.subscribeToNotifications(widget.post.id);
    } else {
      await DiscussionService.unsubscribeFromNotifications(widget.post.id);
    }
    
    // Save activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: newStatus ? 'notification_subscribed' : 'notification_unsubscribed',
        discussionId: widget.post.id,
        content: newStatus 
            ? 'Subscribed to notifications for: ${widget.post.title}'
            : 'Unsubscribed from notifications for: ${widget.post.title}',
        timestamp: DateTime.now(),
      ),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus 
                ? 'You\'ll be notified of all comments on this post'
                : 'You\'ll only be notified of replies to your comments',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _commentController.text.trim().isNotEmpty;
    });
  }

  void _startReply(DiscussionComment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  double _calculateCommentInputHeight() {
    // Base height for comment input
    double baseHeight = 80.0; // Approximate height with padding
    
    // Add extra height if replying (for the reply indicator bar)
    if (_replyingTo != null) {
      baseHeight += 44.0; // Height of reply indicator
    }
    
    return baseHeight;
  }

  Future<void> _loadComments() async {
    final allComments = await DiscussionService.getComments(widget.post.id);
    if (allComments.isEmpty) {
      _loadSampleComments();
    } else {
      setState(() {
        // Rebuild parent-child relationships from flat list
        _comments.addAll(_buildCommentTree(allComments));
      });
    }
  }

  /// Builds a tree structure from flat list of comments
  /// Separates parent comments from replies and nests them correctly
  /// Server-compatible: works with flat storage structure
  List<DiscussionComment> _buildCommentTree(List<DiscussionComment> flatComments) {
    // Separate parent comments and replies
    final parentComments = <DiscussionComment>[];
    final replyComments = <DiscussionComment>[];
    
    for (final comment in flatComments) {
      if (comment.parentCommentId == null) {
        // Top-level comment
        parentComments.add(comment);
      } else {
        // Reply to a comment
        replyComments.add(comment);
      }
    }
    
    // Attach replies to their parent comments
    for (final parent in parentComments) {
      final replies = replyComments
          .where((reply) => reply.parentCommentId == parent.id)
          .toList();
      parent.replies.clear();
      parent.replies.addAll(replies);
    }
    
    return parentComments;
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
          resizeToAvoidBottomInset: true,
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
                  _isNotificationSubscribed 
                      ? Icons.notifications_active 
                      : Icons.notifications_none,
                  color: _isNotificationSubscribed 
                      ? themeService.primaryColor 
                      : const Color(0xFF6B6B8D),
                ),
                onPressed: _toggleNotifications,
                tooltip: _isNotificationSubscribed 
                    ? 'Unsubscribe from notifications' 
                    : 'Subscribe to notifications',
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
              // Scrollable content (post + comments)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Container(
                        color: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _comments.isEmpty
                            ? _buildEmptyComments(l10n, themeService)
                            : Column(
                                children: _comments.map((comment) {
                                  return _buildCommentCard(comment, l10n, themeService);
                                }).toList(),
                              ),
                      ),
                      // Extra padding at bottom for better scroll experience
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Fixed comment input at bottom
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
                ProfileAvatarWidget(
                  imagePath: (widget.post.author == _currentUserName) ? _currentUserPhoto : null,
                  radius: 22,
                  fallbackText: widget.post.authorInitial,
                  backgroundColor: themeService.primaryColor.withOpacity(0.1),
                  textColor: themeService.primaryColor,
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
                // Interactive stats on the left
                Expanded(
                  child: Row(
                    children: [
                      // Like button
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _toggleLike();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.red : const Color(0xFF6B6B8D),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_likeCount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isLiked ? Colors.red : const Color(0xFF6B6B8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Comment button
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _commentFocusNode.requestFocus();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF6B6B8D),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_comments.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B6B8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions on the right
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bookmark button
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _toggleSave();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: _isSaved ? const Color(0xFF1A1A2E) : const Color(0xFF6B6B8D),
                        ),
                      ),
                    ),
                    // Share button
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _sharePost();
                      },
                      borderRadius: BorderRadius.circular(8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        Container(
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
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _toggleCommentLike(comment.id);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                          ),
                      const SizedBox(width: 20),
                      // Reply button
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _startReply(comment);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B6B8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                          // Reply count indicator (Facebook style)
                          if (comment.replies.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B6B8D),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Nested replies (Facebook style - indented)
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 12),
            child: Column(
              children: comment.replies.map((reply) {
                return _buildReplyCard(reply, l10n, themeService);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyCard(DiscussionComment reply, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author avatar (smaller for replies)
            CircleAvatar(
              backgroundColor: themeService.primaryColor.withOpacity(0.1),
              radius: 14,
              child: Text(
                reply.authorInitial,
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author name and time
                  Row(
                    children: [
                      Text(
                        reply.author,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reply.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6B8D),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Reply text
                  Text(
                    reply.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3A3A4E),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Actions (only like for replies - no reply button for 1-level structure)
                  InkWell(
                    onTap: () {
                              HapticFeedback.selectionClick();
                      _toggleCommentLike(reply.id);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reply.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: reply.isLiked ? Colors.red : const Color(0xFF6B6B8D),
                            size: 14,
                          ),
                          if (reply.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              reply.likes.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: reply.isLiked ? Colors.red : const Color(0xFF6B6B8D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _buildCommentInput(AppLocalizations l10n, ThemeService themeService) {
    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator (Facebook style)
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: themeService.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to ${_replyingTo!.author}',
                        style: TextStyle(
                          fontSize: 13,
                          color: themeService.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF6B6B8D),
                      ),
                    ),
                  ],
                ),
              ),
            // Comment input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar (current user with profile picture)
                  ProfileAvatarWidget(
                    imagePath: _currentUserPhoto,
                    radius: 18,
                    fallbackText: _currentUserInitial,
                    backgroundColor: themeService.primaryColor.withOpacity(0.1),
                    textColor: themeService.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null 
                            ? 'Write a reply...' 
                            : 'Write a comment...',
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
    DiscussionComment? targetComment;
    
    // Search in parent comments
    for (final comment in _comments) {
      if (comment.id == commentId) {
        targetComment = comment;
        break;
      }
      // Search in replies
      for (final reply in comment.replies) {
        if (reply.id == commentId) {
          targetComment = reply;
          break;
        }
      }
      if (targetComment != null) break;
    }
    
    if (targetComment != null) {
      final newLikeStatus = !targetComment.isLiked;
      
      setState(() {
        targetComment!.isLiked = newLikeStatus;
        targetComment.likes += newLikeStatus ? 1 : -1;
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

    // For 1-level structure: if replying to a reply, reply to its parent instead
    final actualParentId = _replyingTo?.parentCommentId ?? _replyingTo?.id;

    final newComment = DiscussionComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      discussionId: widget.post.id,
      author: _currentUserName,
      authorInitial: _currentUserInitial,
      content: _commentController.text.trim(),
      timeAgo: 'Just now',
      likes: 0,
      isLiked: false,
      createdAt: DateTime.now(),
      parentCommentId: actualParentId, // Always references parent comment (1-level only)
    );

    setState(() {
      if (actualParentId != null) {
        // Find the parent comment and add reply to it
        final parentIndex = _comments.indexWhere((c) => c.id == actualParentId);
        if (parentIndex != -1) {
          _comments[parentIndex].replies.insert(0, newComment);
        }
      } else {
        // Add as a top-level comment
        _comments.insert(0, newComment);
      }
      _commentController.clear();
      _isComposing = false;
      _replyingTo = null; // Clear reply mode
    });
    
    // Save to database
    await DiscussionService.saveComment(widget.post.id, newComment);
    
    // Save astrologer activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: actualParentId != null ? 'reply_added' : 'comment_added',
        discussionId: widget.post.id,
        commentId: newComment.id,
        content: actualParentId != null 
            ? 'Replied to ${_replyingTo!.author}: ${newComment.content}'
            : 'Added comment: ${newComment.content}',
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

