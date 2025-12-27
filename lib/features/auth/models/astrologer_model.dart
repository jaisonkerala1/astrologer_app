import 'package:equatable/equatable.dart';

class AstrologerModel extends Equatable {
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
  final String? sessionId;
  
  // Verification status
  final bool isVerified;
  final String verificationStatus; // 'none', 'pending', 'approved', 'rejected'
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationApprovedAt;
  final String? verificationRejectionReason;
  
  // Terms acceptance tracking
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;
  final int acceptedTermsVersion;
  final String? acceptanceIpAddress;
  final String? acceptanceDeviceInfo;
  
  // Onboarding approval status
  final bool isApproved;
  final DateTime? approvedAt;
  final String? approvedBy;
  
  // Suspension status
  final bool isSuspended;
  final DateTime? suspendedAt;
  final String? suspensionReason;

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
    this.sessionId,
    this.isVerified = false,
    this.verificationStatus = 'none',
    this.verificationSubmittedAt,
    this.verificationApprovedAt,
    this.verificationRejectionReason,
    this.termsAccepted = false,
    this.termsAcceptedAt,
    this.acceptedTermsVersion = 0,
    this.acceptanceIpAddress,
    this.acceptanceDeviceInfo,
    this.isApproved = false,
    this.approvedAt,
    this.approvedBy,
    this.isSuspended = false,
    this.suspendedAt,
    this.suspensionReason,
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
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      sessionId: json['sessionId'] ?? json['activeSession']?['sessionId'],
      isVerified: json['isVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'none',
      verificationSubmittedAt: _parseDateTime(json['verificationSubmittedAt']),
      verificationApprovedAt: _parseDateTime(json['verificationApprovedAt']),
      verificationRejectionReason: json['verificationRejectionReason'],
      termsAccepted: json['termsAccepted'] ?? false,
      termsAcceptedAt: json['termsAcceptedAt'] != null ? DateTime.parse(json['termsAcceptedAt']) : null,
      acceptedTermsVersion: json['acceptedTermsVersion'] ?? 0,
      acceptanceIpAddress: json['acceptanceIpAddress'],
      acceptanceDeviceInfo: json['acceptanceDeviceInfo'],
      isApproved: json['isApproved'] ?? false,
      approvedAt: _parseDateTime(json['approvedAt']),
      approvedBy: json['approvedBy'],
      isSuspended: json['isSuspended'] ?? false,
      suspendedAt: _parseDateTime(json['suspendedAt']),
      suspensionReason: json['suspensionReason'],
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
      'sessionId': sessionId,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationSubmittedAt': verificationSubmittedAt?.toIso8601String(),
      'verificationApprovedAt': verificationApprovedAt?.toIso8601String(),
      'verificationRejectionReason': verificationRejectionReason,
      'termsAccepted': termsAccepted,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'acceptedTermsVersion': acceptedTermsVersion,
      'acceptanceIpAddress': acceptanceIpAddress,
      'acceptanceDeviceInfo': acceptanceDeviceInfo,
      'isApproved': isApproved,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'isSuspended': isSuspended,
      'suspendedAt': suspendedAt?.toIso8601String(),
      'suspensionReason': suspensionReason,
      '_id': id,
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
    String? sessionId,
    bool? isVerified,
    String? verificationStatus,
    DateTime? verificationSubmittedAt,
    DateTime? verificationApprovedAt,
    String? verificationRejectionReason,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    int? acceptedTermsVersion,
    String? acceptanceIpAddress,
    String? acceptanceDeviceInfo,
    bool? isApproved,
    DateTime? approvedAt,
    String? approvedBy,
    bool? isSuspended,
    DateTime? suspendedAt,
    String? suspensionReason,
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
      sessionId: sessionId ?? this.sessionId,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationSubmittedAt: verificationSubmittedAt ?? this.verificationSubmittedAt,
      verificationApprovedAt: verificationApprovedAt ?? this.verificationApprovedAt,
      verificationRejectionReason: verificationRejectionReason ?? this.verificationRejectionReason,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
      acceptanceIpAddress: acceptanceIpAddress ?? this.acceptanceIpAddress,
      acceptanceDeviceInfo: acceptanceDeviceInfo ?? this.acceptanceDeviceInfo,
      isApproved: isApproved ?? this.isApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }
  
  /// Helper method to safely parse DateTime from JSON
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      }
      return null;
    } catch (e) {
      print('⚠️ [AstrologerModel] Error parsing date: $value - $e');
      return null;
    }
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    name,
    email,
    profilePicture,
    specializations,
    languages,
    experience,
    ratePerMinute,
    isOnline,
    totalEarnings,
    bio,
    awards,
    certificates,
    createdAt,
    updatedAt,
    sessionId,
    isVerified,
    verificationStatus,
    verificationSubmittedAt,
    verificationApprovedAt,
    verificationRejectionReason,
    termsAccepted,
    termsAcceptedAt,
    acceptedTermsVersion,
    acceptanceIpAddress,
    acceptanceDeviceInfo,
    isApproved,
    approvedAt,
    approvedBy,
    isSuspended,
    suspendedAt,
    suspensionReason,
  ];
}









