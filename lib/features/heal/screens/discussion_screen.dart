import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'discussion_detail_screen.dart';
import 'favorites_screen.dart';
import '../services/discussion_service.dart';
import '../services/discussion_api_service.dart';
import '../models/discussion_models.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import '../widgets/simple_create_discussion_bottom_sheet.dart';
import '../../auth/models/astrologer_model.dart';
import '../../clients/widgets/client_search_bar.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<DiscussionPost> _posts = [];
  String _searchQuery = '';
  bool _isLoading = true; // Loading state for shimmer
  bool _useApiData = false; // Flag to track if API data is available
  
  // BLoC instance
  late DiscussionBloc _discussionBloc;
  
  // Current user info
  String _currentUserName = 'You';
  String _currentUserInitial = 'Y';
  String? _currentUserPhoto;

  @override
  void initState() {
    super.initState();
    _discussionBloc = getIt<DiscussionBloc>();
    _loadCurrentUser();
    _loadPosts();
  }
  
  @override
  void dispose() {
    _discussionBloc.close();
    super.dispose();
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
    setState(() => _isLoading = true);
    
    // Try to load from API first
    try {
      _discussionBloc.add(const LoadDiscussionsEvent());
      
      // Wait for the BLoC to respond
      await for (final state in _discussionBloc.stream) {
        if (state is DiscussionLoaded) {
          setState(() {
            _posts.clear();
            _posts.addAll(state.discussions);
            _useApiData = true;
            _isLoading = false;
          });
          break;
        } else if (state is DiscussionError) {
          print('API Error: ${state.message}');
          // Fall back to local storage
          await _loadLocalPosts();
          break;
        }
      }
    } catch (e) {
      print('Error loading from API: $e');
      // Fall back to local storage
      await _loadLocalPosts();
    }
  }
  
  Future<void> _loadLocalPosts() async {
    final posts = await DiscussionService.getDiscussions();
    if (posts.isEmpty) {
      _loadSamplePosts();
    } else {
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
      });
    }
    
    // Small delay for smooth transition (like Facebook)
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() => _isLoading = false);
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

  Future<void> _refreshDiscussions() async {
    // Add haptic feedback for pull-to-refresh
    HapticFeedback.selectionClick();
    
    // Show shimmer during refresh
    setState(() => _isLoading = true);
    
    try {
      final oldPostCount = _posts.length;
      
      if (_useApiData) {
        // Use API to refresh
        _discussionBloc.add(const LoadDiscussionsEvent(refresh: true));
        
        await for (final state in _discussionBloc.stream) {
          if (state is DiscussionLoaded) {
            setState(() {
              _posts.clear();
              _posts.addAll(state.discussions);
              _isLoading = false;
            });
            break;
          } else if (state is DiscussionError) {
            setState(() => _isLoading = false);
            break;
          }
        }
      } else {
        // Fall back to local storage
        await Future.delayed(const Duration(milliseconds: 1500));
        final newPosts = await DiscussionService.getDiscussions();
        
        setState(() {
          _posts.clear();
          if (newPosts.isNotEmpty) {
            _posts.addAll(newPosts);
          } else {
            _loadSamplePosts();
          }
          _isLoading = false;
        });
      }
      
      // Calculate new posts count
      final newPostsCount = _posts.length - oldPostCount;
      
      // Show feedback with haptic
      HapticFeedback.selectionClick();
      
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
      HapticFeedback.selectionClick();
      
      // Hide shimmer on error
      setState(() => _isLoading = false);
      
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showCreatePostBottomSheet();
            },
            backgroundColor: themeService.primaryColor,
            elevation: 4,
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
            label: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
                        ? _buildShimmerList(themeService)
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: ClientSearchBar(
        hintText: 'Search discussions...',
        minimal: true,
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
        },
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
            color: Colors.black.withOpacity(0.2),
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

  /// Shimmer loader list (Facebook-style)
  Widget _buildShimmerList(ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(), // No scrolling while loading
      itemCount: 4, // Show 4 shimmer cards
      itemBuilder: (context, index) => _buildDiscussionCardShimmer(themeService),
    );
  }

  /// Individual discussion card shimmer (matches real card structure)
  Widget _buildDiscussionCardShimmer(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar + Author Info
          Row(
            children: [
              // Avatar shimmer
              SkeletonLoader(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              
              // Author info shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author name
                    SkeletonLoader(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    // Time + Category
                    SkeletonLoader(
                      width: 180,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              
              // More button shimmer
              SkeletonLoader(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Title shimmer (2 lines, thick)
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 12),
          
          // Content shimmer (3 lines, normal)
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.4,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 16),
          
          // Action bar shimmer
          Row(
            children: [
              // Like button shimmer
              SkeletonLoader(
                width: 60,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 20),
              // Comment button shimmer
              SkeletonLoader(
                width: 80,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
              const Spacer(),
              // Share button shimmer
              SkeletonLoader(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
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
      builder: (context) => SimpleCreateDiscussionBottomSheet(
        onSubmit: (title, content, category) {
          _createPost(title, content, category);
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

  void _createPost(String title, String content, String category) async {
    if (title.trim().isEmpty || content.trim().isEmpty) return;

    // Create optimistic post for immediate UI update
    final optimisticPost = DiscussionPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      author: _currentUserName,
      authorInitial: _currentUserInitial,
      timeAgo: 'Just now',
      category: category,
      likes: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );

    // Optimistically add to UI
    setState(() {
      _posts.insert(0, optimisticPost);
    });
    
    if (_useApiData) {
      // Create via API
      _discussionBloc.add(CreateDiscussionEvent(
        title: title.trim(),
        content: content.trim(),
        category: category,
      ));
      
      // Listen for result
      _discussionBloc.stream.firstWhere((state) => 
        state is DiscussionCreated || state is ActionError
      ).then((state) {
        if (state is DiscussionCreated) {
          // Replace optimistic post with real one
          setState(() {
            final index = _posts.indexWhere((p) => p.id == optimisticPost.id);
            if (index != -1) {
              _posts[index] = state.discussion;
            }
          });
        } else if (state is ActionError) {
          // Remove optimistic post on error
          setState(() {
            _posts.removeWhere((p) => p.id == optimisticPost.id);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create post: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    } else {
      // Fallback: Save to local storage
      await DiscussionService.saveDiscussion(optimisticPost);
      
      // Save astrologer activity
      await DiscussionService.saveAstrologerActivity(
        AstrologerActivity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'post_created',
          discussionId: optimisticPost.id,
          content: 'Created post: ${optimisticPost.title}',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final wasLiked = post.isLiked;
      
      // Optimistic update
      setState(() {
        post.isLiked = !wasLiked;
        post.likes += wasLiked ? -1 : 1;
      });
      
      if (_useApiData) {
        // Use API
        _discussionBloc.add(ToggleDiscussionLikeEvent(postId));
      } else {
        // Fallback: Save to local storage
        await DiscussionService.toggleLike(postId, !wasLiked);
        
        // Add to favorites if liked
        if (!wasLiked) {
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
            content: !wasLiked ? 'Liked post: ${post.title}' : 'Unliked post: ${post.title}',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }
}