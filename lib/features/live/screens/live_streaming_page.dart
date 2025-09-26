import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../widgets/live_stream_card.dart';
import '../widgets/live_stream_search_bar.dart';
import '../widgets/live_stream_category_tabs.dart';
import '../models/live_stream_model.dart';

class LiveStreamingPage extends StatefulWidget {
  const LiveStreamingPage({super.key});

  @override
  State<LiveStreamingPage> createState() => _LiveStreamingPageState();
}

class _LiveStreamingPageState extends State<LiveStreamingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _categories = [
    'All',
    'Vedic',
    'Tarot',
    'Numerology',
    'Palmistry',
    'Crystal',
    'Vastu',
    'Astrology',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    HapticFeedback.lightImpact();
    debugPrint('🎯 Category changed to: $category');
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  List<LiveStreamCardModel> _getFilteredStreams() {
    List<LiveStreamCardModel> streams = _getMockLiveStreams();
    
    // Filter by category (case-insensitive)
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
      streams = streams.where((stream) => 
        stream.category.toLowerCase().trim() == _selectedCategory.toLowerCase().trim()
      ).toList();
    }
    
    // Filter by search query (case-insensitive, partial matching)
    if (_searchQuery.isNotEmpty && _searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      streams = streams.where((stream) =>
        stream.astrologerName.toLowerCase().contains(query) ||
        stream.title.toLowerCase().contains(query) ||
        stream.category.toLowerCase().contains(query)
      ).toList();
    }
    
    return streams;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(themeService),
                
                // Search Bar
                LiveStreamSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  isSearching: _isSearching,
                ),
                
                // Category Tabs
                LiveStreamCategoryTabs(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
                
                // Content
                Expanded(
                  child: _buildContent(themeService),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeService.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: themeService.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Live Streams',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Live indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_getFilteredStreams().length} astrologers live now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFilterOptions();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeService.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.tune,
                size: 20,
                color: themeService.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeService themeService) {
    final filteredStreams = _getFilteredStreams();
    
    if (filteredStreams.isEmpty) {
      return _buildEmptyState(themeService);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        // TODO: Refresh live streams
        await Future.delayed(const Duration(seconds: 1));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredStreams.length,
        itemBuilder: (context, index) {
          final stream = filteredStreams[index];
          return LiveStreamCard(
            stream: stream,
            onTap: () => _joinStream(stream),
            onLongPress: () => _showStreamOptions(stream),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: themeService.borderColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.live_tv,
              size: 48,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSearching ? 'No streams found' : 'No live streams',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching 
              ? 'Try adjusting your search or filters'
              : 'Check back later for live sessions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _joinStream(LiveStreamCardModel stream) {
    HapticFeedback.mediumImpact();
    // TODO: Navigate to live stream viewer
    debugPrint('Joining stream: ${stream.title} by ${stream.astrologerName}');
  }

  void _showStreamOptions(LiveStreamCardModel stream) {
    HapticFeedback.mediumImpact();
    // TODO: Show stream options (share, report, etc.)
    debugPrint('Showing options for stream: ${stream.title}');
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeService.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter Streams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Filter options would go here
              Text(
                'Filter options coming soon...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeService.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  List<LiveStreamCardModel> _getMockLiveStreams() {
    return [
      // VEDIC CATEGORY
      LiveStreamCardModel(
        id: '1',
        astrologerName: 'Astro Priya',
        title: 'Daily Vedic Predictions',
        category: 'Vedic',
        viewerCount: 1234,
        thumbnailUrl: 'https://picsum.photos/id/10/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/1.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LiveStreamCardModel(
        id: '2',
        astrologerName: 'Vedic Scholar',
        title: 'Mantra Chanting Session',
        category: 'Vedic',
        viewerCount: 2341,
        thumbnailUrl: 'https://picsum.photos/id/11/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/8.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      LiveStreamCardModel(
        id: '3',
        astrologerName: 'Pandit Rajesh',
        title: 'Vedic Remedies & Solutions',
        category: 'Vedic',
        viewerCount: 1890,
        thumbnailUrl: 'https://picsum.photos/id/12/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/9.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),

      // TAROT CATEGORY
      LiveStreamCardModel(
        id: '4',
        astrologerName: 'Tarot Raj',
        title: 'Tarot Card Readings',
        category: 'Tarot',
        viewerCount: 856,
        thumbnailUrl: 'https://picsum.photos/id/20/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/2.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      LiveStreamCardModel(
        id: '5',
        astrologerName: 'Mystic Sarah',
        title: 'Love & Relationship Tarot',
        category: 'Tarot',
        viewerCount: 1520,
        thumbnailUrl: 'https://picsum.photos/id/21/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/10.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LiveStreamCardModel(
        id: '6',
        astrologerName: 'Card Master Alex',
        title: 'Career Guidance Tarot',
        category: 'Tarot',
        viewerCount: 980,
        thumbnailUrl: 'https://picsum.photos/id/22/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/11.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),

      // NUMEROLOGY CATEGORY
      LiveStreamCardModel(
        id: '7',
        astrologerName: 'Numerologist S.',
        title: 'Number Magic Session',
        category: 'Numerology',
        viewerCount: 2103,
        thumbnailUrl: 'https://picsum.photos/id/30/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/3.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
      LiveStreamCardModel(
        id: '8',
        astrologerName: 'Number Guru Mike',
        title: 'Life Path Numbers',
        category: 'Numerology',
        viewerCount: 1675,
        thumbnailUrl: 'https://picsum.photos/id/31/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/12.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      LiveStreamCardModel(
        id: '9',
        astrologerName: 'Divine Numbers',
        title: 'Name Numerology Analysis',
        category: 'Numerology',
        viewerCount: 1340,
        thumbnailUrl: 'https://picsum.photos/id/32/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/13.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 50)),
      ),

      // PALMISTRY CATEGORY
      LiveStreamCardModel(
        id: '10',
        astrologerName: 'Palmistry Guru',
        title: 'Palm Reading Masterclass',
        category: 'Palmistry',
        viewerCount: 567,
        thumbnailUrl: 'https://picsum.photos/id/40/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/4.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      LiveStreamCardModel(
        id: '11',
        astrologerName: 'Palm Reader Lisa',
        title: 'Future Life Predictions',
        category: 'Palmistry',
        viewerCount: 890,
        thumbnailUrl: 'https://picsum.photos/id/41/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/14.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      ),
      LiveStreamCardModel(
        id: '12',
        astrologerName: 'Hand Analysis Pro',
        title: 'Career & Success Lines',
        category: 'Palmistry',
        viewerCount: 1120,
        thumbnailUrl: 'https://picsum.photos/id/42/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/15.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 35)),
      ),

      // CRYSTAL CATEGORY
      LiveStreamCardModel(
        id: '13',
        astrologerName: 'Crystal Healer',
        title: 'Crystal Energy Healing',
        category: 'Crystal',
        viewerCount: 3120,
        thumbnailUrl: 'https://picsum.photos/id/50/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/5.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      LiveStreamCardModel(
        id: '14',
        astrologerName: 'Crystal Master',
        title: 'Chakra Balancing Session',
        category: 'Crystal',
        viewerCount: 2150,
        thumbnailUrl: 'https://picsum.photos/id/51/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/16.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
      LiveStreamCardModel(
        id: '15',
        astrologerName: 'Gemstone Guide',
        title: 'Birthstone Healing',
        category: 'Crystal',
        viewerCount: 1780,
        thumbnailUrl: 'https://picsum.photos/id/52/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/17.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 25)),
      ),

      // VASTU CATEGORY
      LiveStreamCardModel(
        id: '16',
        astrologerName: 'Vastu Expert',
        title: 'Home Vastu Consultation',
        category: 'Vastu',
        viewerCount: 1456,
        thumbnailUrl: 'https://picsum.photos/id/60/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/6.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LiveStreamCardModel(
        id: '17',
        astrologerName: 'Vastu Consultant',
        title: 'Office Space Energy',
        category: 'Vastu',
        viewerCount: 920,
        thumbnailUrl: 'https://picsum.photos/id/61/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/18.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      ),
      LiveStreamCardModel(
        id: '18',
        astrologerName: 'Feng Shui Master',
        title: 'Home Harmony Tips',
        category: 'Vastu',
        viewerCount: 1560,
        thumbnailUrl: 'https://picsum.photos/id/62/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/19.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 40)),
      ),

      // ASTROLOGY CATEGORY
      LiveStreamCardModel(
        id: '19',
        astrologerName: 'Astro Master',
        title: 'Birth Chart Analysis',
        category: 'Astrology',
        viewerCount: 789,
        thumbnailUrl: 'https://picsum.photos/id/70/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/7.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      LiveStreamCardModel(
        id: '20',
        astrologerName: 'Star Reader',
        title: 'Planetary Transits',
        category: 'Astrology',
        viewerCount: 1340,
        thumbnailUrl: 'https://picsum.photos/id/71/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/20.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      ),
      LiveStreamCardModel(
        id: '21',
        astrologerName: 'Cosmic Guide',
        title: 'Zodiac Compatibility',
        category: 'Astrology',
        viewerCount: 1980,
        thumbnailUrl: 'https://picsum.photos/id/72/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/men/21.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      LiveStreamCardModel(
        id: '22',
        astrologerName: 'Planetary Expert',
        title: 'Mercury Retrograde Guide',
        category: 'Astrology',
        viewerCount: 2450,
        thumbnailUrl: 'https://picsum.photos/id/73/400/600',
        profilePicture: 'https://randomuser.me/api/portraits/women/22.jpg',
        isLive: true,
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      ),
    ];
  }
}
