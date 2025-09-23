import 'package:flutter/material.dart';

enum LiveCommentType {
  comment,
  reaction,
  gift,
  join,
  leave,
}

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
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String? message;
  final LiveCommentType type;
  final LiveReactionType? reaction;
  final DateTime timestamp;
  final bool isFromHost;
  final bool isModerator;
  final bool isPinned;
  final String? giftName;
  final String? giftIcon;
  final int? giftValue;

  LiveCommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    this.message,
    required this.type,
    this.reaction,
    required this.timestamp,
    this.isFromHost = false,
    this.isModerator = false,
    this.isPinned = false,
    this.giftName,
    this.giftIcon,
    this.giftValue,
  });

  factory LiveCommentModel.fromJson(Map<String, dynamic> json) {
    return LiveCommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfilePicture: json['userProfilePicture'],
      message: json['message'],
      type: LiveCommentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LiveCommentType.comment,
      ),
      reaction: json['reaction'] != null 
          ? LiveReactionType.values.firstWhere(
              (e) => e.name == json['reaction'],
              orElse: () => LiveReactionType.heart,
            )
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      isFromHost: json['isFromHost'] ?? false,
      isModerator: json['isModerator'] ?? false,
      isPinned: json['isPinned'] ?? false,
      giftName: json['giftName'],
      giftIcon: json['giftIcon'],
      giftValue: json['giftValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'message': message,
      'type': type.name,
      'reaction': reaction?.name,
      'timestamp': timestamp.toIso8601String(),
      'isFromHost': isFromHost,
      'isModerator': isModerator,
      'isPinned': isPinned,
      'giftName': giftName,
      'giftIcon': giftIcon,
      'giftValue': giftValue,
    };
  }

  LiveCommentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? message,
    LiveCommentType? type,
    LiveReactionType? reaction,
    DateTime? timestamp,
    bool? isFromHost,
    bool? isModerator,
    bool? isPinned,
    String? giftName,
    String? giftIcon,
    int? giftValue,
  }) {
    return LiveCommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      message: message ?? this.message,
      type: type ?? this.type,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
      isFromHost: isFromHost ?? this.isFromHost,
      isModerator: isModerator ?? this.isModerator,
      isPinned: isPinned ?? this.isPinned,
      giftName: giftName ?? this.giftName,
      giftIcon: giftIcon ?? this.giftIcon,
      giftValue: giftValue ?? this.giftValue,
    );
  }

  bool get isComment => type == LiveCommentType.comment;
  bool get isReaction => type == LiveCommentType.reaction;
  bool get isGift => type == LiveCommentType.gift;
  bool get isJoin => type == LiveCommentType.join;
  bool get isLeave => type == LiveCommentType.leave;

  String get displayText {
    switch (type) {
      case LiveCommentType.comment:
        return message ?? '';
      case LiveCommentType.reaction:
        return '${userName} reacted with ${reaction?.name ?? 'heart'}';
      case LiveCommentType.gift:
        return '${userName} sent ${giftName ?? 'a gift'}';
      case LiveCommentType.join:
        return '${userName} joined the live';
      case LiveCommentType.leave:
        return '${userName} left the live';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}





