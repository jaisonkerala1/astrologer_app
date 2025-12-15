class DiscussionPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? authorId;
  final String authorInitial;
  final String? authorAvatar;
  final String timeAgo;
  final String category;
  int likes;
  bool isLiked;
  int commentsCount;
  final String visibility;
  final bool isPinned;
  final DateTime createdAt;

  DiscussionPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.authorId,
    required this.authorInitial,
    this.authorAvatar,
    required this.timeAgo,
    required this.category,
    required this.likes,
    required this.isLiked,
    this.commentsCount = 0,
    this.visibility = 'public',
    this.isPinned = false,
    required this.createdAt,
  });

  /// Factory for local storage JSON (legacy)
  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    return DiscussionPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      authorId: json['authorId'],
      authorInitial: json['authorInitial'],
      authorAvatar: json['authorAvatar'],
      timeAgo: json['timeAgo'] ?? '',
      category: json['category'],
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      commentsCount: json['commentsCount'] ?? 0,
      visibility: json['visibility'] ?? 'public',
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Factory for API response JSON
  factory DiscussionPost.fromApiJson(Map<String, dynamic> json) {
    return DiscussionPost(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? json['authorName'] ?? '',
      authorId: json['authorId'],
      authorInitial: json['authorInitial'] ?? 
          (json['author'] != null && json['author'].isNotEmpty 
              ? json['author'][0].toUpperCase() 
              : '?'),
      authorAvatar: json['authorAvatar'],
      timeAgo: json['timeAgo'] ?? _calculateTimeAgo(json['createdAt']),
      category: json['category'] ?? 'General Discussion',
      likes: json['likes'] ?? json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      commentsCount: json['commentsCount'] ?? 0,
      visibility: json['visibility'] ?? 'public',
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'authorId': authorId,
      'authorInitial': authorInitial,
      'authorAvatar': authorAvatar,
      'timeAgo': timeAgo,
      'category': category,
      'likes': likes,
      'isLiked': isLiked,
      'commentsCount': commentsCount,
      'visibility': visibility,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  DiscussionPost copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    String? authorId,
    String? authorInitial,
    String? authorAvatar,
    String? timeAgo,
    String? category,
    int? likes,
    bool? isLiked,
    int? commentsCount,
    String? visibility,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return DiscussionPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      authorInitial: authorInitial ?? this.authorInitial,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
      visibility: visibility ?? this.visibility,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _calculateTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.parse(createdAt);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

class DiscussionComment {
  final String id;
  final String discussionId;
  final String author;
  final String? authorId;
  final String authorInitial;
  final String? authorAvatar;
  final String content;
  final String timeAgo;
  int likes;
  bool isLiked;
  int repliesCount;
  final DateTime createdAt;
  final String? parentCommentId; // For replies
  List<DiscussionComment> replies; // Nested replies

  DiscussionComment({
    required this.id,
    required this.discussionId,
    required this.author,
    this.authorId,
    required this.authorInitial,
    this.authorAvatar,
    required this.content,
    required this.timeAgo,
    required this.likes,
    required this.isLiked,
    this.repliesCount = 0,
    required this.createdAt,
    this.parentCommentId,
    List<DiscussionComment>? replies,
  }) : replies = replies ?? [];

  /// Factory for local storage JSON (legacy)
  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id'],
      discussionId: json['discussionId'],
      author: json['author'],
      authorId: json['authorId'],
      authorInitial: json['authorInitial'],
      authorAvatar: json['authorAvatar'],
      content: json['content'],
      timeAgo: json['timeAgo'] ?? '',
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      repliesCount: json['repliesCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      parentCommentId: json['parentCommentId'],
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => DiscussionComment.fromJson(reply))
          .toList() ?? [],
    );
  }

  /// Factory for API response JSON
  factory DiscussionComment.fromApiJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id'] ?? json['_id'] ?? '',
      discussionId: json['discussionId'] ?? '',
      author: json['author'] ?? json['authorName'] ?? '',
      authorId: json['authorId'],
      authorInitial: json['authorInitial'] ?? 
          (json['author'] != null && json['author'].isNotEmpty 
              ? json['author'][0].toUpperCase() 
              : '?'),
      authorAvatar: json['authorAvatar'],
      content: json['content'] ?? '',
      timeAgo: json['timeAgo'] ?? _calculateTimeAgo(json['createdAt']),
      likes: json['likes'] ?? json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      repliesCount: json['repliesCount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      parentCommentId: json['parentCommentId'],
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => DiscussionComment.fromApiJson(reply))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discussionId': discussionId,
      'author': author,
      'authorId': authorId,
      'authorInitial': authorInitial,
      'authorAvatar': authorAvatar,
      'content': content,
      'timeAgo': timeAgo,
      'likes': likes,
      'isLiked': isLiked,
      'repliesCount': repliesCount,
      'createdAt': createdAt.toIso8601String(),
      'parentCommentId': parentCommentId,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  DiscussionComment copyWith({
    String? id,
    String? discussionId,
    String? author,
    String? authorId,
    String? authorInitial,
    String? authorAvatar,
    String? content,
    String? timeAgo,
    int? likes,
    bool? isLiked,
    int? repliesCount,
    DateTime? createdAt,
    String? parentCommentId,
    List<DiscussionComment>? replies,
  }) {
    return DiscussionComment(
      id: id ?? this.id,
      discussionId: discussionId ?? this.discussionId,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      authorInitial: authorInitial ?? this.authorInitial,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timeAgo: timeAgo ?? this.timeAgo,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      repliesCount: repliesCount ?? this.repliesCount,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }

  static String _calculateTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.parse(createdAt);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
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



















































