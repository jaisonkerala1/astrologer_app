import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
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
    print('🔄 Refresh triggered, resetting end flag');
    _hasReachedEnd = false; // Reset when refreshing
    context.read<LiveFeedBloc>().add(RefreshLiveFeedEvent(category: _selectedCategory));
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
        Expanded(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(themeService.primaryColor),
            ),
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
    return Column(
      children: [
        _buildHeader(themeService),
        _buildCategories(themeService, state.streams),
        _buildStats(themeService, state),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: state.streams.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.streams.length) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(themeService.primaryColor),
                  ),
                );
              }
              return _LiveStreamCard(
                stream: state.streams[index],
                themeService: themeService,
                onTap: () => _openFeed(state.streams[index].id),
              );
            },
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

  Widget _buildCategories(ThemeService themeService, List<LiveStreamModel> streams) {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded, 'value': null},
      {'name': 'Astrology', 'icon': Icons.star_rounded, 'value': 'Astrology'},
      {'name': 'Tarot', 'icon': Icons.style_rounded, 'value': 'Tarot'},
      {'name': 'Numerology', 'icon': Icons.calculate_rounded, 'value': 'Numerology'},
      {'name': 'Palmistry', 'icon': Icons.back_hand_rounded, 'value': 'Palmistry'},
      {'name': 'Spiritual', 'icon': Icons.self_improvement_rounded, 'value': 'Spiritual'},
    ];

    return SizedBox(
      height: 64,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            themeService.primaryColor,
                            themeService.primaryColor.withOpacity(0.8),
                          ],
                        )
                      : null,
                  color: isSelected ? null : themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? themeService.primaryColor
                        : themeService.borderColor,
                    width: 1,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : themeService.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : themeService.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats(ThemeService themeService, LiveFeedLoaded state) {
    final totalViewers = state.streams.fold<int>(
      0,
      (sum, stream) => sum + stream.viewerCount,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeService.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.live_tv_rounded,
            label: '${state.streams.length} Live',
            color: Colors.red,
            themeService: themeService,
          ),
          Container(
            width: 1,
            height: 24,
            color: themeService.borderColor,
          ),
          _StatItem(
            icon: Icons.visibility_rounded,
            label: '$totalViewers Watching',
            color: themeService.primaryColor,
            themeService: themeService,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeService themeService;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          color: themeService.cardColor,
          border: Border.all(
            color: themeService.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeService.primaryColor.withOpacity(0.3),
                        themeService.primaryColor.withOpacity(0.6),
                        themeService.primaryColor.withOpacity(0.8),
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
                  children: [
                    // Astrologer profile
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: themeService.primaryColor,
                          ),
                          child: stream.astrologerProfilePicture != null
                              ? ClipOval(
                                  child: Image.network(
                                    stream.astrologerProfilePicture!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stream.astrologerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                stream.specialty,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      stream.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Viewers
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stream.formattedViewerCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // LIVE badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
