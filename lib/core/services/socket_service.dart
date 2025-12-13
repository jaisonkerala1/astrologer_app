import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'storage_service.dart';

/// Socket connection state
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Socket event types for live streaming
class LiveSocketEvents {
  static const String join = 'live:join';
  static const String leave = 'live:leave';
  static const String viewerCount = 'live:viewer_count';
  static const String comment = 'live:comment';
  static const String gift = 'live:gift';
  static const String reaction = 'live:reaction';
  static const String end = 'live:end';
  static const String viewerJoined = 'live:viewer_joined';
  static const String viewerLeft = 'live:viewer_left';
}

/// Socket event types for chat
class ChatSocketEvents {
  static const String join = 'chat:join';
  static const String leave = 'chat:leave';
  static const String message = 'chat:message';
  static const String typing = 'chat:typing';
  static const String stopTyping = 'chat:stop_typing';
  static const String read = 'chat:read';
  static const String online = 'chat:online';
  static const String offline = 'chat:offline';
}

/// Socket event types for discussions
class DiscussionSocketEvents {
  static const String join = 'discussion:join';
  static const String leave = 'discussion:leave';
  static const String comment = 'discussion:comment';
  static const String reply = 'discussion:reply';
  static const String like = 'discussion:like';
  static const String update = 'discussion:update';
}

/// Core Socket Service - Singleton
/// Manages WebSocket connection with authentication
/// Provides streams for BLoC integration
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _authToken;
  
  // Connection state stream
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();
  Stream<SocketConnectionState> get connectionStateStream => _connectionStateController.stream;
  SocketConnectionState _currentState = SocketConnectionState.disconnected;
  SocketConnectionState get currentState => _currentState;

  // Live streaming event streams
  final _viewerCountController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveCommentController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveGiftController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveReactionController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveEndController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerLeftController = StreamController<Map<String, dynamic>>.broadcast();

  // Expose streams for BLoC subscription
  Stream<Map<String, dynamic>> get viewerCountStream => _viewerCountController.stream;
  Stream<Map<String, dynamic>> get liveCommentStream => _liveCommentController.stream;
  Stream<Map<String, dynamic>> get liveGiftStream => _liveGiftController.stream;
  Stream<Map<String, dynamic>> get liveReactionStream => _liveReactionController.stream;
  Stream<Map<String, dynamic>> get liveEndStream => _liveEndController.stream;
  Stream<Map<String, dynamic>> get viewerJoinedStream => _viewerJoinedController.stream;
  Stream<Map<String, dynamic>> get viewerLeftStream => _viewerLeftController.stream;

  // Chat event streams
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatOnlineController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get chatMessageStream => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get chatTypingStream => _chatTypingController.stream;
  Stream<Map<String, dynamic>> get chatReadStream => _chatReadController.stream;
  Stream<Map<String, dynamic>> get chatOnlineStream => _chatOnlineController.stream;

  // Discussion event streams
  final _discussionCommentController = StreamController<Map<String, dynamic>>.broadcast();
  final _discussionLikeController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get discussionCommentStream => _discussionCommentController.stream;
  Stream<Map<String, dynamic>> get discussionLikeStream => _discussionLikeController.stream;

  // Error stream
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  /// Get WebSocket URL from API base URL
  String get _socketUrl {
    final baseUrl = ApiConstants.baseUrl;
    // Convert https:// to wss:// or http:// to ws://
    if (baseUrl.startsWith('https://')) {
      return baseUrl; // Socket.IO handles this automatically
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl;
    }
    return baseUrl;
  }

  /// Initialize socket connection with auth token
  Future<void> connect({String? token}) async {
    if (_socket != null && _socket!.connected) {
      debugPrint('🔌 [SOCKET] Already connected');
      return;
    }

    _updateState(SocketConnectionState.connecting);

    // Get token from storage if not provided
    if (token == null) {
      final storage = StorageService();
      _authToken = await storage.getAuthToken();
    } else {
      _authToken = token;
    }

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('⚠️ [SOCKET] No auth token available');
      _updateState(SocketConnectionState.error);
      return;
    }

    try {
      debugPrint('🔌 [SOCKET] Connecting to $_socketUrl');

      _socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': _authToken})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ [SOCKET] Connection error: $e');
      _updateState(SocketConnectionState.error);
      _errorController.add('Failed to connect: $e');
    }
  }

  /// Setup all socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('✅ [SOCKET] Connected');
      _updateState(SocketConnectionState.connected);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 [SOCKET] Disconnected');
      _updateState(SocketConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ [SOCKET] Connect error: $error');
      _updateState(SocketConnectionState.error);
      _errorController.add('Connection error: $error');
    });

    _socket!.onReconnecting((_) {
      debugPrint('🔄 [SOCKET] Reconnecting...');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnect((_) {
      debugPrint('✅ [SOCKET] Reconnected');
      _updateState(SocketConnectionState.connected);
    });

    _socket!.on('connected', (data) {
      debugPrint('✅ [SOCKET] Server acknowledged connection: $data');
    });

    _socket!.on('error', (error) {
      debugPrint('❌ [SOCKET] Server error: $error');
      _errorController.add(error.toString());
    });

    // Live streaming events
    _socket!.on(LiveSocketEvents.viewerCount, (data) {
      debugPrint('👥 [SOCKET] Viewer count: $data');
      _viewerCountController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.comment, (data) {
      debugPrint('💬 [SOCKET] Live comment: $data');
      _liveCommentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.gift, (data) {
      debugPrint('🎁 [SOCKET] Live gift: $data');
      _liveGiftController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.reaction, (data) {
      debugPrint('❤️ [SOCKET] Live reaction: $data');
      _liveReactionController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.end, (data) {
      debugPrint('🛑 [SOCKET] Live end: $data');
      _liveEndController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.viewerJoined, (data) {
      debugPrint('➡️ [SOCKET] Viewer joined: $data');
      _viewerJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.viewerLeft, (data) {
      debugPrint('⬅️ [SOCKET] Viewer left: $data');
      _viewerLeftController.add(Map<String, dynamic>.from(data));
    });

    // Chat events
    _socket!.on(ChatSocketEvents.message, (data) {
      debugPrint('💬 [SOCKET] Chat message: $data');
      _chatMessageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ChatSocketEvents.typing, (data) {
      _chatTypingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ChatSocketEvents.read, (data) {
      _chatReadController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ChatSocketEvents.online, (data) {
      _chatOnlineController.add(Map<String, dynamic>.from(data));
    });

    // Discussion events
    _socket!.on(DiscussionSocketEvents.comment, (data) {
      debugPrint('💬 [SOCKET] Discussion comment: $data');
      _discussionCommentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(DiscussionSocketEvents.like, (data) {
      _discussionLikeController.add(Map<String, dynamic>.from(data));
    });
  }

  void _updateState(SocketConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  // ==================== LIVE STREAMING METHODS ====================

  /// Join a live stream room
  void joinLiveStream({
    required String streamId,
    required bool isBroadcaster,
    String? streamTitle,
  }) {
    if (!isConnected) {
      debugPrint('⚠️ [SOCKET] Not connected, cannot join stream');
      return;
    }

    _socket!.emit(LiveSocketEvents.join, {
      'streamId': streamId,
      'isBroadcaster': isBroadcaster,
      'streamTitle': streamTitle ?? '',
    });

    debugPrint('📺 [SOCKET] Joining stream: $streamId (broadcaster: $isBroadcaster)');
  }

  /// Leave a live stream room
  void leaveLiveStream(String streamId) {
    if (!isConnected) return;

    _socket!.emit(LiveSocketEvents.leave, {
      'streamId': streamId,
    });

    debugPrint('👋 [SOCKET] Leaving stream: $streamId');
  }

  /// Send a comment in live stream
  void sendLiveComment({
    required String streamId,
    required String message,
  }) {
    debugPrint('📤 [SOCKET] Sending comment to stream $streamId: $message');
    debugPrint('📤 [SOCKET] isConnected: $isConnected');
    
    if (!isConnected) {
      debugPrint('⚠️ [SOCKET] Cannot send comment - socket not connected!');
      return;
    }

    _socket!.emit(LiveSocketEvents.comment, {
      'streamId': streamId,
      'message': message,
    });
    
    debugPrint('✅ [SOCKET] Comment emitted successfully');
  }

  /// Send a gift in live stream
  void sendLiveGift({
    required String streamId,
    required String giftType,
    int giftValue = 0,
  }) {
    if (!isConnected) return;

    _socket!.emit(LiveSocketEvents.gift, {
      'streamId': streamId,
      'giftType': giftType,
      'giftValue': giftValue,
    });
  }

  /// Send a reaction (floating hearts)
  void sendLiveReaction({
    required String streamId,
    String reactionType = 'heart',
  }) {
    if (!isConnected) return;

    _socket!.emit(LiveSocketEvents.reaction, {
      'streamId': streamId,
      'reactionType': reactionType,
    });
  }

  /// End a live stream (broadcaster only)
  void endLiveStream(String streamId) {
    if (!isConnected) return;

    _socket!.emit(LiveSocketEvents.end, {
      'streamId': streamId,
    });

    debugPrint('🛑 [SOCKET] Ending stream: $streamId');
  }

  // ==================== CHAT METHODS ====================

  /// Join a chat conversation room
  void joinChat(String conversationId) {
    if (!isConnected) return;

    _socket!.emit(ChatSocketEvents.join, {
      'conversationId': conversationId,
    });
  }

  /// Leave a chat conversation room
  void leaveChat(String conversationId) {
    if (!isConnected) return;

    _socket!.emit(ChatSocketEvents.leave, {
      'conversationId': conversationId,
    });
  }

  /// Send a chat message
  void sendChatMessage({
    required String conversationId,
    required String message,
  }) {
    if (!isConnected) return;

    _socket!.emit(ChatSocketEvents.message, {
      'conversationId': conversationId,
      'message': message,
    });
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId) {
    if (!isConnected) return;

    _socket!.emit(ChatSocketEvents.typing, {
      'conversationId': conversationId,
    });
  }

  /// Stop typing indicator
  void sendStopTyping(String conversationId) {
    if (!isConnected) return;

    _socket!.emit(ChatSocketEvents.stopTyping, {
      'conversationId': conversationId,
    });
  }

  // ==================== DISCUSSION METHODS ====================

  /// Join a discussion thread
  void joinDiscussion(String discussionId) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.join, {
      'discussionId': discussionId,
    });
  }

  /// Leave a discussion thread
  void leaveDiscussion(String discussionId) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.leave, {
      'discussionId': discussionId,
    });
  }

  // ==================== CONNECTION MANAGEMENT ====================

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateState(SocketConnectionState.disconnected);
      debugPrint('🔌 [SOCKET] Disconnected and disposed');
    }
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    disconnect();
    await connect(token: _authToken);
  }

  /// Update auth token (on login/logout)
  void updateAuthToken(String? token) {
    _authToken = token;
    if (token == null) {
      disconnect();
    } else if (!isConnected) {
      connect(token: token);
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _viewerCountController.close();
    _liveCommentController.close();
    _liveGiftController.close();
    _liveReactionController.close();
    _liveEndController.close();
    _viewerJoinedController.close();
    _viewerLeftController.close();
    _chatMessageController.close();
    _chatTypingController.close();
    _chatReadController.close();
    _chatOnlineController.close();
    _discussionCommentController.close();
    _discussionLikeController.close();
    _errorController.close();
  }
}

