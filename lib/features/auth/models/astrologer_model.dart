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
  final String? bio;
  final List<String> certifications;
  final List<String> awards;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.bio,
    this.certifications = const [],
    this.awards = const [],
    required this.createdAt,
    required this.updatedAt,
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
      bio: json['bio'],
      certifications: List<String>.from(json['certifications'] ?? []),
      awards: List<String>.from(json['awards'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
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
      'bio': bio,
      'certifications': certifications,
      'awards': awards,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    String? bio,
    List<String>? certifications,
    List<String>? awards,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      awards: awards ?? this.awards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}









