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
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import 'discussion_detail_screen.dart';
import 'favorites_screen.dart';
import '../services/discussion_service.dart';
import '../services/discussion_api_service.dart';
import '../services/discussion_socket_service.dart';
import '../models/discussion_models.dart';
import '../widgets/facebook_create_post_bottom_sheet.dart';
import '../../auth/models/astrologer_model.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<DiscussionPost> _posts = [];
  String _searchQuery = '';
  
  // API and Real-time services
  final _apiService = DiscussionApiService();
  final _socketService = DiscussionSocketService();
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Current user info
  String _currentUserName = 'You';
  String _currentUserInitial = 'Y';
  String? _currentUserPhoto;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
    _setupRealTimeListeners();
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

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try loading from API first
      final result = await _apiService.getDiscussions(
        page: 1,
        limit: 50,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );
      
      setState(() {
        _posts.clear();
        _posts.addAll(result['discussions']);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading from API: $e');
      
      // Fallback: Try local storage
      try {
        final localPosts = await DiscussionService.getDiscussions();
        if (localPosts.isNotEmpty) {
          setState(() {
            _posts.clear();
            _posts.addAll(localPosts);
            _isLoading = false;
          });
        } else {
          // Last resort: Load sample posts
          _loadSamplePosts();
          setState(() => _isLoading = false);
        }
      } catch (localError) {
        setState(() {
          _errorMessage = 'Failed to load discussions. Please check your connection.';
          _isLoading = false;
        });
        // Still show sample posts for demo
        _loadSamplePosts();
      }
    }
  }

  void _loadSamplePosts() {
    setState(() {
      _posts.addAll([
        DiscussionPost(
          id: '1',
          authorId: '',
          title: 'Astro Veda',
          content: 'Welcome to our spiritual community! Share your experiences and learn from others.',
          author: 'dipanshu',
          authorInitial: 'D',
          category: 'general',
          likes: 24,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '2',
          authorId: '',
          title: 'hi eeveryone',
          content: 'Hello everyone! I\'m new here and excited to be part of this community.',
          author: 'jatin',
          authorInitial: 'J',
          category: 'general',
          likes: 8,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '3',
          authorId: '',
          title: 'Understanding Planetary Transits',
          content: 'Let\'s discuss how planetary transits affect our daily lives and spiritual growth.',
          author: 'jatin',
          authorInitial: 'J',
          category: 'vedic',
          likes: 12,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DiscussionPost(
          id: '4',
          authorId: '',
          title: 'Tarot Reading Insights',
          content: 'Share your tarot reading experiences and interpretations.',
          author: 'sarah',
          authorInitial: 'S',
          category: 'tarot',
          likes: 18,
          isLiked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DiscussionPost(
          id: '5',
          authorId: '',
          title: 'Vastu Tips for Home',
          content: 'Simple Vastu Shastra tips to improve your home energy and bring positivity.',
          author: 'mike',
          authorInitial: 'M',
          category: 'vastu',
          likes: 15,
          isLiked: false,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
    });
  }

  /// Setup real-time Socket.IO listeners for live updates
  void _setupRealTimeListeners() {
    // Connect to Socket.IO server
    _socketService.connect();
    
    // Listen to new discussions created by other users
    _socketService.onDiscussionCreated((discussion, author) {
      setState(() {
        // Add to top of list
        _posts.insert(0, discussion);
      });
    });
    
    // Listen to discussion updates
    _socketService.onDiscussionUpdated((discussionId, updatedDiscussion) {
      setState(() {
        final index = _posts.indexWhere((p) => p.id == discussionId);
        if (index != -1) {
          _posts[index] = updatedDiscussion;
        }
      });
    });
    
    // Listen to discussion deletions
    _socketService.onDiscussionDeleted((discussionId) {
      setState(() {
        _posts.removeWhere((p) => p.id == discussionId);
      });
    });
    
    // Listen to real-time like updates (Facebook-style)
    _socketService.onDiscussionLike((discussionId, action, likeCount, user) {
      setState(() {
        final index = _posts.indexWhere((p) => p.id == discussionId);
        if (index != -1) {
          _posts[index].likes = likeCount;
        }
      });
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

  Future<void> _refreshDiscussions() async {
    // Add haptic feedback for pull-to-refresh
    HapticFeedback.mediumImpact();
    
    try {
      final oldPostCount = _posts.length;
      
      // Fetch fresh data from API
      final result = await _apiService.getDiscussions(
        page: 1,
        limit: 50,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );
      
      setState(() {
        // Clear and reload posts
        _posts.clear();
        _posts.addAll(result['discussions']);
      });
      
      // Calculate new posts count
      final newPostsCount = _posts.length - oldPostCount;
      
      // Show feedback with haptic
      HapticFeedback.lightImpact();
      
      if (mounted) {
        // Show success message
        if (newPostsCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$newPostsCount new post${newPostsCount > 1 ? 's' : ''} loaded'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You\'re all caught up!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Error handling
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh. Please try again.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _refreshDiscussions,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showCreatePostBottomSheet();
            },
            backgroundColor: themeService.primaryColor,
            elevation: 4,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
          ),
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
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(l10n, themeService),
              // Posts List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshDiscussions,
                  color: themeService.primaryColor,
                  backgroundColor: Colors.white,
                  displacement: 50,
                  strokeWidth: 2.5,
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _filteredPosts.isEmpty
                        ? _buildEmptyState(l10n, themeService)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = _filteredPosts[index];
                              return _buildPostCard(post, l10n, themeService);
                            },
                          ),
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
                  // Author Avatar (with profile picture support)
                  ProfileAvatarWidget(
                    imagePath: (post.author == _currentUserName) ? _currentUserPhoto : null,
                    radius: 20,
                    fallbackText: post.authorInitial,
                    backgroundColor: themeService.primaryColor.withOpacity(0.1),
                    textColor: themeService.primaryColor,
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
    // Make empty state scrollable for pull-to-refresh to work
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 300,
          child: Center(
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
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Pull down to refresh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF6B6B8D).withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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

    try {
      // Post to API - Socket.IO will broadcast to all users
      final newPost = await _apiService.createDiscussion(
        title: title.trim(),
        content: content.trim(),
        category: category,
        visibleTo: privacy == 'Public' ? 'both' : 'astrologers_only',
      );

      // Add to local list (optimistic update)
      setState(() {
        _posts.insert(0, newPost);
      });

      // Also save to local storage as backup
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
    } catch (e) {
      print('Error creating post: $e');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString().contains('category') ? 'Invalid category' : 'Please check your internet connection'}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _createPost(title, content, category, privacy),
            ),
          ),
        );
      }
    }
  }

  void _toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final oldLikeStatus = post.isLiked;
      final oldLikeCount = post.likes;
      
      // Optimistic UI update
      setState(() {
        post.isLiked = !oldLikeStatus;
        post.likes += post.isLiked ? 1 : -1;
      });
      
      try {
        // Call API - it returns the actual state from backend
        final result = await _apiService.toggleDiscussionLike(postId);
        
        // Sync with backend response (this is the truth!)
        setState(() {
          post.isLiked = result['liked'] as bool;
          post.likes = result['likeCount'] as int;
        });
        
        // Also save to local storage
        await DiscussionService.toggleLike(postId, post.isLiked);
        
        // Save astrologer activity
        await DiscussionService.saveAstrologerActivity(
          AstrologerActivity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'post_liked',
            discussionId: postId,
            content: post.isLiked ? 'Liked post: ${post.title}' : 'Unliked post: ${post.title}',
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        print('Error toggling like: $e');
        // Revert optimistic update on error
        setState(() {
          post.isLiked = oldLikeStatus;
          post.likes = oldLikeCount;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Clean up Socket.IO listeners and disconnect
    _socketService.removeAllListeners();
    _socketService.disconnect();
    super.dispose();
  }
}