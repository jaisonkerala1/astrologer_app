import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import 'live_stream_viewer_screen.dart';

class LiveStreamsScreen extends StatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  State<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen> {
  final LiveStreamService _liveService = LiveStreamService();
  LiveStreamCategory? _selectedCategory;
  List<LiveStreamModel> _streams = [];
  List<LiveStreamModel> _filteredStreams = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveStreams();
  }

  Future<void> _loadLiveStreams() async {
    setState(() => _isLoading = true);
    try {
      final streams = await _liveService.getLiveStreams();
      if (mounted) {
        setState(() {
          _streams = streams;
        _filteredStreams = streams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load live streams: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
      _searchQuery = query;
      _filterStreams();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
    return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadLiveStreams,
              color: themeService.primaryColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
            slivers: [
                  // Modern App Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'LIVE',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_filteredStreams.length} Streams',
                                          style: TextStyle(
                                            color: themeService.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
            Text(
              'Live Streams',
              style: TextStyle(
                color: themeService.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
              ),
            ),
                                    const SizedBox(height: 4),
            Text(
                                      'Connect with top astrologers live right now',
              style: TextStyle(
                                        color: themeService.textSecondary,
                fontSize: 14,
                                        fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
        IconButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _loadLiveStreams();
                                },
          icon: Icon(
            Icons.refresh_rounded,
                                  color: themeService.textSecondary,
                                ),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Search Bar
                          Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
            border: Border.all(
                                color: themeService.borderColor.withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
          ),
          child: TextField(
                              style: TextStyle(color: themeService.textPrimary),
            decoration: InputDecoration(
                                hintText: 'Search astrologers or topics',
              hintStyle: TextStyle(
                                  color: themeService.textHint,
                                  fontSize: 15,
              ),
                                border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: themeService.textSecondary,
                                  size: 22,
                                ),
              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // Category Filter Chips
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: LiveStreamCategory.values.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedCategory == null;
                            return _buildCategoryChip(
                              'All',
                              isSelected,
                              () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _filterStreams();
                              },
                              themeService,
                            );
                          }
                          final category = LiveStreamCategory.values[index - 1];
                          final isSelected = _selectedCategory == category;
                          return _buildCategoryChip(
                            _getCategoryName(category),
                            isSelected,
                            () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCategory = category;
                              });
                              _filterStreams();
                            },
                            themeService,
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  // Live Stream Grid
                  if (_isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildShimmerTile(themeService),
                          childCount: 6,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    )
                  else if (_filteredStreams.isEmpty)
                    SliverFillRemaining(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                              Icons.video_library_outlined,
                              size: 64,
                              color: themeService.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
                              'No live streams found',
              style: TextStyle(
                  color: themeService.textSecondary,
                                fontSize: 16,
                  fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                              'Try adjusting your filters',
              style: TextStyle(
                                color: themeService.textHint,
                fontSize: 14,
              ),
            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final stream = _filteredStreams[index];
                            return _buildStreamTile(stream, themeService);
                          },
                          childCount: _filteredStreams.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeService themeService,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? themeService.primaryColor
              : themeService.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? themeService.primaryColor
                : themeService.borderColor.withOpacity(0.5),
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : themeService.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamTile(LiveStreamModel stream, ThemeService themeService) {
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
          children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  stream.thumbnailUrl ?? 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop&crop=face',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: themeService.surfaceColor,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: themeService.textSecondary.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Badge & Viewer Count
                    Row(
                      children: [
                        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                            color: const Color(0xFFFF2D55),
                            borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                                width: 4,
                                height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                              Text(
                                _getCategoryName(stream.category).toUpperCase(),
                                style: const TextStyle(
                    color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye_rounded,
                                color: Colors.white,
                                size: 12,
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
                    const Spacer(),
                    // Title
                    Text(
                      stream.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Astrologer Info
          Row(
            children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            image: stream.astrologerProfilePicture != null
                                ? DecorationImage(
                                    image: NetworkImage(stream.astrologerProfilePicture!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: stream.astrologerProfilePicture == null
                              ? Center(
                child: Text(
                  stream.astrologerName.isNotEmpty
                      ? stream.astrologerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                )
                              : null,
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
                              if (stream.isVerified)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: Colors.blue[400],
                                    ),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'Verified',
                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                            ],
                ),
              ),
            ],
          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerTile(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
                decoration: BoxDecoration(
                color: themeService.borderColor.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeService.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                      width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: themeService.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return 'General';
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.tarot:
        return 'Tarot';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
    }
  }
}
