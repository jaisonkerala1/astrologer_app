import 'package:flutter/material.dart';

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

enum LiveStreamQuality {
  low,
  medium,
  high,
  ultra,
}

class LiveStreamModel {
  final String id;
  final String astrologerId;
  final String astrologerName;
  final String? astrologerProfilePicture;
  final String astrologerSpecialty;
  final String title;
  final String description;
  final int viewerCount;
  final bool isLive;
  final DateTime startedAt;
  final String? thumbnailUrl;
  final String? streamUrl;
  final List<String> tags;
  final double rating;
  final int totalSessions;
  final String language;
  final bool isVerified;
  final int likes;
  final LiveStreamCategory category;
  final int duration;

  LiveStreamModel({
    required this.id,
    required this.astrologerId,
    required this.astrologerName,
    this.astrologerProfilePicture,
    required this.astrologerSpecialty,
    required this.title,
    required this.description,
    required this.viewerCount,
    required this.isLive,
    required this.startedAt,
    this.thumbnailUrl,
    this.streamUrl,
    this.tags = const [],
    this.rating = 0.0,
    this.totalSessions = 0,
    this.language = 'English',
    this.isVerified = false,
    this.likes = 0,
    this.category = LiveStreamCategory.general,
    this.duration = 0,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      astrologerName: json['astrologerName'] ?? '',
      astrologerProfilePicture: json['astrologerProfilePicture'],
      astrologerSpecialty: json['astrologerSpecialty'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      viewerCount: json['viewerCount'] ?? 0,
      isLive: json['isLive'] ?? false,
      startedAt: DateTime.parse(json['startedAt'] ?? DateTime.now().toIso8601String()),
      thumbnailUrl: json['thumbnailUrl'],
      streamUrl: json['streamUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalSessions: json['totalSessions'] ?? 0,
      language: json['language'] ?? 'English',
      isVerified: json['isVerified'] ?? false,
      likes: json['likes'] ?? 0,
      category: LiveStreamCategory.values.firstWhere(
        (e) => e.toString() == 'LiveStreamCategory.${json['category'] ?? 'general'}',
        orElse: () => LiveStreamCategory.general,
      ),
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerId': astrologerId,
      'astrologerName': astrologerName,
      'astrologerProfilePicture': astrologerProfilePicture,
      'astrologerSpecialty': astrologerSpecialty,
      'title': title,
      'description': description,
      'viewerCount': viewerCount,
      'isLive': isLive,
      'startedAt': startedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'tags': tags,
      'rating': rating,
      'totalSessions': totalSessions,
      'language': language,
      'isVerified': isVerified,
      'likes': likes,
      'category': category.toString().split('.').last,
      'duration': duration,
    };
  }

  LiveStreamModel copyWith({
    String? id,
    String? astrologerId,
    String? astrologerName,
    String? astrologerProfilePicture,
    String? astrologerSpecialty,
    String? title,
    String? description,
    int? viewerCount,
    bool? isLive,
    DateTime? startedAt,
    String? thumbnailUrl,
    String? streamUrl,
    List<String>? tags,
    double? rating,
    int? totalSessions,
    String? language,
    bool? isVerified,
    int? likes,
    LiveStreamCategory? category,
    int? duration,
  }) {
    return LiveStreamModel(
      id: id ?? this.id,
      astrologerId: astrologerId ?? this.astrologerId,
      astrologerName: astrologerName ?? this.astrologerName,
      astrologerProfilePicture: astrologerProfilePicture ?? this.astrologerProfilePicture,
      astrologerSpecialty: astrologerSpecialty ?? this.astrologerSpecialty,
      title: title ?? this.title,
      description: description ?? this.description,
      viewerCount: viewerCount ?? this.viewerCount,
      isLive: isLive ?? this.isLive,
      startedAt: startedAt ?? this.startedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      language: language ?? this.language,
      isVerified: isVerified ?? this.isVerified,
      likes: likes ?? this.likes,
      category: category ?? this.category,
      duration: duration ?? this.duration,
    );
  }

  String get specialty => astrologerSpecialty;

  String get liveDuration {
    final now = DateTime.now();
    final difference = now.difference(startedAt);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String get formattedViewerCount {
    if (viewerCount >= 1000000) {
      return '${(viewerCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewerCount >= 1000) {
      return '${(viewerCount / 1000).toStringAsFixed(1)}K';
    } else {
      return viewerCount.toString();
    }
  }

  String get formattedDuration {
    if (startedAt == null) return '0:00';
    
    final now = DateTime.now();
    final difference = now.difference(startedAt!);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}