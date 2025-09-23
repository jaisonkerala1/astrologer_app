import 'package:flutter/material.dart';

enum LiveStreamStatus {
  preparing,
  live,
  ended,
  paused,
}

enum LiveStreamQuality {
  low,
  medium,
  high,
  ultra,
}

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
  final int viewerCount;
  final int totalViewers;
  final int likes;
  final int comments;
  final bool isPrivate;
  final String? thumbnailUrl;
  final String? streamUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  LiveStreamModel({
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
    this.viewerCount = 0,
    this.totalViewers = 0,
    this.likes = 0,
    this.comments = 0,
    this.isPrivate = false,
    this.thumbnailUrl,
    this.streamUrl,
    this.tags = const [],
    this.metadata = const {},
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      astrologerName: json['astrologerName'] ?? '',
      astrologerProfilePicture: json['astrologerProfilePicture'],
      title: json['title'] ?? '',
      description: json['description'],
      category: LiveStreamCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LiveStreamCategory.general,
      ),
      status: LiveStreamStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LiveStreamStatus.ended,
      ),
      quality: LiveStreamQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => LiveStreamQuality.medium,
      ),
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      viewerCount: json['viewerCount'] ?? 0,
      totalViewers: json['totalViewers'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
      thumbnailUrl: json['thumbnailUrl'],
      streamUrl: json['streamUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
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
      'viewerCount': viewerCount,
      'totalViewers': totalViewers,
      'likes': likes,
      'comments': comments,
      'isPrivate': isPrivate,
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'tags': tags,
      'metadata': metadata,
    };
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
    int? viewerCount,
    int? totalViewers,
    int? likes,
    int? comments,
    bool? isPrivate,
    String? thumbnailUrl,
    String? streamUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
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
      viewerCount: viewerCount ?? this.viewerCount,
      totalViewers: totalViewers ?? this.totalViewers,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isPrivate: isPrivate ?? this.isPrivate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isLive => status == LiveStreamStatus.live;
  bool get isEnded => status == LiveStreamStatus.ended;
  bool get isPreparing => status == LiveStreamStatus.preparing;
  
  Duration get duration {
    final endTime = endedAt ?? DateTime.now();
    return endTime.difference(startedAt);
  }

  String get formattedDuration {
    final duration = this.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}











