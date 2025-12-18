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
  static const String like = 'live:like';
  static const String unlike = 'live:unlike';
  static const String likeCount = 'live:like_count';
  static const String end = 'live:end';
  static const String viewerJoined = 'live:viewer_joined';
  static const String viewerLeft = 'live:viewer_left';
  // Global events (broadcast to ALL connected users)
  static const String streamStarted = 'live:stream_started';
  static const String streamEnded = 'live:stream_ended';
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

/// Socket event types for Direct Messages (Admin/User to Astrologer)
class DirectMessageSocketEvents {
  static const String join = 'dm:join_conversation';
  static const String leave = 'dm:leave_conversation';
  static const String send = 'dm:send_message';
  static const String received = 'dm:message_received';
  static const String typingStart = 'dm:typing_start';
  static const String typingStop = 'dm:typing_stop';
  static const String markRead = 'dm:mark_read';
  static const String history = 'dm:history';
}

/// Socket event types for Calls (Voice & Video)
class CallSocketEvents {
  static const String initiate = 'call:initiate';
  static const String incoming = 'call:incoming';
  static const String accept = 'call:accept';
  static const String reject = 'call:reject';
  static const String connected = 'call:connected';
  static const String end = 'call:end';
  static const String token = 'call:token';
}

/// Socket event types for discussions
class DiscussionSocketEvents {
  static const String join = 'discussion:join';
  static const String leave = 'discussion:leave';
  static const String comment = 'discussion:comment';
  static const String reply = 'discussion:reply';
  static const String like = 'discussion:like';
  static const String update = 'discussion:update';
  static const String delete = 'discussion:delete';
}

/// Socket event types for service requests (Heal tab)
class ServiceRequestSocketEvents {
  static const String join = 'service-request:join';
  static const String leave = 'service-request:leave';
  static const String new_ = 'service-request:new';
  static const String status = 'service-request:status';
  static const String notes = 'service-request:notes';
  static const String delete = 'service-request:delete';
  static const String update = 'service-request:update';
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
  Map<String, dynamic>? _serverUser; // from server 'connected' ack
  int _authReconnectAttempts = 0;
  static const int _maxAuthReconnectAttempts = 2;
  
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
  final _likesCountController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveEndController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerLeftController = StreamController<Map<String, dynamic>>.broadcast();
  // Global stream events (for dashboard/list updates)
  final _streamStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _streamEndedController = StreamController<Map<String, dynamic>>.broadcast();

  // Expose streams for BLoC subscription
  Stream<Map<String, dynamic>> get viewerCountStream => _viewerCountController.stream;
  Stream<Map<String, dynamic>> get liveCommentStream => _liveCommentController.stream;
  Stream<Map<String, dynamic>> get liveGiftStream => _liveGiftController.stream;
  Stream<Map<String, dynamic>> get liveReactionStream => _liveReactionController.stream;
  Stream<Map<String, dynamic>> get likesCountStream => _likesCountController.stream;
  Stream<Map<String, dynamic>> get liveEndStream => _liveEndController.stream;
  Stream<Map<String, dynamic>> get viewerJoinedStream => _viewerJoinedController.stream;
  Stream<Map<String, dynamic>> get viewerLeftStream => _viewerLeftController.stream;
  // Global stream events (for dashboard/list updates)
  Stream<Map<String, dynamic>> get streamStartedStream => _streamStartedController.stream;
  Stream<Map<String, dynamic>> get streamEndedStream => _streamEndedController.stream;

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
  final _discussionUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _discussionDeleteController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get discussionCommentStream => _discussionCommentController.stream;
  Stream<Map<String, dynamic>> get discussionLikeStream => _discussionLikeController.stream;
  Stream<Map<String, dynamic>> get discussionUpdateStream => _discussionUpdateController.stream;
  Stream<Map<String, dynamic>> get discussionDeleteStream => _discussionDeleteController.stream;

  // Service Request event streams (Heal tab)
  final _serviceRequestNewController = StreamController<Map<String, dynamic>>.broadcast();
  final _serviceRequestStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _serviceRequestNotesController = StreamController<Map<String, dynamic>>.broadcast();
  final _serviceRequestDeleteController = StreamController<Map<String, dynamic>>.broadcast();
  final _serviceRequestUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get serviceRequestNewStream => _serviceRequestNewController.stream;
  Stream<Map<String, dynamic>> get serviceRequestStatusStream => _serviceRequestStatusController.stream;
  Stream<Map<String, dynamic>> get serviceRequestNotesStream => _serviceRequestNotesController.stream;
  Stream<Map<String, dynamic>> get serviceRequestDeleteStream => _serviceRequestDeleteController.stream;
  Stream<Map<String, dynamic>> get serviceRequestUpdateStream => _serviceRequestUpdateController.stream;

  // Direct Message event streams
  final _dmMessageReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _dmTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _dmHistoryController = StreamController<Map<String, dynamic>>.broadcast();
  final _dmGlobalController = StreamController<Map<String, dynamic>>.broadcast(); // global DM events (new/personal)

  Stream<Map<String, dynamic>> get dmMessageReceivedStream => _dmMessageReceivedController.stream;
  Stream<Map<String, dynamic>> get dmTypingStream => _dmTypingController.stream;
  Stream<Map<String, dynamic>> get dmHistoryStream => _dmHistoryController.stream;
  Stream<Map<String, dynamic>> get dmGlobalStream => _dmGlobalController.stream;

  // Call event streams
  final _callIncomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callConnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callTokenController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get callIncomingStream => _callIncomingController.stream;
  Stream<Map<String, dynamic>> get callAcceptedStream => _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get callRejectedStream => _callRejectedController.stream;
  Stream<Map<String, dynamic>> get callConnectedStream => _callConnectedController.stream;
  Stream<Map<String, dynamic>> get callEndedStream => _callEndedController.stream;
  Stream<Map<String, dynamic>> get callTokenStream => _callTokenController.stream;

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
    // Always load the latest token so we can decide whether to reconnect.
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

    // If we're already connected but server treated us as anonymous (bad/expired token at connect time),
    // force a reconnect using the fresh token so we join the correct personal room (astrologer:<id>).
    if (_socket != null && _socket!.connected) {
      if (!isAuthenticated && _authReconnectAttempts < _maxAuthReconnectAttempts) {
        _authReconnectAttempts += 1;
        print('🔐 [SOCKET] Connected but unauthenticated. Forcing reconnect ($_authReconnectAttempts/$_maxAuthReconnectAttempts)');
        disconnect();
      } else {
        debugPrint('🔌 [SOCKET] Already connected');
        return;
      }
    }

    _updateState(SocketConnectionState.connecting);

    try {
      debugPrint('🔌 [SOCKET] Connecting to $_socketUrl');
      _serverUser = null; // reset until server ack arrives

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

  /// Wait for socket to be ready (connected + authenticated).
  /// Use this before emitting important events (join room, request history)
  /// to prevent race conditions on first load or after phone lock/unlock.
  Future<void> waitUntilReady({Duration timeout = const Duration(seconds: 5)}) async {
    final deadline = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(deadline)) {
      // Success: authenticated connection
      if (isConnected && isAuthenticated) {
        print('✅ [SOCKET] Ready! (connected + authenticated)');
        return;
      }
      
      // Give up if we've maxed auth retries and are stuck anonymous
      // (proceeding will allow chat to work, but calls won't be received)
      if (isConnected && !isAuthenticated && _authReconnectAttempts >= _maxAuthReconnectAttempts) {
        print('⚠️ [SOCKET] Connected but anonymous (auth failed after $_authReconnectAttempts retries). Proceeding anyway...');
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('⚠️ [SOCKET] Timeout waiting for ready state (connected: $isConnected, auth: $isAuthenticated)');
  }

  /// Setup all socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('✅ [SOCKET] Connected');
      _updateState(SocketConnectionState.connected);
      // Ask server for ack/user immediately; this also helps detect anonymous sockets.
      // (Server emits 'connected' automatically, but this helps in case of timing issues.)
      _socket!.emit('get_stats');
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
      try {
        final map = Map<String, dynamic>.from(data as dynamic);
        final user = map['user'];
        _serverUser = user is Map ? Map<String, dynamic>.from(user) : null;
      } catch (_) {
        _serverUser = null;
      }

      // Use print (not debugPrint) so it always shows in logs
      print('✅ [SOCKET] Server acknowledged connection: $data');
      print('🔐 [SOCKET] Authenticated: $isAuthenticated, user: $_serverUser');

      // If server treated us as anonymous, reconnect with fresh token
      if (!isAuthenticated && _authReconnectAttempts < _maxAuthReconnectAttempts) {
        _authReconnectAttempts += 1;
        print('🔐 [SOCKET] Server says anonymous. Reconnecting ($_authReconnectAttempts/$_maxAuthReconnectAttempts)');
        // ignore: discarded_futures
        Future<void>.delayed(const Duration(milliseconds: 250), () async {
          disconnect();
          await connect();
        });
      }
    });

    _socket!.on('stats', (data) {
      print('📊 [SOCKET] Stats: $data');
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

    _socket!.on(LiveSocketEvents.likeCount, (data) {
      debugPrint('👍 [SOCKET] Like count: $data');
      _likesCountController.add(Map<String, dynamic>.from(data));
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

    // Global stream events (for dashboard updates)
    _socket!.on(LiveSocketEvents.streamStarted, (data) {
      debugPrint('🔴 [SOCKET] New stream started: $data');
      _streamStartedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(LiveSocketEvents.streamEnded, (data) {
      debugPrint('⬛ [SOCKET] Stream ended: $data');
      _streamEndedController.add(Map<String, dynamic>.from(data));
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

    _socket!.on(DiscussionSocketEvents.reply, (data) {
      debugPrint('↩️ [SOCKET] Discussion reply: $data');
      _discussionCommentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(DiscussionSocketEvents.like, (data) {
      debugPrint('❤️ [SOCKET] Discussion like: $data');
      _discussionLikeController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(DiscussionSocketEvents.update, (data) {
      debugPrint('🔄 [SOCKET] Discussion update: $data');
      _discussionUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(DiscussionSocketEvents.delete, (data) {
      debugPrint('🗑️ [SOCKET] Discussion delete: $data');
      _discussionDeleteController.add(Map<String, dynamic>.from(data));
    });

    // Service Request events (Heal tab)
    _socket!.on(ServiceRequestSocketEvents.new_, (data) {
      debugPrint('🆕 [SOCKET] New service request: $data');
      _serviceRequestNewController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ServiceRequestSocketEvents.status, (data) {
      debugPrint('🔄 [SOCKET] Service request status update: $data');
      _serviceRequestStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ServiceRequestSocketEvents.notes, (data) {
      debugPrint('📝 [SOCKET] Service request notes update: $data');
      _serviceRequestNotesController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ServiceRequestSocketEvents.delete, (data) {
      debugPrint('🗑️ [SOCKET] Service request deleted: $data');
      _serviceRequestDeleteController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(ServiceRequestSocketEvents.update, (data) {
      debugPrint('🔄 [SOCKET] Service request update: $data');
      _serviceRequestUpdateController.add(Map<String, dynamic>.from(data));
    });

    // Direct Message events
    _socket!.on(DirectMessageSocketEvents.received, (data) {
      debugPrint('💬 [SOCKET] Direct message received: $data');
      _dmMessageReceivedController.add(Map<String, dynamic>.from(data));
      _dmGlobalController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(DirectMessageSocketEvents.typingStart, (data) {
      debugPrint('✍️ [SOCKET] User typing: $data');
      _dmTypingController.add(Map<String, dynamic>.from(data));
    });

    // Listen for message history (support both legacy and new)
    _socket!.on('dm:history_response', (data) {
      debugPrint('📜 [SOCKET] Message history (legacy) received: $data');
      _dmHistoryController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on(DirectMessageSocketEvents.history, (data) {
      debugPrint('📜 [SOCKET] Message history received: $data');
      _dmHistoryController.add(Map<String, dynamic>.from(data));
    });

    // Personal-room new message notification
    _socket!.on('dm:new_message', (data) {
      debugPrint('🆕 [SOCKET] New message notification: $data');
      _dmGlobalController.add(Map<String, dynamic>.from(data));
    });

    // Call events
    _socket!.on(CallSocketEvents.incoming, (data) {
      print('📞 [SOCKET] Incoming call: $data');
      _callIncomingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(CallSocketEvents.accept, (data) {
      print('✅ [SOCKET] Call accepted: $data');
      _callAcceptedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(CallSocketEvents.reject, (data) {
      print('❌ [SOCKET] Call rejected: $data');
      _callRejectedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(CallSocketEvents.connected, (data) {
      print('🔗 [SOCKET] Call connected: $data');
      _callConnectedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(CallSocketEvents.end, (data) {
      print('📴 [SOCKET] Call ended: $data');
      _callEndedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on(CallSocketEvents.token, (data) {
      print('🔑 [SOCKET] Agora token received: $data');
      _callTokenController.add(Map<String, dynamic>.from(data));
    });
  }

  void _updateState(SocketConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// True if server acknowledges a non-anonymous user for this socket.
  bool get isAuthenticated {
    final user = _serverUser;
    if (user == null) return false;
    final isAnon = user['isAnonymous'] == true;
    if (isAnon) return false;
    // Backends may mark role or isAdmin; for astrologers role='astrologer'
    return true;
  }

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

  /// Like a live stream (one-time per user)
  void likeLiveStream(String streamId) {
    if (!isConnected) {
      debugPrint('⚠️ [SOCKET] Cannot like - not connected');
      return;
    }

    _socket!.emit(LiveSocketEvents.like, {
      'streamId': streamId,
    });

    debugPrint('👍 [SOCKET] Emitted like event for stream: $streamId');
  }

  /// Unlike a live stream
  void unlikeLiveStream(String streamId) {
    if (!isConnected) return;

    _socket!.emit(LiveSocketEvents.unlike, {
      'streamId': streamId,
    });

    debugPrint('👎 [SOCKET] Unliked stream: $streamId');
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

  /// Join a discussion thread room
  void joinDiscussion(String discussionId) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.join, {
      'discussionId': discussionId,
    });
    
    debugPrint('📥 [SOCKET] Joining discussion room: $discussionId');
  }

  /// Alias for joinDiscussion (for BLoC compatibility)
  void joinDiscussionRoom(String discussionId) => joinDiscussion(discussionId);

  /// Leave a discussion thread room
  void leaveDiscussion(String discussionId) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.leave, {
      'discussionId': discussionId,
    });
    
    debugPrint('📤 [SOCKET] Leaving discussion room: $discussionId');
  }

  /// Alias for leaveDiscussion (for BLoC compatibility)
  void leaveDiscussionRoom(String discussionId) => leaveDiscussion(discussionId);

  /// Send a comment in discussion (via socket for real-time)
  void sendDiscussionComment({
    required String discussionId,
    required String content,
    String? parentCommentId,
  }) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.comment, {
      'discussionId': discussionId,
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    });
    
    debugPrint('💬 [SOCKET] Sending discussion comment');
  }

  /// Toggle like on discussion or comment via socket
  void sendDiscussionLike({
    required String discussionId,
    String? commentId,
  }) {
    if (!isConnected) return;

    _socket!.emit(DiscussionSocketEvents.like, {
      'discussionId': discussionId,
      if (commentId != null) 'commentId': commentId,
    });
  }

  // ==================== SERVICE REQUEST METHODS ====================

  /// Join astrologer's service request room (for real-time updates)
  /// Note: The backend auto-joins the astrologer room on connection,
  /// but this method can be used for explicit joins if needed
  void joinServiceRequestRoom(String astrologerId) {
    if (!isConnected) return;

    _socket!.emit(ServiceRequestSocketEvents.join, {
      'astrologerId': astrologerId,
    });
    
    debugPrint('📥 [SOCKET] Joining service request room for astrologer: $astrologerId');
  }

  /// Leave astrologer's service request room
  void leaveServiceRequestRoom(String astrologerId) {
    if (!isConnected) return;

    _socket!.emit(ServiceRequestSocketEvents.leave, {
      'astrologerId': astrologerId,
    });
    
    debugPrint('📤 [SOCKET] Leaving service request room for astrologer: $astrologerId');
  }

  // ==================== DIRECT MESSAGE METHODS ====================

  /// Join a direct message conversation
  void joinDirectConversation({
    required String conversationId,
    required String userId,
    required String userType, // 'admin', 'astrologer', 'user'
  }) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.join, {
      'conversationId': conversationId,
      'userId': userId,
      'userType': userType,
    });

    debugPrint('💬 [SOCKET] Joining conversation: $conversationId as $userType');
  }

  /// Leave a direct message conversation
  void leaveDirectConversation(String conversationId) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.leave, {
      'conversationId': conversationId,
    });

    debugPrint('👋 [SOCKET] Leaving conversation: $conversationId');
  }

  /// Send a direct message
  void sendDirectMessage({
    required String conversationId,
    required String recipientId,
    required String recipientType, // 'admin', 'astrologer', 'user'
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) {
    if (!isConnected) {
      debugPrint('⚠️ [SOCKET] Cannot send message - not connected');
      return;
    }

    _socket!.emit(DirectMessageSocketEvents.send, {
      'conversationId': conversationId,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'content': content,
      'messageType': messageType,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    });

    debugPrint('📤 [SOCKET] Sending message to $recipientType ($recipientId)');
  }

  /// Send typing indicator for direct message
  void sendDirectMessageTyping({
    required String conversationId,
    required String userId,
  }) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.typingStart, {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  /// Stop typing indicator for direct message
  void sendDirectMessageStopTyping({
    required String conversationId,
    required String userId,
  }) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.typingStop, {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  /// Mark messages as read
  void markDirectMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.markRead, {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });

    debugPrint('✅ [SOCKET] Marking ${messageIds.length} messages as read');
  }

  /// Request message history
  void requestDirectMessageHistory({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) {
    if (!isConnected) return;

    _socket!.emit(DirectMessageSocketEvents.history, {
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });

    debugPrint('📜 [SOCKET] Requesting message history for: $conversationId');
  }

  // ==================== CALL METHODS ====================

  /// Initiate a call (voice or video)
  void initiateCall({
    required String recipientId,
    required String recipientType, // 'admin', 'astrologer', 'user'
    required String callType, // 'voice' or 'video'
    String? channelName,
  }) {
    if (!isConnected) {
      debugPrint('⚠️ [SOCKET] Cannot initiate call - not connected');
      return;
    }

    _socket!.emit(CallSocketEvents.initiate, {
      'recipientId': recipientId,
      'recipientType': recipientType,
      'callType': callType,
      if (channelName != null) 'channelName': channelName,
    });

    debugPrint('📞 [SOCKET] Initiating $callType call to $recipientType ($recipientId)');
  }

  /// Accept an incoming call
  void acceptCall({
    required String callId,
    required String contactId,
  }) {
    if (!isConnected) return;

    _socket!.emit(CallSocketEvents.accept, {
      'callId': callId,
      'contactId': contactId,
    });

    debugPrint('✅ [SOCKET] Accepting call: $callId');
  }

  /// Reject an incoming call
  void rejectCall({
    required String callId,
    required String contactId,
    String reason = 'declined',
  }) {
    if (!isConnected) return;

    _socket!.emit(CallSocketEvents.reject, {
      'callId': callId,
      'contactId': contactId,
      'reason': reason,
    });

    debugPrint('❌ [SOCKET] Rejecting call: $callId');
  }

  /// Notify call connected
  void notifyCallConnected({
    required String callId,
    required String contactId,
  }) {
    if (!isConnected) return;

    _socket!.emit(CallSocketEvents.connected, {
      'callId': callId,
      'contactId': contactId,
    });

    debugPrint('🔗 [SOCKET] Call connected: $callId');
  }

  /// End a call
  void endCall({
    required String callId,
    required String contactId,
    int? duration,
  }) {
    if (!isConnected) return;

    _socket!.emit(CallSocketEvents.end, {
      'callId': callId,
      'contactId': contactId,
      if (duration != null) 'duration': duration,
    });

    debugPrint('📴 [SOCKET] Ending call: $callId');
  }

  /// Request Agora token for a call
  void requestCallToken({
    required String callId,
    required String channelName,
  }) {
    if (!isConnected) return;

    _socket!.emit(CallSocketEvents.token, {
      'callId': callId,
      'channelName': channelName,
    });

    debugPrint('🔑 [SOCKET] Requesting Agora token for call: $callId');
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
    _likesCountController.close();
    _liveEndController.close();
    _viewerJoinedController.close();
    _viewerLeftController.close();
    _streamStartedController.close();
    _streamEndedController.close();
    _chatMessageController.close();
    _chatTypingController.close();
    _chatReadController.close();
    _chatOnlineController.close();
    _discussionCommentController.close();
    _discussionLikeController.close();
    _discussionUpdateController.close();
    _discussionDeleteController.close();
    _serviceRequestNewController.close();
    _serviceRequestStatusController.close();
    _serviceRequestNotesController.close();
    _serviceRequestDeleteController.close();
    _serviceRequestUpdateController.close();
    _dmMessageReceivedController.close();
    _dmTypingController.close();
    _dmHistoryController.close();
    _dmGlobalController.close();
    _callIncomingController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callConnectedController.close();
    _callEndedController.close();
    _callTokenController.close();
    _errorController.close();
  }
}

