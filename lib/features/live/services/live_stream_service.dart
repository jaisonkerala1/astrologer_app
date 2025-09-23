import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/live_stream_model.dart';
import '../models/live_comment_model.dart';

class LiveStreamService extends ChangeNotifier {
  static final LiveStreamService _instance = LiveStreamService._internal();
  factory LiveStreamService() => _instance;
  LiveStreamService._internal();

  LiveStreamModel? _currentStream;
  List<LiveCommentModel> _comments = [];
  List<LiveStreamModel> _liveStreams = [];
  bool _isStreaming = false;
  Timer? _viewerCountTimer;
  Timer? _commentsTimer;
  final Random _random = Random();

  // Getters
  LiveStreamModel? get currentStream => _currentStream;
  List<LiveCommentModel> get comments => List.from(_comments);
  List<LiveStreamModel> get liveStreams => List.from(_liveStreams);
  bool get isStreaming => _isStreaming;
  int get viewerCount => _currentStream?.viewerCount ?? 0;
  int get totalViewers => _currentStream?.totalViewers ?? 0;
  int get likes => _currentStream?.likes ?? 0;
  int get commentsCount => _currentStream?.comments ?? 0;

  // Initialize with mock data
  void initialize() {
    _loadMockLiveStreams();
  }

  // Start a new live stream
  Future<bool> startLiveStream({
    required String title,
    String? description,
    required LiveStreamCategory category,
    LiveStreamQuality quality = LiveStreamQuality.medium,
    bool isPrivate = false,
    List<String> tags = const [],
  }) async {
    try {
      // Create new stream
      final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
      _currentStream = LiveStreamModel(
        id: streamId,
        astrologerId: 'current_user',
        astrologerName: 'Your Name',
        astrologerProfilePicture: null,
        title: title,
        description: description,
        category: category,
        status: LiveStreamStatus.preparing,
        quality: quality,
        startedAt: DateTime.now(),
        isPrivate: isPrivate,
        tags: tags,
        streamUrl: 'rtmp://mock-server.com/live/$streamId',
        thumbnailUrl: null,
      );

      _isStreaming = true;
      notifyListeners();

      // Simulate stream preparation
      await Future.delayed(const Duration(seconds: 2));

      // Start the stream
      _currentStream = _currentStream!.copyWith(
        status: LiveStreamStatus.live,
      );

      _startMockDataUpdates();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error starting live stream: $e');
      return false;
    }
  }

  // End current live stream
  Future<bool> endLiveStream() async {
    try {
      if (_currentStream == null) return false;

      _stopMockDataUpdates();

      _currentStream = _currentStream!.copyWith(
        status: LiveStreamStatus.ended,
        endedAt: DateTime.now(),
      );

      // Add to completed streams
      _liveStreams.insert(0, _currentStream!);
      _currentStream = null;
      _isStreaming = false;
      _comments.clear();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error ending live stream: $e');
      return false;
    }
  }

  // Pause/Resume stream
  Future<bool> toggleStreamPause() async {
    if (_currentStream == null) return false;

    final newStatus = _currentStream!.status == LiveStreamStatus.live
        ? LiveStreamStatus.paused
        : LiveStreamStatus.live;

    _currentStream = _currentStream!.copyWith(status: newStatus);
    notifyListeners();
    return true;
  }

  // Send comment
  Future<bool> sendComment({
    required String message,
    required String userId,
    required String userName,
    String? userProfilePicture,
  }) async {
    try {
      final comment = LiveCommentModel(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        userProfilePicture: userProfilePicture,
        message: message,
        type: LiveCommentType.comment,
        timestamp: DateTime.now(),
      );

      _comments.add(comment);
      _currentStream = _currentStream?.copyWith(
        comments: _currentStream!.comments + 1,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending comment: $e');
      return false;
    }
  }

  // Send reaction
  Future<bool> sendReaction({
    required String userId,
    required String userName,
    required LiveReactionType reaction,
  }) async {
    try {
      final reactionComment = LiveCommentModel(
        id: 'reaction_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        type: LiveCommentType.reaction,
        reaction: reaction,
        timestamp: DateTime.now(),
      );

      _comments.add(reactionComment);
      _currentStream = _currentStream?.copyWith(
        likes: _currentStream!.likes + 1,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending reaction: $e');
      return false;
    }
  }

  // Join live stream
  Future<bool> joinLiveStream(String streamId) async {
    try {
      final stream = _liveStreams.firstWhere(
        (s) => s.id == streamId,
        orElse: () => throw Exception('Stream not found'),
      );

      if (!stream.isLive) return false;

      _currentStream = stream;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error joining live stream: $e');
      return false;
    }
  }

  // Get live streams
  Future<List<LiveStreamModel>> getLiveStreams({
    LiveStreamCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay

      var filteredStreams = _liveStreams.where((stream) => stream.isLive);

      if (category != null) {
        filteredStreams = filteredStreams.where((stream) => stream.category == category);
      }

      return filteredStreams.skip(offset).take(limit).toList();
    } catch (e) {
      debugPrint('Error getting live streams: $e');
      return [];
    }
  }

  // Get stream comments
  Future<List<LiveCommentModel>> getStreamComments(String streamId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _comments.where((comment) => comment.type == LiveCommentType.comment).toList();
    } catch (e) {
      debugPrint('Error getting stream comments: $e');
      return [];
    }
  }

  // Mock data generation
  void _loadMockLiveStreams() {
    _liveStreams = [
      LiveStreamModel(
        id: 'stream_1',
        astrologerId: 'astro_1',
        astrologerName: 'Dr. Sarah Johnson',
        astrologerProfilePicture: null,
        title: 'Daily Tarot Reading - Love & Relationships',
        description: 'Join me for an insightful tarot reading session focusing on love and relationships.',
        category: LiveStreamCategory.tarot,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.high,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        viewerCount: 1247,
        totalViewers: 3456,
        likes: 892,
        comments: 156,
        tags: ['tarot', 'love', 'relationships'],
        streamUrl: 'rtmp://mock-server.com/live/stream_1',
      ),
      LiveStreamModel(
        id: 'stream_2',
        astrologerId: 'astro_2',
        astrologerName: 'Master Rajesh',
        astrologerProfilePicture: null,
        title: 'Palmistry Workshop - Learn to Read Palms',
        description: 'Interactive palmistry session where you can learn the basics of palm reading.',
        category: LiveStreamCategory.palmistry,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.medium,
        startedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        viewerCount: 892,
        totalViewers: 2134,
        likes: 567,
        comments: 89,
        tags: ['palmistry', 'workshop', 'learning'],
        streamUrl: 'rtmp://mock-server.com/live/stream_2',
      ),
      LiveStreamModel(
        id: 'stream_3',
        astrologerId: 'astro_3',
        astrologerName: 'Luna Mystic',
        astrologerProfilePicture: null,
        title: 'Meditation & Healing Session',
        description: 'Guided meditation for inner peace and spiritual healing.',
        category: LiveStreamCategory.meditation,
        status: LiveStreamStatus.live,
        quality: LiveStreamQuality.low,
        startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        viewerCount: 456,
        totalViewers: 1234,
        likes: 234,
        comments: 45,
        tags: ['meditation', 'healing', 'spiritual'],
        streamUrl: 'rtmp://mock-server.com/live/stream_3',
      ),
    ];
  }

  void _startMockDataUpdates() {
    // Update viewer count every 3-8 seconds
    _viewerCountTimer = Timer.periodic(Duration(seconds: 3 + _random.nextInt(6)), (timer) {
      if (_currentStream != null && _currentStream!.isLive) {
        final change = _random.nextInt(21) - 10; // -10 to +10
        final newCount = (_currentStream!.viewerCount + change).clamp(0, 99999);
        
        _currentStream = _currentStream!.copyWith(
          viewerCount: newCount,
          totalViewers: _currentStream!.totalViewers + (change > 0 ? change : 0),
        );
        notifyListeners();
      }
    });

    // Generate mock comments every 5-15 seconds
    _commentsTimer = Timer.periodic(Duration(seconds: 5 + _random.nextInt(11)), (timer) {
      if (_currentStream != null && _currentStream!.isLive) {
        _generateMockComment();
      }
    });
  }

  void _stopMockDataUpdates() {
    _viewerCountTimer?.cancel();
    _commentsTimer?.cancel();
    _viewerCountTimer = null;
    _commentsTimer = null;
  }

  void _generateMockComment() {
    final mockUsers = [
      {'name': 'Alex Chen', 'id': 'user_1'},
      {'name': 'Maria Rodriguez', 'id': 'user_2'},
      {'name': 'David Kim', 'id': 'user_3'},
      {'name': 'Emma Wilson', 'id': 'user_4'},
      {'name': 'James Brown', 'id': 'user_5'},
    ];

    final mockComments = [
      'Amazing reading! Thank you! 🙏',
      'This is so helpful!',
      'Can you read my palm next?',
      'Love your energy! ✨',
      'This resonates with me so much',
      'Thank you for the guidance',
      'Beautiful session!',
      'When is the next stream?',
      'You are amazing!',
      'This helped me a lot',
    ];

    final mockReactions = [
      LiveReactionType.heart,
      LiveReactionType.fire,
      LiveReactionType.clap,
      LiveReactionType.love,
    ];

    final user = mockUsers[_random.nextInt(mockUsers.length)];
    final isReaction = _random.nextBool();

    if (isReaction && _random.nextBool()) {
      // Send reaction
      final reaction = mockReactions[_random.nextInt(mockReactions.length)];
      sendReaction(
        userId: user['id']!,
        userName: user['name']!,
        reaction: reaction,
      );
    } else {
      // Send comment
      final comment = mockComments[_random.nextInt(mockComments.length)];
      sendComment(
        userId: user['id']!,
        userName: user['name']!,
        message: comment,
      );
    }
  }

  @override
  void dispose() {
    _stopMockDataUpdates();
    super.dispose();
  }
}











