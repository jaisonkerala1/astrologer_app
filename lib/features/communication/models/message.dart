import 'package:equatable/equatable.dart';

/// Model for individual chat messages
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType; // 'user', 'astrologer', 'admin'
  final String content;
  final String messageType; // 'text', 'image', 'audio', 'file'
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isMe; // Is this message from current user?
  final String status; // 'sent', 'delivered', 'read', 'failed'
  final DateTime? readAt;
  final String? replyToId;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.messageType = 'text',
    this.mediaUrl,
    required this.timestamp,
    this.isMe = false,
    this.status = 'sent',
    this.readAt,
    this.replyToId,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderType,
        content,
        messageType,
        mediaUrl,
        timestamp,
        isMe,
        status,
        readAt,
        replyToId,
      ];

  /// From JSON
  factory Message.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId'] ?? '';
    final senderType = json['senderType'] ?? 'user';
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: senderId,
      senderType: senderType,
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      // Only count as "me" if it's my senderId and I'm an astrologer (avoid admin/user showing as me)
      isMe: currentUserId != null ? (senderId == currentUserId && senderType == 'astrologer') : false,
      status: json['status'] ?? 'sent',
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      replyToId: json['replyToId'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'readAt': readAt?.toIso8601String(),
      'replyToId': replyToId,
    };
  }

  /// Copy with
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? content,
    String? messageType,
    String? mediaUrl,
    DateTime? timestamp,
    bool? isMe,
    String? status,
    DateTime? readAt,
    String? replyToId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId ?? this.replyToId,
    );
  }

  /// Get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    // Return time only for today
    if (timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    // Return date for older messages
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
