class DiscussionPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorInitial;
  final String timeAgo;
  final String category;
  int likes;
  bool isLiked;
  final DateTime createdAt;

  DiscussionPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorInitial,
    required this.timeAgo,
    required this.category,
    required this.likes,
    required this.isLiked,
    required this.createdAt,
  });

  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    return DiscussionPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      authorInitial: json['authorInitial'],
      timeAgo: json['timeAgo'],
      category: json['category'],
      likes: json['likes'],
      isLiked: json['isLiked'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'authorInitial': authorInitial,
      'timeAgo': timeAgo,
      'category': category,
      'likes': likes,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class DiscussionComment {
  final String id;
  final String discussionId;
  final String author;
  final String authorInitial;
  final String content;
  final String timeAgo;
  int likes;
  bool isLiked;
  final DateTime createdAt;

  DiscussionComment({
    required this.id,
    required this.discussionId,
    required this.author,
    required this.authorInitial,
    required this.content,
    required this.timeAgo,
    required this.likes,
    required this.isLiked,
    required this.createdAt,
  });

  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id'],
      discussionId: json['discussionId'],
      author: json['author'],
      authorInitial: json['authorInitial'],
      content: json['content'],
      timeAgo: json['timeAgo'],
      likes: json['likes'],
      isLiked: json['isLiked'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discussionId': discussionId,
      'author': author,
      'authorInitial': authorInitial,
      'content': content,
      'timeAgo': timeAgo,
      'likes': likes,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
    };
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














































