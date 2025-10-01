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

  @override
  void initState() {
    super.initState();
    _loadLiveStreams();
  }

  Future<void> _loadLiveStreams() async {
    try {
      final streams = await _liveService.getLiveStreams();
        setState(() {
          _streams = streams;
        _filteredStreams = streams;
        });
    } catch (e) {
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
        return RefreshIndicator(
          onRefresh: _loadLiveStreams,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Streams',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connect with top astrologers live right now',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: themeService.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _loadLiveStreams();
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSearchBar(themeService),
                    ),
                    const SizedBox(height: 16),
                    // Category Chips
                    _buildCategoryChips(themeService),
                    const SizedBox(height: 16),
                    // Featured Section placeholder removed
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildStreamGrid(themeService),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeService.borderColor),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search astrologers or topics',
          hintStyle: TextStyle(color: themeService.textHint),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: themeService.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryChips(ThemeService themeService) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: LiveStreamCategory.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategory == null;
            return ChoiceChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = null;
                  _filterStreams();
                });
              },
            );
          }

          final category = LiveStreamCategory.values[index - 1];
          final isSelected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category.name.toUpperCase()),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
                _filterStreams();
              });
            },
          );
        },
      ),
    );
  }

  SliverGrid _buildStreamGrid(ThemeService themeService) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stream = _filteredStreams[index];
          return _LiveStreamTile(
            stream: stream,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamViewerScreen(liveStream: stream),
                ),
              );
            },
          );
        },
        childCount: _filteredStreams.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
    );
  }
}

class _LiveStreamTile extends StatelessWidget {
  final LiveStreamModel stream;
  final VoidCallback onTap;

  const _LiveStreamTile({
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(stream.thumbnailUrl ?? 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop&crop=face'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stream.category.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            stream.formattedViewerCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    stream.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: stream.astrologerProfilePicture != null
                            ? NetworkImage(stream.astrologerProfilePicture!)
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: stream.astrologerProfilePicture == null
                            ? Text(
                                stream.astrologerName.isNotEmpty
                                    ? stream.astrologerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stream.astrologerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}