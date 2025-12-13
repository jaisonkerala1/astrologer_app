import 'package:equatable/equatable.dart';

/// Live Comment Model
/// Represents a comment in a live stream
class LiveCommentModel extends Equatable {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isGift;
  
  const LiveCommentModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isGift = false,
  });
  
  /// Create from JSON (from socket event)
  factory LiveCommentModel.fromJson(Map<String, dynamic> json) {
    return LiveCommentModel(
      id: json['id'] ?? '',
      streamId: json['streamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      userAvatar: json['userAvatar'],
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isGift: json['isGift'] ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isGift': isGift,
    };
  }
  
  /// Get time ago string (e.g. "2m ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  List<Object?> get props => [
    id,
    streamId,
    userId,
    userName,
    userAvatar,
    message,
    timestamp,
    isGift,
  ];
}
