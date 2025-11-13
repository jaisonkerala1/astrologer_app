import 'package:equatable/equatable.dart';

/// Discovery-enhanced astrologer model with additional social/public metrics
class DiscoveryAstrologer extends Equatable {
  final String id;
  final String name;
  final String? profilePicture;
  final String title; // e.g., "Vedic Astrology Expert"
  final String bio;
  final List<String> specializations;
  final List<String> languages;
  final int experience;
  final double ratePerMinute;
  final bool isOnline;
  final bool isVerified;
  
  // Discovery-specific metrics
  final double rating;
  final int totalReviews;
  final int totalConsultations;
  final int followers;
  final String responseTime; // e.g., "5 min", "1 hour"
  final int repeatClients; // percentage
  final List<String> achievements;
  
  const DiscoveryAstrologer({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.title,
    required this.bio,
    required this.specializations,
    required this.languages,
    required this.experience,
    required this.ratePerMinute,
    required this.isOnline,
    required this.isVerified,
    required this.rating,
    required this.totalReviews,
    required this.totalConsultations,
    required this.followers,
    required this.responseTime,
    required this.repeatClients,
    required this.achievements,
  });

  factory DiscoveryAstrologer.fromJson(Map<String, dynamic> json) {
    return DiscoveryAstrologer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
      title: json['title'] ?? 'Astrology Expert',
      bio: json['bio'] ?? '',
      specializations: List<String>.from(json['specializations'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      experience: json['experience'] ?? 0,
      ratePerMinute: (json['ratePerMinute'] ?? 0).toDouble(),
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalConsultations: json['totalConsultations'] ?? 0,
      followers: json['followers'] ?? 0,
      responseTime: json['responseTime'] ?? 'N/A',
      repeatClients: json['repeatClients'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePicture': profilePicture,
      'title': title,
      'bio': bio,
      'specializations': specializations,
      'languages': languages,
      'experience': experience,
      'ratePerMinute': ratePerMinute,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalConsultations': totalConsultations,
      'followers': followers,
      'responseTime': responseTime,
      'repeatClients': repeatClients,
      'achievements': achievements,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        profilePicture,
        title,
        bio,
        specializations,
        languages,
        experience,
        ratePerMinute,
        isOnline,
        isVerified,
        rating,
        totalReviews,
        totalConsultations,
        followers,
        responseTime,
        repeatClients,
        achievements,
      ];
}

