import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/animated_button.dart';
import 'discussion_detail_screen.dart';
import 'favorites_screen.dart';
import '../services/discussion_service.dart';
import '../models/discussion_models.dart';
import '../widgets/facebook_create_post_bottom_sheet.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<DiscussionPost> _posts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final posts = await DiscussionService.getDiscussions();
    if (posts.isEmpty) {
      _loadSamplePosts();
    } else {
      setState(() {
        _posts.addAll(posts);
      });
    }
  }

  void _loadSamplePosts() {
    setState(() {
      _posts.addAll([
        DiscussionPost(
          id: '1',
          title: 'Astro Veda',
          content: 'Welcome to our spiritual community! Share your experiences and learn from others.',
          author: 'dipanshu',
          authorInitial: 'D',
          timeAgo: '1 day ago',
          category: 'Community Support & Life Talk',
          likes: 24,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '2',
          title: 'hi eeveryone',
          content: 'Hello everyone! I\'m new here and excited to be part of this community.',
          author: 'jatin',
          authorInitial: 'J',
          timeAgo: '1 day ago',
          category: 'Yoga, Meditation & Mindfulness',
          likes: 8,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '3',
          title: 'what',
          content: 'What are your thoughts on the current energy shifts?',
          author: 'jatin',
          authorInitial: 'J',
          timeAgo: '1 day ago',
          category: 'Yoga, Meditation & Mindfulness',
          likes: 12,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '4',
          title: 'Crystal Healing Guide',
          content: 'Complete guide to crystal healing for beginners. Which crystals resonate with you?',
          author: 'sarah',
          authorInitial: 'S',
          timeAgo: '2 days ago',
          category: 'Healing & Wellness',
          likes: 18,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DiscussionPost(
          id: '5',
          title: 'Meditation Techniques',
          content: 'Share your favorite meditation techniques and how they\'ve helped you.',
          author: 'mike',
          authorInitial: 'M',
          timeAgo: '3 days ago',
          category: 'Yoga, Meditation & Mindfulness',
          likes: 15,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
    });
  }

  List<DiscussionPost> get _filteredPosts {
    if (_searchQuery.isEmpty) return _posts;
    return _posts.where((post) =>
        post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(
              l10n.discussion,
              style: const TextStyle(
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
                icon: const Icon(Icons.bookmark_border, color: Color(0xFF6B6B8D)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedPostsScreen(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    _showCreatePostBottomSheet();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(l10n, themeService),
              // Posts List
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: _filteredPosts.isEmpty
                      ? _buildEmptyState(l10n, themeService)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            return _buildPostCard(post, l10n, themeService);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search discussions...',
          hintStyle: const TextStyle(
            color: Color(0xFF6B6B8D),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6B6B8D),
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B6B8D),
                      size: 18,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPostCard(DiscussionPost post, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFAFAFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SimpleTouchFeedback(
        onTap: () {
          _showPostDetail(post);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar + Metadata
              Row(
                children: [
                  // Author Avatar
                  CircleAvatar(
                    backgroundColor: themeService.primaryColor.withOpacity(0.1),
                    radius: 20,
                    child: Text(
                      post.authorInitial,
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Author Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${post.timeAgo} • ${post.category}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B6B8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // More Options
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: const Color(0xFF6B6B8D),
                      size: 20,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Post Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Post Content Preview
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6B8D),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Action Bar
              Row(
                children: [
                  // Like Button
                  _buildActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likes}',
                    color: post.isLiked ? Colors.red : const Color(0xFF6B6B8D),
                    onTap: () => _toggleLike(post.id),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Comment Button
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Comment',
                    color: const Color(0xFF6B6B8D),
                    onTap: () => _showPostDetail(post),
                  ),
                  
                  const Spacer(),
                  
                  // Share Button
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                    ),
                    color: const Color(0xFF6B6B8D),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E5E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 48,
                color: Color(0xFF6B6B8D),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty ? l10n.noPostsYet : 'No posts found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? l10n.beTheFirstToPost : 'Try a different search term',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6B8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FacebookCreatePostBottomSheet(
        onSubmit: (title, content, category, privacy) {
          _createPost(title, content, category, privacy);
        },
      ),
    );
  }

  void _showPostDetail(DiscussionPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(post: post),
      ),
    );
  }

  void _createPost(String title, String content, String category, String privacy) async {
    if (title.trim().isEmpty || content.trim().isEmpty) return;

    final newPost = DiscussionPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      author: 'You',
      authorInitial: 'Y',
      timeAgo: 'Just now',
      category: category,
      likes: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _posts.insert(0, newPost);
    });
    
    // Save to database
    await DiscussionService.saveDiscussion(newPost);
    
    // Save astrologer activity
    await DiscussionService.saveAstrologerActivity(
      AstrologerActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'post_created',
        discussionId: newPost.id,
        content: 'Created post: ${newPost.title}',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final newLikeStatus = !post.isLiked;
      
      setState(() {
        post.isLiked = newLikeStatus;
        post.likes += newLikeStatus ? 1 : -1;
      });
      
      // Save to database
      await DiscussionService.toggleLike(postId, newLikeStatus);
      
      // Add to favorites if liked
      if (newLikeStatus) {
        await DiscussionService.addToFavorites(postId);
      } else {
        await DiscussionService.removeFromFavorites(postId);
      }
      
      // Save astrologer activity
      await DiscussionService.saveAstrologerActivity(
        AstrologerActivity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'post_liked',
          discussionId: postId,
          content: newLikeStatus ? 'Liked post: ${post.title}' : 'Unliked post: ${post.title}',
          timestamp: DateTime.now(),
        ),
      );
    }
  }
}