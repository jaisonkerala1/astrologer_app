import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../widgets/live_stream_card.dart';

class LiveStreamsScreen extends StatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  State<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen>
    with TickerProviderStateMixin {
  final LiveStreamService _liveService = LiveStreamService();
  late TabController _tabController;
  LiveStreamCategory? _selectedCategory;
  bool _isLoading = false;
  List<LiveStreamModel> _streams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLiveStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveStreams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final streams = await _liveService.getLiveStreams(
        category: _selectedCategory,
      );
      
      if (mounted) {
        setState(() {
          _streams = streams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading streams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Live Streams',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Live Now'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveStreamsList(),
          _buildCategoriesGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goLive,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.videocam),
        label: const Text('Go Live'),
      ),
    );
  }

  Widget _buildLiveStreamsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_streams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Live Streams',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start a live stream!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _goLive,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.videocam),
              label: const Text('Start Streaming'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLiveStreams,
      color: Colors.red,
      backgroundColor: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _streams.length,
        itemBuilder: (context, index) {
          final stream = _streams[index];
          return LiveStreamCard(
            stream: stream,
            onTap: () => _joinStream(stream),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: LiveStreamCategory.values.length,
        itemBuilder: (context, index) {
          final category = LiveStreamCategory.values[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(LiveStreamCategory category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
        _loadLiveStreams();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.red.withOpacity(0.8), Colors.pink.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 40,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              _getCategoryDisplayName(category),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${_getCategoryStreamCount(category)} streams',
              style: TextStyle(
                color: isSelected 
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return Icons.public;
      case LiveStreamCategory.astrology:
        return Icons.star;
      case LiveStreamCategory.healing:
        return Icons.healing;
      case LiveStreamCategory.meditation:
        return Icons.self_improvement;
      case LiveStreamCategory.tarot:
        return Icons.style;
      case LiveStreamCategory.numerology:
        return Icons.numbers;
      case LiveStreamCategory.palmistry:
        return Icons.contact_page;
      case LiveStreamCategory.spiritual:
        return Icons.auto_awesome;
    }
  }

  String _getCategoryDisplayName(LiveStreamCategory category) {
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

  int _getCategoryStreamCount(LiveStreamCategory category) {
    return _streams.where((stream) => stream.category == category).length;
  }

  void _goLive() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/live-preparation');
  }

  void _joinStream(LiveStreamModel stream) {
    HapticFeedback.lightImpact();
    // Navigate to audience view screen
    Navigator.pushNamed(context, '/live-audience', arguments: stream);
  }
}
