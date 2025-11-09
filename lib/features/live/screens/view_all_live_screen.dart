import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../clients/widgets/client_search_bar.dart';
import '../bloc/live_feed_bloc.dart';
import '../bloc/live_feed_event.dart';
import '../bloc/live_feed_state.dart';
import '../models/live_stream_model.dart';
import 'live_feed_screen.dart';

/// Instagram-style View All Live Streams
/// Beautiful grid with search, categories, and seamless feed integration
class ViewAllLiveScreen extends StatefulWidget {
  const ViewAllLiveScreen({super.key});

  @override
  State<ViewAllLiveScreen> createState() => _ViewAllLiveScreenState();
}

class _ViewAllLiveScreenState extends State<ViewAllLiveScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasReachedEnd = false;

  void _onScroll() {
    if (_isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final threshold = maxScroll - 400;
    
    if (current > threshold && !_hasReachedEnd) {
      final bloc = context.read<LiveFeedBloc>();
      final state = bloc.state;
      
      if (state is LiveFeedLoaded && state.hasMoreStreams) {
        print('⬇️ Loading more streams...');
        setState(() => _isLoadingMore = true);
        bloc.add(const LoadMoreLiveStreamsEvent());
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      } else if (state is LiveFeedLoaded && !state.hasMoreStreams) {
        print('🛑 Reached end, no more streams');
        _hasReachedEnd = true; // Prevent further triggers
      }
    }
  }

  Future<void> _onRefresh() async {
    // Add haptic feedback for pull-to-refresh
    HapticFeedback.selectionClick();
    
    // Show shimmer during refresh
    setState(() => _isLoadingMore = false); // Reset loading more state
    
    try {
      _hasReachedEnd = false; // Reset end flag
      
      // Dispatch refresh event
      context.read<LiveFeedBloc>().add(RefreshLiveFeedEvent(category: _selectedCategory));
      
      // Wait for state to update to loading
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Wait for the refresh to complete (shimmer will show)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Small delay for smooth transition (like discussion module)
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Show feedback with haptic
      HapticFeedback.selectionClick();
      
      if (mounted) {
        final state = context.read<LiveFeedBloc>().state;
        if (state is LiveFeedLoaded) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.streams.isNotEmpty 
                    ? 'Refreshed ${state.streams.length} live stream${state.streams.length > 1 ? 's' : ''}'
                    : 'You\'re all caught up!',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Provider.of<ThemeService>(context, listen: false).isDarkMode()
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      // Error handling
      HapticFeedback.selectionClick();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh. Please try again.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _onRefresh,
            ),
          ),
        );
      }
    }
  }

  void _onCategoryTap(String? category) {
    print('🏷️ Category tapped: $category (current: $_selectedCategory)');
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
    context.read<LiveFeedBloc>().add(FilterByCategoryEvent(category));
    print('   Dispatched FilterByCategoryEvent');
  }

  void _openFeed(String streamId) async {
    print('🎬 Opening feed for stream: $streamId');
    HapticFeedback.selectionClick();
    
    // Get current bloc state
    final bloc = context.read<LiveFeedBloc>();
    final state = bloc.state;
    
    if (state is LiveFeedLoaded) {
      print('✅ Current streams count: ${state.streams.length}');
      print('✅ Current index: ${state.currentIndex}');
      print('✅ Target stream ID: $streamId');
      
      // Find the stream in the list
      final streamIndex = state.streams.indexWhere((s) => s.id == streamId);
      print('✅ Stream index: $streamIndex');
    }
    
    // Navigate to vertical feed starting at this stream
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          print('🚀 Building LiveFeedScreen with stream: $streamId');
          return BlocProvider.value(
            value: bloc,
            child: LiveFeedScreen(initialStreamId: streamId),
          );
        },
      ),
    );
    
    print('⬅️ Returned from LiveFeedScreen');
    
    // Restore UI after return
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: SafeArea(
            child: BlocBuilder<LiveFeedBloc, LiveFeedState>(
              builder: (context, state) {
                if (state is LiveFeedLoading) {
                  return _buildLoading(themeService);
                }
                
                if (state is LiveFeedError) {
                  return _buildError(themeService, state.message);
                }
                
                if (state is LiveFeedEmpty) {
                  return _buildEmpty(themeService);
                }
                
                // Handle loading more state - keep showing current content
                if (state is LiveFeedLoadingMore) {
                  print('⏳ Loading more streams, keeping current content visible');
                  return _buildContent(themeService, LiveFeedLoaded(
                    streams: state.currentStreams,
                    currentIndex: state.currentIndex,
                    hasMoreStreams: true,
                    selectedCategory: state.selectedCategory,
                    totalStreams: state.currentStreams.length,
                  ));
                }
                
                if (state is LiveFeedLoaded) {
                  return _buildContent(themeService, state);
                }
                
                return _buildLoading(themeService);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading(ThemeService themeService) {
    return Column(
      children: [
        _buildHeader(themeService),
        _buildSearchBar(themeService),
        _buildCategories(themeService, []),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: 6, // Show 6 skeleton cards
            itemBuilder: (context, index) {
              return _ShimmerCard(themeService: themeService, index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeService themeService, String message) {
    return Column(
      children: [
        _buildHeader(themeService),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: themeService.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeService themeService) {
    return Column(
      children: [
        _buildHeader(themeService),
        _buildCategories(themeService, []),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.live_tv_rounded,
                  size: 80,
                  color: themeService.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No live streams',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _onCategoryTap(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeService.primaryColor,
                      side: BorderSide(color: themeService.primaryColor),
                    ),
                    child: const Text('Clear Filter'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeService themeService, LiveFeedLoaded state) {
    // Filter streams by search query
    final filteredStreams = _searchQuery.isEmpty
        ? state.streams
        : state.streams.where((stream) {
            return stream.astrologerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   stream.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   stream.astrologerSpecialty.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        _buildHeader(themeService),
        _buildSearchBar(themeService),
        _buildCategories(themeService, state.streams),
        Expanded(
          child: filteredStreams.isEmpty
              ? _buildNoResults(themeService)
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: themeService.primaryColor,
                  backgroundColor: themeService.isDarkMode() 
                      ? const Color(0xFF1A1A2E) 
                      : Colors.white,
                  displacement: 50,
                  strokeWidth: 2.5,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredStreams.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredStreams.length) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(themeService.primaryColor),
                          ),
                        );
                      }
                      return _LiveStreamCard(
                        stream: filteredStreams[index],
                        themeService: themeService,
                        onTap: () => _openFeed(filteredStreams[index].id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeService.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: themeService.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Now',
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Discover live sessions',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClientSearchBar(
        hintText: 'Search live streams...',
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

  Widget _buildCategories(ThemeService themeService, List<LiveStreamModel> streams) {
    final categories = [
      {'name': 'All', 'value': null},
      {'name': 'Astrology', 'value': 'Astrology'},
      {'name': 'Tarot', 'value': 'Tarot'},
      {'name': 'Numerology', 'value': 'Numerology'},
      {'name': 'Palmistry', 'value': 'Palmistry'},
      {'name': 'Spiritual', 'value': 'Spiritual'},
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onCategoryTap(cat['value'] as String?),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeService.primaryColor 
                      : themeService.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? themeService.primaryColor 
                        : themeService.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat['name'] as String,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : themeService.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResults(ThemeService themeService) {
    // Make empty state scrollable for pull-to-refresh to work
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: themeService.primaryColor,
      backgroundColor: themeService.isDarkMode() 
          ? const Color(0xFF1A1A2E) 
          : Colors.white,
      displacement: 50,
      strokeWidth: 2.5,
      child: ListView(
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
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: themeService.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No streams found',
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search or category',
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  final LiveStreamModel stream;
  final ThemeService themeService;
  final VoidCallback onTap;

  const _LiveStreamCard({
    required this.stream,
    required this.themeService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Full profile picture background
              Positioned.fill(
                child: stream.astrologerProfilePicture != null
                    ? Image.network(
                        stream.astrologerProfilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeService.primaryColor.withOpacity(0.5),
                                  themeService.primaryColor.withOpacity(0.8),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              themeService.primaryColor.withOpacity(0.5),
                              themeService.primaryColor.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
              ),
              
              // Top gradient for badge visibility
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 70,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom gradient overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 130,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      stream.astrologerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    
                    // Specialty
                    Text(
                      stream.specialty,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Title
                    Text(
                      stream.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // LIVE badge - Top left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF3B30),
                        Color(0xFFE60000),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Viewers - Top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stream.formattedViewerCount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// YouTube-style Shimmer Skeleton Loader
class _ShimmerCard extends StatefulWidget {
  final ThemeService themeService;
  final int index;

  const _ShimmerCard({
    required this.themeService,
    required this.index,
  });

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Stagger animations for each card
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeService.isDarkMode();
    final baseColor = isDark 
        ? const Color(0xFF2C2C2E) 
        : const Color(0xFFE5E5EA);
    final highlightColor = isDark 
        ? const Color(0xFF3A3A3C) 
        : const Color(0xFFF2F2F7);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: baseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Base skeleton structure
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: baseColor,
                      ),
                    ),
                  ],
                ),

                // Shimmer elements matching the actual card layout
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 60,
                    height: 22,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 55,
                    height: 22,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name skeleton
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Specialty skeleton
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title skeleton line 1
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Title skeleton line 2
                      Container(
                        width: 120,
                        height: 10,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),

                // Animated shimmer gradient overlay
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(_animation.value * MediaQuery.of(context).size.width, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            baseColor.withOpacity(0.0),
                            highlightColor.withOpacity(0.3),
                            baseColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
