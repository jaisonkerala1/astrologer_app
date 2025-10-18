import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import 'discussion_detail_screen.dart';
import '../services/discussion_service.dart';
import '../models/discussion_models.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

// Keep old name for backwards compatibility
class FavoritesScreen extends SavedPostsScreen {
  const FavoritesScreen({super.key});
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final List<DiscussionPost> _savedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    final savedPosts = await DiscussionService.getSavedPosts();
    
    if (savedPosts.isEmpty) {
      _loadSampleSavedPosts();
    } else {
      setState(() {
        _savedPosts.addAll(savedPosts);
      });
    }
  }

  void _loadSampleSavedPosts() {
    // Sample saved posts for demonstration
    setState(() {
      _savedPosts.addAll([
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
          id: '6',
          title: 'Meditation for Beginners',
          content: 'Step-by-step guide to start your meditation journey. Perfect for newcomers.',
          author: 'priya',
          authorInitial: 'P',
          timeAgo: '3 days ago',
          category: 'Yoga, Meditation & Mindfulness',
          likes: 32,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        DiscussionPost(
          id: '7',
          title: 'Vastu Shastra Tips',
          content: 'Simple Vastu tips to improve your home energy and bring positivity.',
          author: 'rajesh',
          authorInitial: 'R',
          timeAgo: '4 days ago',
          category: 'Healing & Wellness',
          likes: 15,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
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
              'Saved Posts',
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
          ),
          body: _savedPosts.isEmpty
              ? _buildEmptyState(l10n, themeService)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedPosts.length,
                  itemBuilder: (context, index) {
                    final post = _savedPosts[index];
                    return _buildPostCard(post, l10n, themeService);
                  },
                ),
        );
      },
    );
  }

  Widget _buildPostCard(DiscussionPost post, AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFAFAFA),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscussionDetailScreen(post: post),
            ),
          );
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
                  // Bookmark button (remove from saved)
                  GestureDetector(
                    onTap: () => _removeFromSaved(post.id),
                    child: const Icon(
                      Icons.bookmark,
                      color: Color(0xFF1A1A2E),
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
                Icons.bookmark_border,
                size: 48,
                color: Color(0xFF6B6B8D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saved posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save posts to read them later',
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

  void _removeFromSaved(String postId) async {
    setState(() {
      _savedPosts.removeWhere((post) => post.id == postId);
    });
    
    // Remove from database
    await DiscussionService.unsavePost(postId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from saved posts'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
