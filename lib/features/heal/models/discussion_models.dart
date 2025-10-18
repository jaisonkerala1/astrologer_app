class DiscussionPost {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String author;
  final String? authorPhoto;
  final String authorInitial;
  final String? imageUrl;
  final List<String> tags;
  final String category;
  int likes;
  bool isLiked;
  bool isSaved;
  bool isSubscribed;
  int commentCount;
  int shareCount;
  int viewCount;
  int saveCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiscussionPost({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.author,
    this.authorPhoto,
    required this.authorInitial,
    this.imageUrl,
    this.tags = const [],
    required this.category,
    required this.likes,
    required this.isLiked,
    this.isSaved = false,
    this.isSubscribed = false,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.saveCount = 0,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Factory constructor for API responses (from Railway backend)
  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    // Get author initial from first letter of name
    String getInitial(String? name) {
      if (name == null || name.isEmpty) return 'A';
      return name.substring(0, 1).toUpperCase();
    }

    return DiscussionPost(
      id: json['_id'] ?? json['id'],
      authorId: json['authorId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['authorName'] ?? json['author'] ?? 'Unknown',
      authorPhoto: json['authorPhoto'],
      authorInitial: getInitial(json['authorName'] ?? json['author']),
      imageUrl: json['imageUrl'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      category: json['category'] ?? 'general',
      likes: json['likeCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isSubscribed: json['isSubscribed'] ?? false,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      saveCount: json['saveCount'] ?? 0,
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime? ?? DateTime.now()),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'authorId': authorId,
      'authorName': author,
      'authorPhoto': authorPhoto,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'tags': tags,
      'category': category,
      'likeCount': likes,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isSubscribed': isSubscribed,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'saveCount': saveCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Helper to get "time ago" string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class DiscussionComment {
  final String id;
  final String discussionId;
  final String authorId;
  final String authorType; // 'astrologer' or 'user'
  final String author;
  final String? authorPhoto;
  final String authorInitial;
  final String content;
  final String? imageUrl;
  int likes;
  bool isLiked;
  int replyCount;
  bool isEdited;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? parentCommentId; // For replies
  List<DiscussionComment> replies; // Nested replies

  DiscussionComment({
    required this.id,
    required this.discussionId,
    required this.authorId,
    this.authorType = 'astrologer',
    required this.author,
    this.authorPhoto,
    required this.authorInitial,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.isLiked,
    this.replyCount = 0,
    this.isEdited = false,
    required this.createdAt,
    this.editedAt,
    this.parentCommentId,
    List<DiscussionComment>? replies,
  }) : replies = replies ?? [];

  /// Factory constructor for API responses (from Railway backend)
  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    // Get author initial from first letter of name
    String getInitial(String? name) {
      if (name == null || name.isEmpty) return 'A';
      return name.substring(0, 1).toUpperCase();
    }

    return DiscussionComment(
      id: json['_id'] ?? json['id'],
      discussionId: json['discussionId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorType: json['authorType'] ?? 'astrologer',
      author: json['authorName'] ?? json['author'] ?? 'Unknown',
      authorPhoto: json['authorPhoto'],
      authorInitial: getInitial(json['authorName'] ?? json['author']),
      content: json['text'] ?? json['content'] ?? '',
      imageUrl: json['imageUrl'],
      likes: json['likeCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      replyCount: json['replyCount'] ?? 0,
      isEdited: json['isEdited'] ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime? ?? DateTime.now()),
      editedAt: json['editedAt'] is String
          ? DateTime.parse(json['editedAt'])
          : (json['editedAt'] as DateTime?),
      parentCommentId: json['parentCommentId'],
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => DiscussionComment.fromJson(reply))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'discussionId': discussionId,
      'authorId': authorId,
      'authorType': authorType,
      'authorName': author,
      'authorPhoto': authorPhoto,
      'text': content,
      'imageUrl': imageUrl,
      'likeCount': likes,
      'isLiked': isLiked,
      'replyCount': replyCount,
      'isEdited': isEdited,
      'createdAt': createdAt.toIso8601String(),
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      'parentCommentId': parentCommentId,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  /// Helper to get "time ago" string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class AstrologerActivity {
  final String id;
  final String type; // 'post_created', 'comment_added', 'post_liked', 'comment_liked'
  final String discussionId;
  final String? commentId;
  final String content;
  final DateTime timestamp;

  AstrologerActivity({
    required this.id,
    required this.type,
    required this.discussionId,
    this.commentId,
    required this.content,
    required this.timestamp,
  });

  factory AstrologerActivity.fromJson(Map<String, dynamic> json) {
    return AstrologerActivity(
      id: json['id'],
      type: json['type'],
      discussionId: json['discussionId'],
      commentId: json['commentId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'discussionId': discussionId,
      'commentId': commentId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum ActivityType {
  postCreated,
  commentAdded,
  postLiked,
  commentLiked,
  postShared,
}

extension ActivityTypeExtension on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.postCreated:
        return 'post_created';
      case ActivityType.commentAdded:
        return 'comment_added';
      case ActivityType.postLiked:
        return 'post_liked';
      case ActivityType.commentLiked:
        return 'comment_liked';
      case ActivityType.postShared:
        return 'post_shared';
    }
  }
}



















































