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
  final String bio;
  final String awards;
  final String certificates;
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
    required this.bio,
    required this.awards,
    required this.certificates,
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
      bio: json['bio'] ?? '',
      awards: json['awards'] ?? '',
      certificates: json['certificates'] ?? '',
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
      'awards': awards,
      'certificates': certificates,
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
    String? awards,
    String? certificates,
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
      awards: awards ?? this.awards,
      certificates: certificates ?? this.certificates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}









