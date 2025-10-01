import '../models/live_gift_model.dart';

enum LiveReactionType {
  heart,
  fire,
  clap,
  laugh,
  wow,
  love,
}

class LiveCommentModel {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String message;
  final DateTime timestamp;
  final bool isHost;
  final LiveReactionType? reaction;
  final LiveGiftModel? gift;

  LiveCommentModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.message,
    required this.timestamp,
    this.isHost = false,
    this.reaction,
    this.gift,
  });

  factory LiveCommentModel.fromJson(Map<String, dynamic> json) {
    return LiveCommentModel(
      id: json['id'] ?? '',
      streamId: json['streamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfilePicture: json['userProfilePicture'],
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isHost: json['isHost'] ?? false,
      reaction: json['reaction'] != null
          ? LiveReactionType.values.firstWhere(
              (type) => type.toString() == 'LiveReactionType.${json['reaction']}',
              orElse: () => LiveReactionType.heart,
            )
          : null,
      gift: json['gift'] != null ? LiveGiftModel.fromJson(json['gift']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isHost': isHost,
      'reaction': reaction?.toString().split('.').last,
      'gift': gift?.toJson(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  bool get isFromHost => isHost;

  bool get isComment => reaction == null && gift == null && message.isNotEmpty;

  bool get isReaction => reaction != null;

  bool get isGift => gift != null;

  String get displayText {
    if (isReaction) {
      return '$userName reacted';
    }
    if (isGift && gift != null) {
      return '$userName sent ${gift!.giftName}';
    }
    return message;
  }

  String get giftIcon => gift?.giftEmoji ?? '';
}