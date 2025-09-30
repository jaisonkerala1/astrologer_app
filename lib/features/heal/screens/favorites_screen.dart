import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import 'discussion_detail_screen.dart';
import '../services/discussion_service.dart';
import '../models/discussion_models.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<DiscussionPost> _favoritePosts = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritePosts();
  }

  Future<void> _loadFavoritePosts() async {
    final favoriteIds = await DiscussionService.getFavorites();
    final allPosts = await DiscussionService.getDiscussions();
    
    final favoritePosts = allPosts.where((post) => favoriteIds.contains(post.id)).toList();
    
    if (favoritePosts.isEmpty) {
      _loadSampleFavorites();
    } else {
      setState(() {
        _favoritePosts.addAll(favoritePosts);
      });
    }
  }

  void _loadSampleFavorites() {
    // Sample favorite posts for demonstration
    setState(() {
      _favoritePosts.addAll([
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
    
    return Scaffold(
      backgroundColor: const Color(0xFF6B46C1),
      appBar: AppBar(
        title: Text(
          'Favorites',
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _favoritePosts.isEmpty
          ? _buildEmptyState(l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoritePosts.length,
              itemBuilder: (context, index) {
                final post = _favoritePosts[index];
                return _buildPostCard(post, l10n);
              },
            ),
    );
  }

  Widget _buildPostCard(DiscussionPost post, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${post.author} • ${post.timeAgo} • ${post.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Like button
                  GestureDetector(
                    onTap: () => _removeFromFavorites(post.id),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
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
                      color: const Color(0xFF6B46C1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  // Author avatar
                  CircleAvatar(
                    backgroundColor: const Color(0xFF8B4513),
                    radius: 20,
                    child: Text(
                      post.authorInitial,
                      style: const TextStyle(
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Like posts to add them to your favorites',
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

  void _removeFromFavorites(String postId) async {
    setState(() {
      _favoritePosts.removeWhere((post) => post.id == postId);
    });
    
    // Remove from database
    await DiscussionService.removeFromFavorites(postId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
