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
          backgroundColor: themeService.primaryColor,
          appBar: AppBar(
            title: Text(
              l10n.discussion,
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
                icon: Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: AnimatedButton(
                  onPressed: () {
                    _showCreatePostBottomSheet();
                  },
                  text: 'Post',
                  icon: Icons.add,
                  backgroundColor: Colors.white,
                  foregroundColor: themeService.primaryColor,
                  width: 100,
                  height: 40,
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
                  color: themeService.primaryColor,
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
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
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
        style: TextStyle(
          color: themeService.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search discussions...',
          hintStyle: TextStyle(
            color: themeService.textSecondary.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: themeService.primaryColor.withOpacity(0.7),
              size: 22,
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
                    child: Icon(
                      Icons.close_rounded,
                      color: themeService.textSecondary.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPostCard(DiscussionPost post, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${post.author} • ${post.timeAgo} • ${post.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Like button
                  GestureDetector(
                    onTap: () => _toggleLike(post.id),
                    child: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : themeService.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textPrimary.withOpacity(0.87),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Navigation arrow button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  // Author avatar
                  CircleAvatar(
                    backgroundColor: themeService.accentColor,
                    radius: 20,
                    child: Text(
                      post.authorInitial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? l10n.noPostsYet : 'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
                      color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? l10n.beTheFirstToPost : 'Try a different search term',
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