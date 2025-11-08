import 'dart:math';
import '../../models/live_stream_model.dart';
import 'live_feed_repository.dart';

/// Mock implementation of LiveFeedRepository
/// Uses simulated data until backend with Agora is ready
class MockLiveFeedRepository implements LiveFeedRepository {
  final Random _random = Random();
  
  // Mock categories
  static const List<String> _categories = [
    'Astrology',
    'Tarot',
    'Numerology',
    'Palmistry',
    'Vastu',
    'Gemstones',
  ];
  
  // Mock astrologer data
  static const List<Map<String, String>> _astrologers = [
    {'name': 'Dr. Rajesh Kumar', 'image': 'https://i.pravatar.cc/150?img=12', 'specialty': 'Vedic Astrology'},
    {'name': 'Priya Sharma', 'image': 'https://i.pravatar.cc/150?img=45', 'specialty': 'Tarot Reading'},
    {'name': 'Amit Patel', 'image': 'https://i.pravatar.cc/150?img=33', 'specialty': 'Numerology'},
    {'name': 'Sanjana Singh', 'image': 'https://i.pravatar.cc/150?img=47', 'specialty': 'Palmistry'},
    {'name': 'Vikram Mehta', 'image': 'https://i.pravatar.cc/150?img=51', 'specialty': 'Vastu Shastra'},
    {'name': 'Kavita Desai', 'image': 'https://i.pravatar.cc/150?img=29', 'specialty': 'Gemstone Therapy'},
    {'name': 'Rahul Joshi', 'image': 'https://i.pravatar.cc/150?img=68', 'specialty': 'Astrology'},
    {'name': 'Neha Gupta', 'image': 'https://i.pravatar.cc/150?img=25', 'specialty': 'Tarot'},
    {'name': 'Arjun Reddy', 'image': 'https://i.pravatar.cc/150?img=13', 'specialty': 'Numerology'},
    {'name': 'Meera Nair', 'image': 'https://i.pravatar.cc/150?img=44', 'specialty': 'Palmistry'},
    {'name': 'Rohan Das', 'image': 'https://i.pravatar.cc/150?img=59', 'specialty': 'Vedic Astrology'},
    {'name': 'Ananya Iyer', 'image': 'https://i.pravatar.cc/150?img=23', 'specialty': 'Tarot Reading'},
    {'name': 'Karan Malhotra', 'image': 'https://i.pravatar.cc/150?img=56', 'specialty': 'Astrology'},
    {'name': 'Shreya Kapoor', 'image': 'https://i.pravatar.cc/150?img=31', 'specialty': 'Gemstones'},
    {'name': 'Aditya Verma', 'image': 'https://i.pravatar.cc/150?img=52', 'specialty': 'Vastu'},
  ];
  
  // Mock titles for live streams
  static const List<String> _streamTitles = [
    '🌟 Live Astrology Reading',
    '🔮 Tarot Card Session',
    '✨ Daily Predictions & Guidance',
    '💫 Kundli Analysis Live',
    '🌙 Moon Sign Reading',
    '⭐ Weekly Horoscope Discussion',
    '🎴 Tarot for Love & Career',
    '🔢 Numerology Consultation',
    '👋 Palmistry & Life Path',
    '🏠 Vastu Tips for Home',
    '💎 Gemstone Recommendations',
    '🌞 Sun Sign Compatibility',
    '📿 Spiritual Guidance Session',
    '🌸 Meditation & Astrology',
    '🎯 Career & Business Predictions',
  ];
  
  // Store generated streams for consistency
  final List<LiveStreamModel> _allStreams = [];
  bool _initialized = false;
  
  /// Initialize mock data
  void _initializeStreams() {
    if (_initialized) return;
    
    for (int i = 0; i < 15; i++) {
      final astrologer = _astrologers[i % _astrologers.length];
      final categoryName = _categories[_random.nextInt(_categories.length)];
      
      // Map string category to enum
      final categoryEnum = _mapCategoryToEnum(categoryName);
      
      _allStreams.add(LiveStreamModel(
        id: 'stream_${i + 1}',
        astrologerId: 'astro_${i + 1}',
        astrologerName: astrologer['name']!,
        astrologerProfilePicture: astrologer['image']!,
        astrologerSpecialty: astrologer['specialty']!,
        title: _streamTitles[i],
        description: 'Live $categoryName session with ${astrologer['name']}',
        category: categoryEnum,
        thumbnailUrl: astrologer['image']!,
        viewerCount: _random.nextInt(500) + 50, // 50-550 viewers
        likes: _random.nextInt(1000) + 100,
        isLive: true,
        startedAt: DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
        tags: [categoryName, 'Live', 'Consultation'],
        rating: 4.0 + _random.nextDouble(),
        totalSessions: _random.nextInt(500) + 100,
        language: 'English',
        isVerified: _random.nextBool(),
        duration: _random.nextInt(120),
      ));
    }
    
    // Sort by viewers (like Instagram/YouTube)
    _allStreams.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
    
    _initialized = true;
  }
  
  /// Map category string to enum
  LiveStreamCategory _mapCategoryToEnum(String category) {
    switch (category.toLowerCase()) {
      case 'astrology':
        return LiveStreamCategory.astrology;
      case 'tarot':
        return LiveStreamCategory.tarot;
      case 'numerology':
        return LiveStreamCategory.numerology;
      case 'palmistry':
        return LiveStreamCategory.palmistry;
      case 'vastu':
      case 'gemstones':
        return LiveStreamCategory.spiritual;
      default:
        return LiveStreamCategory.general;
    }
  }
  
  @override
  Future<List<LiveStreamModel>> getActiveLiveStreams({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    _initializeStreams();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Filter by category if provided
    List<LiveStreamModel> streams = _allStreams;
    if (category != null && category.isNotEmpty) {
      final categoryEnum = _mapCategoryToEnum(category);
      streams = _allStreams.where((s) => s.category == categoryEnum).toList();
    }
    
    // Pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= streams.length) {
      return []; // No more streams
    }
    
    return streams.sublist(
      startIndex,
      endIndex > streams.length ? streams.length : endIndex,
    );
  }
  
  @override
  Future<LiveStreamModel> getLiveStreamById(String streamId) async {
    _initializeStreams();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      return _allStreams.firstWhere((s) => s.id == streamId);
    } catch (e) {
      throw Exception('Stream not found: $streamId');
    }
  }
  
  @override
  Future<void> preloadStreamData(String streamId) async {
    // Simulate preloading (no-op for mock)
    // In real implementation:
    // - Fetch Agora token
    // - Get channel credentials
    // - Preload stream metadata
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  @override
  Future<List<String>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    return List.from(_categories);
  }
  
  @override
  Future<Map<String, dynamic>> joinStream(String streamId) async {
    _initializeStreams();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Mock join data (ready for Agora integration)
    return {
      'success': true,
      'streamId': streamId,
      'channelName': 'channel_$streamId',
      'token': 'mock_agora_token_${DateTime.now().millisecondsSinceEpoch}',
      'uid': _random.nextInt(100000),
      'appId': 'mock_app_id',
      // Future: Add real Agora credentials here
    };
  }
  
  @override
  Future<void> leaveStream(String streamId) async {
    // Simulate leaving stream
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In real implementation:
    // - Notify backend
    // - Cleanup Agora resources
    // - Update viewer count
  }
}

