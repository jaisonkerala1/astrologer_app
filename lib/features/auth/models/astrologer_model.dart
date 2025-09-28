class AstrologerModel {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String? profilePicture;
  final List<String> specializations;
  final List<String> languages;
  final int experience;
  final double ratePerMinute;
  final bool isOnline;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // New mandatory fields for customer-facing profiles
  final String bio;
  final List<String> education;
  final List<String> certifications;
  final List<String> awards;
  final String responseTime;
  final double successRate;
  final int totalConsultations;
  final double averageRating;
  final int reviewCount;
  final int followerCount;
  final bool isVerified;
  final String? videoIntroduction;
  final List<String> portfolio;
  final Map<String, dynamic> availability;
  final Map<String, dynamic> socialLinks;
  final List<Map<String, dynamic>> specialOffers;
  final List<String> tags;
  final bool featured;
  final int priority;

  AstrologerModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.specializations,
    required this.languages,
    required this.experience,
    required this.ratePerMinute,
    required this.isOnline,
    required this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
    // New mandatory fields
    required this.bio,
    required this.education,
    required this.certifications,
    required this.awards,
    required this.responseTime,
    required this.successRate,
    required this.totalConsultations,
    required this.averageRating,
    required this.reviewCount,
    required this.followerCount,
    required this.isVerified,
    this.videoIntroduction,
    required this.portfolio,
    required this.availability,
    required this.socialLinks,
    required this.specialOffers,
    required this.tags,
    required this.featured,
    required this.priority,
  });

  factory AstrologerModel.fromJson(Map<String, dynamic> json) {
    return AstrologerModel(
      id: json['_id'] ?? json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      specializations: List<String>.from(json['specializations'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      experience: json['experience'] ?? 0,
      ratePerMinute: (json['ratePerMinute'] ?? 0).toDouble(),
      isOnline: json['isOnline'] ?? false,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      // New mandatory fields
      bio: json['bio'] ?? 'Professional astrologer with years of experience',
      education: List<String>.from(json['education'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      awards: List<String>.from(json['awards'] ?? []),
      responseTime: json['responseTime'] ?? 'Responds in 2 hours',
      successRate: (json['successRate'] ?? 95.0).toDouble(),
      totalConsultations: json['totalConsultations'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      followerCount: json['followerCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      videoIntroduction: json['videoIntroduction'],
      portfolio: List<String>.from(json['portfolio'] ?? []),
      availability: Map<String, dynamic>.from(json['availability'] ?? {}),
      socialLinks: Map<String, dynamic>.from(json['socialLinks'] ?? {}),
      specialOffers: List<Map<String, dynamic>>.from(json['specialOffers'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      featured: json['featured'] ?? false,
      priority: json['priority'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'specializations': specializations,
      'languages': languages,
      'experience': experience,
      'ratePerMinute': ratePerMinute,
      'isOnline': isOnline,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // New mandatory fields
      'bio': bio,
      'education': education,
      'certifications': certifications,
      'awards': awards,
      'responseTime': responseTime,
      'successRate': successRate,
      'totalConsultations': totalConsultations,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'followerCount': followerCount,
      'isVerified': isVerified,
      'videoIntroduction': videoIntroduction,
      'portfolio': portfolio,
      'availability': availability,
      'socialLinks': socialLinks,
      'specialOffers': specialOffers,
      'tags': tags,
      'featured': featured,
      'priority': priority,
    };
  }

  AstrologerModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? profilePicture,
    List<String>? specializations,
    List<String>? languages,
    int? experience,
    double? ratePerMinute,
    bool? isOnline,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    // New mandatory fields
    String? bio,
    List<String>? education,
    List<String>? certifications,
    List<String>? awards,
    String? responseTime,
    double? successRate,
    int? totalConsultations,
    double? averageRating,
    int? reviewCount,
    int? followerCount,
    bool? isVerified,
    String? videoIntroduction,
    List<String>? portfolio,
    Map<String, dynamic>? availability,
    Map<String, dynamic>? socialLinks,
    List<Map<String, dynamic>>? specialOffers,
    List<String>? tags,
    bool? featured,
    int? priority,
  }) {
    return AstrologerModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      specializations: specializations ?? this.specializations,
      languages: languages ?? this.languages,
      experience: experience ?? this.experience,
      ratePerMinute: ratePerMinute ?? this.ratePerMinute,
      isOnline: isOnline ?? this.isOnline,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // New mandatory fields
      bio: bio ?? this.bio,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      awards: awards ?? this.awards,
      responseTime: responseTime ?? this.responseTime,
      successRate: successRate ?? this.successRate,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      followerCount: followerCount ?? this.followerCount,
      isVerified: isVerified ?? this.isVerified,
      videoIntroduction: videoIntroduction ?? this.videoIntroduction,
      portfolio: portfolio ?? this.portfolio,
      availability: availability ?? this.availability,
      socialLinks: socialLinks ?? this.socialLinks,
      specialOffers: specialOffers ?? this.specialOffers,
      tags: tags ?? this.tags,
      featured: featured ?? this.featured,
      priority: priority ?? this.priority,
    );
  }
}









