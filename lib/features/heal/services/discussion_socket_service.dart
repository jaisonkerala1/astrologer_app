import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/services/storage_service.dart';
import '../models/discussion_models.dart';

/// Professional Socket.IO Service for Real-time Discussion Features
/// Handles all WebSocket connections and real-time events
/// Provides Facebook-level real-time experience
class DiscussionSocketService {
  // Singleton pattern
  static final DiscussionSocketService _instance = DiscussionSocketService._internal();
  factory DiscussionSocketService() => _instance;
  DiscussionSocketService._internal();

  // Socket.IO instance
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Railway production server
  static const String _serverUrl = 'https://astrologerapp-production.up.railway.app';
  
  final StorageService _storageService = StorageService();

  // ============================================
  // CONNECTION MANAGEMENT
  // ============================================

  /// Connect to Socket.IO server with authentication
  Future<void> connect() async {
    if (_isConnected && _socket != null) {
      print('🔌 Already connected to Socket.IO');
      return;
    }

    try {
      // Get JWT token for authentication
      final token = await _storageService.getAuthToken();
      
      if (token == null) {
        print('⚠️ No JWT token found, connecting as anonymous');
      }

      // Configure Socket.IO client
      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Use WebSocket only
            .disableAutoConnect() // Manual connection control
            .setAuth({'token': token ?? ''}) // JWT authentication
            .setExtraHeaders({'Authorization': 'Bearer ${token ?? ''}'})
            .build(),
      );

      // Setup event listeners
      _setupEventListeners();

      // Connect
      _socket!.connect();
      print('🔌 Connecting to Socket.IO server...');
    } catch (e) {
      print('❌ Error connecting to Socket.IO: $e');
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('❌ Disconnected from Socket.IO');
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Setup core event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.on('connect', (_) {
      _isConnected = true;
      print('✅ Socket.IO connected successfully');
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      print('❌ Socket.IO disconnected');
    });

    _socket!.on('authenticated', (data) {
      print('✅ Socket.IO authenticated: ${data['user']['name']}');
    });

    _socket!.on('error', (error) {
      print('❌ Socket.IO error: $error');
    });

    _socket!.on('connect_error', (error) {
      print('❌ Socket.IO connection error: $error');
    });
  }

  // ============================================
  // DISCUSSION ROOM MANAGEMENT
  // ============================================

  /// Join a discussion room to receive real-time updates
  void joinDiscussion(String discussionId) {
    if (_socket == null || !_isConnected) {
      print('⚠️ Socket not connected, cannot join discussion');
      return;
    }

    _socket!.emit('discussion:join', discussionId);
    print('👥 Joined discussion room: $discussionId');
  }

  /// Leave a discussion room
  void leaveDiscussion(String discussionId) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit('discussion:leave', discussionId);
    print('👋 Left discussion room: $discussionId');
  }

  // ============================================
  // TYPING INDICATORS
  // ============================================

  /// Emit typing indicator
  void startTyping(String discussionId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('comment:typing', discussionId);
  }

  /// Emit stop typing indicator
  void stopTyping(String discussionId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('comment:stop-typing', discussionId);
  }

  // ============================================
  // REAL-TIME EVENT LISTENERS
  // ============================================

  /// Listen to new discussions created
  void onDiscussionCreated(Function(DiscussionPost discussion, Map<String, dynamic> author) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:created', (data) {
      try {
        final discussion = DiscussionPost.fromJson(data['discussion']);
        final author = data['author'];
        callback(discussion, author);
      } catch (e) {
        print('Error parsing discussion:created event: $e');
      }
    });
  }

  /// Listen to discussion updates
  void onDiscussionUpdated(Function(String discussionId, DiscussionPost discussion) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:updated', (data) {
      try {
        final discussionId = data['discussionId'];
        final discussion = DiscussionPost.fromJson(data['discussion']);
        callback(discussionId, discussion);
      } catch (e) {
        print('Error parsing discussion:updated event: $e');
      }
    });
  }

  /// Listen to discussion deletions
  void onDiscussionDeleted(Function(String discussionId) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:deleted', (data) {
      try {
        final discussionId = data['discussionId'];
        callback(discussionId);
      } catch (e) {
        print('Error parsing discussion:deleted event: $e');
      }
    });
  }

  /// Listen to new comments (REAL-TIME!)
  void onCommentAdded(Function(String discussionId, DiscussionComment comment, Map<String, dynamic> author) callback) {
    if (_socket == null) return;

    _socket!.on('comment:added', (data) {
      try {
        final discussionId = data['discussionId'];
        final comment = DiscussionComment.fromJson(data['comment']);
        final author = data['author'];
        callback(discussionId, comment, author);
      } catch (e) {
        print('Error parsing comment:added event: $e');
      }
    });
  }

  /// Listen to comment updates
  void onCommentUpdated(Function(String discussionId, String commentId, DiscussionComment comment) callback) {
    if (_socket == null) return;

    _socket!.on('comment:updated', (data) {
      try {
        final discussionId = data['discussionId'];
        final commentId = data['commentId'];
        final comment = DiscussionComment.fromJson(data['comment']);
        callback(discussionId, commentId, comment);
      } catch (e) {
        print('Error parsing comment:updated event: $e');
      }
    });
  }

  /// Listen to comment deletions
  void onCommentDeleted(Function(String discussionId, String commentId) callback) {
    if (_socket == null) return;

    _socket!.on('comment:deleted', (data) {
      try {
        final discussionId = data['discussionId'];
        final commentId = data['commentId'];
        callback(discussionId, commentId);
      } catch (e) {
        print('Error parsing comment:deleted event: $e');
      }
    });
  }

  /// Listen to discussion likes
  void onDiscussionLike(Function(String discussionId, String action, int likeCount, Map<String, dynamic> user) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:like', (data) {
      try {
        final discussionId = data['discussionId'];
        final action = data['action']; // 'liked' or 'unliked'
        final likeCount = data['likeCount'];
        final user = data['user'];
        callback(discussionId, action, likeCount, user);
      } catch (e) {
        print('Error parsing discussion:like event: $e');
      }
    });
  }

  /// Listen to comment likes
  void onCommentLike(Function(String discussionId, String commentId, String action, int likeCount, Map<String, dynamic> user) callback) {
    if (_socket == null) return;

    _socket!.on('comment:like', (data) {
      try {
        final discussionId = data['discussionId'];
        final commentId = data['commentId'];
        final action = data['action'];
        final likeCount = data['likeCount'];
        final user = data['user'];
        callback(discussionId, commentId, action, likeCount, user);
      } catch (e) {
        print('Error parsing comment:like event: $e');
      }
    });
  }

  /// Listen to share events
  void onDiscussionShare(Function(String discussionId, int shareCount) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:share', (data) {
      try {
        final discussionId = data['discussionId'];
        final shareCount = data['shareCount'];
        callback(discussionId, shareCount);
      } catch (e) {
        print('Error parsing discussion:share event: $e');
      }
    });
  }

  /// Listen to viewer count updates
  void onViewersUpdate(Function(String discussionId, int count) callback) {
    if (_socket == null) return;

    _socket!.on('discussion:viewers', (data) {
      try {
        final discussionId = data['discussionId'];
        final count = data['count'];
        callback(discussionId, count);
      } catch (e) {
        print('Error parsing discussion:viewers event: $e');
      }
    });
  }

  /// Listen to user joined room
  void onUserJoined(Function(Map<String, dynamic>? user) callback) {
    if (_socket == null) return;

    _socket!.on('user:joined', (data) {
      try {
        final user = data['user'];
        callback(user);
      } catch (e) {
        print('Error parsing user:joined event: $e');
      }
    });
  }

  /// Listen to user left room
  void onUserLeft(Function(Map<String, dynamic>? user) callback) {
    if (_socket == null) return;

    _socket!.on('user:left', (data) {
      try {
        final user = data['user'];
        callback(user);
      } catch (e) {
        print('Error parsing user:left event: $e');
      }
    });
  }

  /// Listen to typing indicators
  void onUserTyping(Function(String discussionId, Map<String, dynamic> user) callback) {
    if (_socket == null) return;

    _socket!.on('comment:typing', (data) {
      try {
        final discussionId = data['discussionId'];
        final user = data['user'];
        callback(discussionId, user);
      } catch (e) {
        print('Error parsing comment:typing event: $e');
      }
    });
  }

  /// Listen to stop typing indicators
  void onUserStopTyping(Function(String discussionId, Map<String, dynamic> user) callback) {
    if (_socket == null) return;

    _socket!.on('comment:stop-typing', (data) {
      try {
        final discussionId = data['discussionId'];
        final user = data['user'];
        callback(discussionId, user);
      } catch (e) {
        print('Error parsing comment:stop-typing event: $e');
      }
    });
  }

  /// Listen to presence updates
  void onPresenceUpdate(Function(Map<String, dynamic> user, String status) callback) {
    if (_socket == null) return;

    _socket!.on('presence:update', (data) {
      try {
        final user = data['user'];
        final status = data['status']; // 'online', 'away', 'busy', 'offline'
        callback(user, status);
      } catch (e) {
        print('Error parsing presence:update event: $e');
      }
    });
  }

  // ============================================
  // CLEAN UP
  // ============================================

  /// Remove all event listeners
  void removeAllListeners() {
    if (_socket == null) return;

    _socket!.off('discussion:created');
    _socket!.off('discussion:updated');
    _socket!.off('discussion:deleted');
    _socket!.off('comment:added');
    _socket!.off('comment:updated');
    _socket!.off('comment:deleted');
    _socket!.off('discussion:like');
    _socket!.off('comment:like');
    _socket!.off('discussion:share');
    _socket!.off('discussion:viewers');
    _socket!.off('user:joined');
    _socket!.off('user:left');
    _socket!.off('comment:typing');
    _socket!.off('comment:stop-typing');
    _socket!.off('presence:update');
    
    print('🧹 Removed all Socket.IO event listeners');
  }
}

