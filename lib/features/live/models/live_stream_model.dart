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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveStreamCardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveStreamCardModel(id: $id, astrologerName: $astrologerName, title: $title, category: $category, viewerCount: $viewerCount, isLive: $isLive)';
  }
}