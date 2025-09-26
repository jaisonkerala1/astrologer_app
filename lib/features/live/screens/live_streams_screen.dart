import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../widgets/live_stream_card.dart';
import 'live_stream_viewer_screen.dart';

class LiveStreamsScreen extends StatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  State<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen> {
  final LiveStreamService _liveService = LiveStreamService();
  LiveStreamCategory? _selectedCategory;
  bool _isLoading = false;
  List<LiveStreamModel> _streams = [];
  List<LiveStreamModel> _filteredStreams = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLiveStreams();
  }

  Future<void> _loadLiveStreams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final streams = await _liveService.getLiveStreams();
        setState(() {
          _streams = streams;
        _filteredStreams = streams;
          _isLoading = false;
        });
    } catch (e) {
        setState(() {
          _isLoading = false;
        });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load live streams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStreams() {
    setState(() {
      _filteredStreams = _streams.where((stream) {
        final matchesCategory = _selectedCategory == null || stream.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty || 
            stream.astrologerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            stream.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            stream.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterStreams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
    return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(themeService),
              _buildSearchBar(themeService),
              _buildTabBar(themeService),
              _buildContent(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: themeService.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: themeService.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Streams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeService.textPrimary,
              ),
            ),
            Text(
              '${_filteredStreams.length} astrologers live now',
              style: TextStyle(
                fontSize: 14,
                color: themeService.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: themeService.textPrimary,
          ),
          onPressed: _loadLiveStreams,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(ThemeService themeService) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeService.borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search astrologers, topics...',
              hintStyle: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: themeService.textSecondary,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: themeService.textSecondary,
                        size: 18,
                      ),
                      onPressed: () => _onSearchChanged(''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeService themeService) {
    final categories = [
      {'name': 'All', 'category': null},
      {'name': 'General', 'category': LiveStreamCategory.general},
      {'name': 'Tarot', 'category': LiveStreamCategory.tarot},
      {'name': 'Astrology', 'category': LiveStreamCategory.astrology},
      {'name': 'Reiki Healing', 'category': LiveStreamCategory.healing},
      {'name': 'Numerology', 'category': LiveStreamCategory.numerology},
      {'name': 'Palmistry', 'category': LiveStreamCategory.palmistry},
      {'name': 'Spiritual', 'category': LiveStreamCategory.spiritual},
      {'name': 'Meditation', 'category': LiveStreamCategory.meditation},
      {'name': 'Crystal Healing', 'category': LiveStreamCategory.healing},
      {'name': 'Vedic Remedies', 'category': LiveStreamCategory.astrology},
      {'name': 'Moon Reading', 'category': LiveStreamCategory.spiritual},
      {'name': 'Mantra Chanting', 'category': LiveStreamCategory.spiritual},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category['category'];
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedCategory = category['category'] as LiveStreamCategory?;
                    _filterStreams();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? themeService.primaryColor 
                        : themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? themeService.primaryColor 
                          : themeService.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Colors.white 
                            : themeService.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeService themeService) {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSkeletonStreamCard(themeService),
              );
            },
            childCount: 6, // Show 6 skeleton cards
          ),
        ),
      );
    }

    if (_filteredStreams.isEmpty) {
      return SliverFillRemaining(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.tv_off,
              size: 80,
                color: themeService.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
                _searchQuery.isNotEmpty
                    ? 'No streams found for "$_searchQuery"'
                    : 'No live streams available',
              style: TextStyle(
                  color: themeService.textSecondary,
                fontSize: 18,
                  fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Check back later for live sessions',
              style: TextStyle(
                  color: themeService.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
              if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _onSearchChanged(''),
              style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
              ),
                  child: const Text('Clear Search'),
            ),
          ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final stream = _filteredStreams[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStreamCard(stream, themeService),
            );
          },
          childCount: _filteredStreams.length,
        ),
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveStreamViewerScreen(liveStream: stream),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreamThumbnail(stream, themeService),
            _buildStreamInfo(stream, themeService),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamThumbnail(LiveStreamModel stream, ThemeService themeService) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor.withOpacity(0.8),
                themeService.primaryColor.withOpacity(0.6),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled_rounded,
                  size: 60,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 8),
            Text(
                  'Live Now',
              style: TextStyle(
                    color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${stream.viewerCount} watching',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamInfo(LiveStreamModel stream, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: themeService.primaryColor.withOpacity(0.1),
                child: Text(
                  stream.astrologerName.isNotEmpty
                      ? stream.astrologerName[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: themeService.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.astrologerName,
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      stream.specialty,
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(stream.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCategoryLabel(stream.category),
                  style: TextStyle(
                    color: _getCategoryColor(stream.category),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stream.title,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stream.description,
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${stream.rating.toStringAsFixed(1)}',
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.schedule_rounded,
                color: themeService.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${stream.duration} min',
                style: TextStyle(
                  color: themeService.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeService.textSecondary,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStreamCard(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton Thumbnail
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: themeService.backgroundColor,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Skeleton Live Badge
              Positioned(
                top: 12,
                left: 12,
                child: SkeletonLoader(
                  width: 50,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Skeleton Viewer Count
              Positioned(
                top: 12,
                right: 12,
                child: SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          // Skeleton Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton Astrologer Info
                Row(
                  children: [
                    SkeletonCircle(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 120,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 80,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    SkeletonLoader(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Skeleton Title
                SkeletonLoader(
                  width: double.infinity,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                // Skeleton Description
                SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                SkeletonLoader(
                  width: 200,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                // Skeleton Bottom Info
                Row(
                  children: [
                    SkeletonLoader(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 16),
                    SkeletonLoader(
                      width: 40,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Spacer(),
                    SkeletonLoader(
                      width: 16,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.astrology:
        return Colors.purple;
      case LiveStreamCategory.spiritual:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getCategoryLabel(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
      default:
        return 'General';
    }
  }
}