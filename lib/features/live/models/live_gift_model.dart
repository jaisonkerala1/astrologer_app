class LiveGiftModel {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String giftName;
  final String giftEmoji;
  final int giftValue;
  final DateTime timestamp;

  LiveGiftModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    required this.giftName,
    required this.giftEmoji,
    required this.giftValue,
    required this.timestamp,
  });

  factory LiveGiftModel.fromJson(Map<String, dynamic> json) {
    return LiveGiftModel(
      id: json['id'] ?? '',
      streamId: json['streamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      giftName: json['giftName'] ?? '',
      giftEmoji: json['giftEmoji'] ?? '',
      giftValue: json['giftValue'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'giftValue': giftValue,
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

  String get formattedValue {
    if (giftValue >= 1000) {
      return '${(giftValue / 1000).toStringAsFixed(1)}K';
    } else {
      return giftValue.toString();
    }
  }
}


