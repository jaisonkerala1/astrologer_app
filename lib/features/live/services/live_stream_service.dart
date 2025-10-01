import 'package:flutter/foundation.dart';
import '../models/live_stream_model.dart';
import '../models/live_comment_model.dart';
import '../models/live_reaction_model.dart';
import '../models/live_gift_model.dart';

class LiveStreamService extends ChangeNotifier {
  static final LiveStreamService _instance = LiveStreamService._internal();
  factory LiveStreamService() => _instance;
  LiveStreamService._internal();

  final Map<String, List<LiveCommentModel>> _comments = {};
  final Map<String, List<LiveReactionModel>> _reactions = {};
  final Map<String, List<LiveGiftModel>> _gifts = {};
  final Map<String, int> _viewerCounts = {};
  
  LiveStreamModel? _currentStream;
  int _currentLikes = 0;

  LiveStreamModel? get currentStream => _currentStream;
  int get currentLikes => _currentLikes;

  List<LiveCommentModel> get comments {
    final streamId = _currentStream?.id;
    if (streamId == null) return const [];
    return List.unmodifiable(_comments[streamId] ?? []);
  }

  // Mock data for live streams
  List<LiveStreamModel> getMockLiveStreams() {
    return [
      LiveStreamModel(
        id: '1',
        astrologerId: 'astrologer_1',
        astrologerName: 'Priya Sharma',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Vedic Astrology',
        title: 'Daily Horoscope Reading',
        description: 'Join me for today\'s horoscope reading and get insights about your day ahead!',
        viewerCount: 234,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop&crop=face',
        tags: ['horoscope', 'daily', 'vedic'],
        rating: 4.8,
        totalSessions: 1250,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.astrology,
        duration: 45,
      ),
      LiveStreamModel(
        id: '2',
        astrologerId: 'astrologer_2',
        astrologerName: 'Raj Kumar',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Tarot Reading',
        title: 'Tarot Card Reading Session',
        description: 'Let\'s explore what the cards have to say about your future!',
        viewerCount: 189,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        tags: ['tarot', 'cards', 'future'],
        rating: 4.6,
        totalSessions: 890,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.astrology,
        duration: 60,
      ),
      LiveStreamModel(
        id: '3',
        astrologerId: 'astrologer_3',
        astrologerName: 'Anita Singh',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Numerology',
        title: 'Numerology Consultation',
        description: 'Discover your life path number and its significance!',
        viewerCount: 156,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 22)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        tags: ['numerology', 'numbers', 'life path'],
        rating: 4.9,
        totalSessions: 2100,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.astrology,
        duration: 30,
      ),
      LiveStreamModel(
        id: '4',
        astrologerId: 'astrologer_4',
        astrologerName: 'Vikram Joshi',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Palmistry',
        title: 'Palm Reading Session',
        description: 'Let me read your palm and reveal your destiny!',
        viewerCount: 98,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        tags: ['palmistry', 'palm reading', 'destiny'],
        rating: 4.7,
        totalSessions: 750,
        language: 'English',
        isVerified: false,
        category: LiveStreamCategory.astrology,
        duration: 40,
      ),
      LiveStreamModel(
        id: '5',
        astrologerId: 'astrologer_5',
        astrologerName: 'Sita Devi',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Crystal Healing',
        title: 'Crystal Healing Meditation',
        description: 'Join me for a peaceful crystal healing session!',
        viewerCount: 312,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        tags: ['crystal', 'healing', 'meditation'],
        rating: 4.8,
        totalSessions: 1800,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.spiritual,
        duration: 90,
      ),
      LiveStreamModel(
        id: '6',
        astrologerId: 'astrologer_6',
        astrologerName: 'Dr. Maya Patel',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Vedic Remedies',
        title: 'Vedic Remedies for Health',
        description: 'Learn ancient Vedic remedies for modern health issues!',
        viewerCount: 445,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 18)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face',
        tags: ['vedic', 'remedies', 'health'],
        rating: 4.9,
        totalSessions: 3200,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.astrology,
        duration: 75,
      ),
      LiveStreamModel(
        id: '7',
        astrologerId: 'astrologer_7',
        astrologerName: 'Guru Ravi',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Spiritual Guidance',
        title: 'Spiritual Awakening Session',
        description: 'Embark on a journey of spiritual awakening and self-discovery!',
        viewerCount: 278,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
        tags: ['spiritual', 'awakening', 'guidance'],
        rating: 4.7,
        totalSessions: 1500,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.spiritual,
        duration: 120,
      ),
      LiveStreamModel(
        id: '8',
        astrologerId: 'astrologer_8',
        astrologerName: 'Luna Moon',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Moon Reading',
        title: 'Lunar Energy Reading',
        description: 'Connect with lunar energies and understand moon phases!',
        viewerCount: 167,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop&crop=face',
        tags: ['moon', 'lunar', 'energy'],
        rating: 4.6,
        totalSessions: 980,
        language: 'English',
        isVerified: false,
        category: LiveStreamCategory.spiritual,
        duration: 50,
      ),
      LiveStreamModel(
        id: '9',
        astrologerId: 'astrologer_9',
        astrologerName: 'Master Krishna',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Mantra Chanting',
        title: 'Sacred Mantra Chanting',
        description: 'Join us for powerful mantra chanting and meditation!',
        viewerCount: 523,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop&crop=face',
        tags: ['mantra', 'chanting', 'sacred'],
        rating: 4.8,
        totalSessions: 2500,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.spiritual,
        duration: 60,
      ),
      LiveStreamModel(
        id: '10',
        astrologerId: 'astrologer_10',
        astrologerName: 'Sage Vishnu',
        astrologerProfilePicture: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        astrologerSpecialty: 'Vedic Astrology',
        title: 'Birth Chart Analysis',
        description: 'Deep dive into your birth chart and planetary positions!',
        viewerCount: 89,
        isLive: true,
        startedAt: DateTime.now().subtract(const Duration(minutes: 7)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        tags: ['birth chart', 'planets', 'vedic'],
        rating: 4.9,
        totalSessions: 1800,
        language: 'English',
        isVerified: true,
        category: LiveStreamCategory.astrology,
        duration: 90,
      ),
    ];
  }

  Future<List<LiveStreamModel>> getLiveStreams() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return getMockLiveStreams();
  }

  Future<LiveStreamModel?> getLiveStream(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final streams = getMockLiveStreams();
    try {
      return streams.firstWhere((stream) => stream.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<LiveStreamModel>> getActiveLiveStreams() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return getMockLiveStreams().where((stream) => stream.isLive).toList();
  }

  Future<void> joinLiveStream(String streamId) async {
    await Future.delayed(const Duration(seconds: 1));
    _viewerCounts[streamId] = (_viewerCounts[streamId] ?? 0) + 1;
    _initializeMockData(streamId);
  }

  Future<void> leaveLiveStream(String streamId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _viewerCounts[streamId] = (_viewerCounts[streamId] ?? 1) - 1;
  }

  Future<List<LiveCommentModel>> getComments(String streamId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _comments[streamId] ?? [];
  }

  Future<void> sendComment(String streamId, String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final comment = LiveCommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      streamId: streamId,
      userId: 'current_user',
      userName: 'You',
      userProfilePicture: null,
      message: message,
      timestamp: DateTime.now(),
      isHost: false,
    );
    
    _comments[streamId] = (_comments[streamId] ?? [])..add(comment);
    notifyListeners();
  }

  Future<List<LiveReactionModel>> getReactions(String streamId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reactions[streamId] ?? [];
  }

  Future<void> sendReaction(String streamId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final reaction = LiveReactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      streamId: streamId,
      userId: 'current_user',
      userName: 'You',
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    
    _reactions[streamId] = (_reactions[streamId] ?? [])..add(reaction);
    notifyListeners();
  }

  Future<List<LiveGiftModel>> getGifts(String streamId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _gifts[streamId] ?? [];
  }

  Future<void> sendGift(String streamId, LiveGiftModel gift) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _gifts[streamId] = (_gifts[streamId] ?? [])..add(gift);
    notifyListeners();
  }

  void incrementLikes() {
    _currentLikes++;
    if (_currentStream != null) {
      _currentStream = _currentStream!.copyWith(likes: _currentLikes);
      notifyListeners();
    }
  }

  Future<bool> startLiveStream({
    required String title,
    String? description,
    required LiveStreamCategory category,
    required LiveStreamQuality quality,
    required bool isPrivate,
    required List<String> tags,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create current stream
      _currentStream = LiveStreamModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        astrologerId: 'current_astrologer',
        astrologerName: 'You',
        astrologerSpecialty: _getCategoryDisplayName(category),
        title: title,
        description: description ?? '',
        viewerCount: 0,
        isLive: true,
        startedAt: DateTime.now(),
        tags: tags,
        rating: 0.0,
        totalSessions: 0,
        language: 'English',
        isVerified: false,
        likes: 0,
      );
      
      _currentLikes = 0;
      if (kDebugMode) {
        debugPrint('🎥 [LIVE_SERVICE] Stream created: ${_currentStream?.id}');
        debugPrint('🎥 [LIVE_SERVICE] Stream title: ${_currentStream?.title}');
      }
      notifyListeners();
      
      // Mock successful stream start
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting live stream: $e');
      }
      return false;
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

  Future<bool> endLiveStream([String? streamId]) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Clear current stream
      _currentStream = null;
      _currentLikes = 0;
      notifyListeners();
      
      // Mock successful stream end
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error ending live stream: $e');
      }
      return false;
    }
  }

  void _initializeMockData(String streamId) {
    if (_comments[streamId] == null) {
      _comments[streamId] = [
        LiveCommentModel(
          id: '1',
          streamId: streamId,
          userId: 'user_1',
          userName: 'Sarah M.',
          userProfilePicture: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face',
          message: 'Amazing reading! Thank you so much! 🙏',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isHost: false,
        ),
        LiveCommentModel(
          id: '2',
          streamId: streamId,
          userId: 'user_2',
          userName: 'Mike R.',
          userProfilePicture: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
          message: 'Can you read my chart next?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          isHost: false,
        ),
        LiveCommentModel(
          id: '3',
          streamId: streamId,
          userId: 'host',
          userName: 'You',
          userProfilePicture: null,
          message: 'Welcome everyone! Let me know your questions.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          isHost: true,
        ),
      ];
    }

    if (_reactions[streamId] == null) {
      _reactions[streamId] = [
        LiveReactionModel(
          id: '1',
          streamId: streamId,
          userId: 'user_1',
          userName: 'Sarah M.',
          emoji: '❤️',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ];
    }

    if (_gifts[streamId] == null) {
      _gifts[streamId] = [
        LiveGiftModel(
          id: '1',
          streamId: streamId,
          userId: 'user_1',
          userName: 'Sarah M.',
          giftName: 'Rose',
          giftEmoji: '🌹',
          giftValue: 10,
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ];
    }
  }
}