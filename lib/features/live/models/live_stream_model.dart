// Live Stream Models for Agora Integration

enum LiveStreamCategory {
  general,
  astrology,
  healing,
  meditation,
  tarot,
  numerology,
  palmistry,
  spiritual,
}

enum LiveStreamStatus {
  preparing,
  live,
  ended,
  paused,
}

enum LiveStreamQuality {
  low,    // 360p
  medium, // 720p
  high,   // 1080p
  ultra,  // 4K
}


class LiveStreamModel {
  final String id;
  final String astrologerId;
  final String astrologerName;
  final String? astrologerProfilePicture;
  final String title;
  final String? description;
  final LiveStreamCategory category;
  final LiveStreamStatus status;
  final LiveStreamQuality quality;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isPrivate;
  final List<String> tags;
  final String streamUrl;
  final String? thumbnailUrl;
  final int viewerCount;
  final int totalViewers;
  final int likes;
  final int comments;

  const LiveStreamModel({
    required this.id,
    required this.astrologerId,
    required this.astrologerName,
    this.astrologerProfilePicture,
    required this.title,
    this.description,
    required this.category,
    required this.status,
    required this.quality,
    required this.startedAt,
    this.endedAt,
    this.isPrivate = false,
    this.tags = const [],
    required this.streamUrl,
    this.thumbnailUrl,
    this.viewerCount = 0,
    this.totalViewers = 0,
    this.likes = 0,
    this.comments = 0,
  });

  bool get isLive => status == LiveStreamStatus.live;
  bool get isEnded => status == LiveStreamStatus.ended;
  bool get isPreparing => status == LiveStreamStatus.preparing;

  String get durationString {
    final endTime = endedAt ?? DateTime.now();
    final duration = endTime.difference(startedAt);
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String get formattedDuration => durationString;

  String get categoryDisplayName {
    switch (category) {
      case LiveStreamCategory.general:
        return 'General';
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.tarot:
        return 'Tarot';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
    }
  }

  String get qualityDisplayName {
    switch (quality) {
      case LiveStreamQuality.low:
        return '360p';
      case LiveStreamQuality.medium:
        return '720p';
      case LiveStreamQuality.high:
        return '1080p';
      case LiveStreamQuality.ultra:
        return '4K';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case LiveStreamStatus.preparing:
        return 'Preparing';
      case LiveStreamStatus.live:
        return 'Live';
      case LiveStreamStatus.ended:
        return 'Ended';
      case LiveStreamStatus.paused:
        return 'Paused';
    }
  }

  LiveStreamModel copyWith({
    String? id,
    String? astrologerId,
    String? astrologerName,
    String? astrologerProfilePicture,
    String? title,
    String? description,
    LiveStreamCategory? category,
    LiveStreamStatus? status,
    LiveStreamQuality? quality,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isPrivate,
    List<String>? tags,
    String? streamUrl,
    String? thumbnailUrl,
    int? viewerCount,
    int? totalViewers,
    int? likes,
    int? comments,
  }) {
    return LiveStreamModel(
      id: id ?? this.id,
      astrologerId: astrologerId ?? this.astrologerId,
      astrologerName: astrologerName ?? this.astrologerName,
      astrologerProfilePicture: astrologerProfilePicture ?? this.astrologerProfilePicture,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      quality: quality ?? this.quality,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      tags: tags ?? this.tags,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewerCount: viewerCount ?? this.viewerCount,
      totalViewers: totalViewers ?? this.totalViewers,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerId': astrologerId,
      'astrologerName': astrologerName,
      'astrologerProfilePicture': astrologerProfilePicture,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'quality': quality.name,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'isPrivate': isPrivate,
      'tags': tags,
      'streamUrl': streamUrl,
      'thumbnailUrl': thumbnailUrl,
      'viewerCount': viewerCount,
      'totalViewers': totalViewers,
      'likes': likes,
      'comments': comments,
    };
  }

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id'] as String,
      astrologerId: json['astrologerId'] as String,
      astrologerName: json['astrologerName'] as String,
      astrologerProfilePicture: json['astrologerProfilePicture'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: LiveStreamCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LiveStreamCategory.general,
      ),
      status: LiveStreamStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LiveStreamStatus.preparing,
      ),
      quality: LiveStreamQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => LiveStreamQuality.medium,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      streamUrl: json['streamUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewerCount: json['viewerCount'] as int? ?? 0,
      totalViewers: json['totalViewers'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveStreamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveStreamModel(id: $id, title: $title, status: $status, viewerCount: $viewerCount)';
  }
}

// Live Stream Card Model for UI display
class LiveStreamCardModel {
  final String id;
  final String astrologerName;
  final String title;
  final String category;
  final int viewerCount;
  final String thumbnailUrl;
  final String profilePicture;
  final bool isLive;
  final DateTime startTime;

  const LiveStreamCardModel({
    required this.id,
    required this.astrologerName,
    required this.title,
    required this.category,
    required this.viewerCount,
    required this.thumbnailUrl,
    required this.profilePicture,
    required this.isLive,
    required this.startTime,
  });

  String get formattedViewerCount {
    if (viewerCount >= 1000000) {
      return '${(viewerCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewerCount >= 1000) {
      return '${(viewerCount / 1000).toStringAsFixed(1)}K';
    }
    return viewerCount.toString();
  }

  String get durationString {
    final duration = DateTime.now().difference(startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerName': astrologerName,
      'title': title,
      'category': category,
      'viewerCount': viewerCount,
      'thumbnailUrl': thumbnailUrl,
      'profilePicture': profilePicture,
      'isLive': isLive,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory LiveStreamCardModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamCardModel(
      id: json['id'] as String,
      astrologerName: json['astrologerName'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      viewerCount: json['viewerCount'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String,
      profilePicture: json['profilePicture'] as String,
      isLive: json['isLive'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }

  LiveStreamCardModel copyWith({
    String? id,
    String? astrologerName,
    String? title,
    String? category,
    int? viewerCount,
    String? thumbnailUrl,
    String? profilePicture,
    bool? isLive,
    DateTime? startTime,
  }) {
    return LiveStreamCardModel(
      id: id ?? this.id,
      astrologerName: astrologerName ?? this.astrologerName,
      title: title ?? this.title,
      category: category ?? this.category,
      viewerCount: viewerCount ?? this.viewerCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      profilePicture: profilePicture ?? this.profilePicture,
      isLive: isLive ?? this.isLive,
      startTime: startTime ?? this.startTime,
    );
  }
}