class LiveReactionModel {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime timestamp;

  LiveReactionModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.timestamp,
  });

  factory LiveReactionModel.fromJson(Map<String, dynamic> json) {
    return LiveReactionModel(
      id: json['id'] ?? '',
      streamId: json['streamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      emoji: json['emoji'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 10) {
      return 'now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }
}



