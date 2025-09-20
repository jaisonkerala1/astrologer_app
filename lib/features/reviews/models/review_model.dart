class ReviewModel {
  final String id;
  final String clientName;
  final String clientAvatar;
  final double rating;
  final String reviewText;
  final DateTime createdAt;
  final String? astrologerReply;
  final DateTime? repliedAt;
  final String sessionId;
  final bool isPublic;

  ReviewModel({
    required this.id,
    required this.clientName,
    this.clientAvatar = '',
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.astrologerReply,
    this.repliedAt,
    required this.sessionId,
    this.isPublic = true,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      clientName: json['clientName'] ?? 'Anonymous',
      clientAvatar: json['clientAvatar'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewText: json['reviewText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      astrologerReply: json['astrologerReply'],
      repliedAt: json['repliedAt'] != null ? DateTime.parse(json['repliedAt']) : null,
      sessionId: json['sessionId'] ?? '',
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt.toIso8601String(),
      'astrologerReply': astrologerReply,
      'repliedAt': repliedAt?.toIso8601String(),
      'sessionId': sessionId,
      'isPublic': isPublic,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? clientName,
    String? clientAvatar,
    double? rating,
    String? reviewText,
    DateTime? createdAt,
    String? astrologerReply,
    DateTime? repliedAt,
    String? sessionId,
    bool? isPublic,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      astrologerReply: astrologerReply ?? this.astrologerReply,
      repliedAt: repliedAt ?? this.repliedAt,
      sessionId: sessionId ?? this.sessionId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
