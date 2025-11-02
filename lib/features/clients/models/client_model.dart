import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Client Model
/// Represents a unique client with aggregated consultation data
class ClientModel extends Equatable {
  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final DateTime firstConsultation;
  final DateTime lastConsultation;
  final int totalConsultations;
  final int completedConsultations;
  final int cancelledConsultations;
  final double totalSpent;
  final int averageDuration; // in minutes
  final String preferredType; // phone, video, inPerson, chat
  final String? lastNotes;
  final double? averageRating;

  const ClientModel({
    required this.clientName,
    required this.clientPhone,
    this.clientEmail,
    required this.firstConsultation,
    required this.lastConsultation,
    required this.totalConsultations,
    required this.completedConsultations,
    required this.cancelledConsultations,
    required this.totalSpent,
    required this.averageDuration,
    required this.preferredType,
    this.lastNotes,
    this.averageRating,
  });

  /// Get initials from client name for avatar
  String get initials {
    final parts = clientName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Get days since last consultation
  int get daysSinceLastConsultation {
    return DateTime.now().difference(lastConsultation).inDays;
  }

  /// Get formatted last consultation text
  String get lastConsultationText {
    final days = daysSinceLastConsultation;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    if (days < 365) return '${(days / 30).floor()} months ago';
    return '${(days / 365).floor()} years ago';
  }

  /// Check if client is recent (within last 30 days)
  bool get isRecent => daysSinceLastConsultation <= 30;

  /// Check if client is frequent (5+ consultations)
  bool get isFrequent => totalConsultations >= 5;

  /// Check if client is VIP (10+ consultations or 10000+ spent)
  bool get isVIP => totalConsultations >= 10 || totalSpent >= 10000;

  /// Get completion rate percentage
  double get completionRate {
    if (totalConsultations == 0) return 0;
    return (completedConsultations / totalConsultations) * 100;
  }

  /// Get avatar color based on name
  Color get avatarColor {
    final colors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
    ];
    final index = clientName.length % colors.length;
    return colors[index];
  }

  /// Get preferred type icon
  IconData get preferredTypeIcon {
    switch (preferredType.toLowerCase()) {
      case 'phone':
        return Icons.phone;
      case 'video':
        return Icons.videocam;
      case 'inperson':
      case 'in_person':
        return Icons.person;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.phone;
    }
  }

  /// Get preferred type display name
  String get preferredTypeDisplay {
    switch (preferredType.toLowerCase()) {
      case 'phone':
        return 'Phone Call';
      case 'video':
        return 'Video Call';
      case 'inperson':
      case 'in_person':
        return 'In Person';
      case 'chat':
        return 'Chat';
      default:
        return preferredType;
    }
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      clientName: json['clientName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      clientEmail: json['clientEmail'],
      firstConsultation: DateTime.parse(json['firstConsultation']),
      lastConsultation: DateTime.parse(json['lastConsultation']),
      totalConsultations: json['totalConsultations'] ?? 0,
      completedConsultations: json['completedConsultations'] ?? 0,
      cancelledConsultations: json['cancelledConsultations'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      averageDuration: json['averageDuration'] ?? 30,
      preferredType: json['preferredType'] ?? 'phone',
      lastNotes: json['lastNotes'],
      averageRating: json['averageRating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'firstConsultation': firstConsultation.toIso8601String(),
      'lastConsultation': lastConsultation.toIso8601String(),
      'totalConsultations': totalConsultations,
      'completedConsultations': completedConsultations,
      'cancelledConsultations': cancelledConsultations,
      'totalSpent': totalSpent,
      'averageDuration': averageDuration,
      'preferredType': preferredType,
      'lastNotes': lastNotes,
      'averageRating': averageRating,
    };
  }

  ClientModel copyWith({
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    DateTime? firstConsultation,
    DateTime? lastConsultation,
    int? totalConsultations,
    int? completedConsultations,
    int? cancelledConsultations,
    double? totalSpent,
    int? averageDuration,
    String? preferredType,
    String? lastNotes,
    double? averageRating,
  }) {
    return ClientModel(
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      firstConsultation: firstConsultation ?? this.firstConsultation,
      lastConsultation: lastConsultation ?? this.lastConsultation,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      completedConsultations: completedConsultations ?? this.completedConsultations,
      cancelledConsultations: cancelledConsultations ?? this.cancelledConsultations,
      totalSpent: totalSpent ?? this.totalSpent,
      averageDuration: averageDuration ?? this.averageDuration,
      preferredType: preferredType ?? this.preferredType,
      lastNotes: lastNotes ?? this.lastNotes,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  @override
  List<Object?> get props => [
        clientName,
        clientPhone,
        clientEmail,
        firstConsultation,
        lastConsultation,
        totalConsultations,
        completedConsultations,
        cancelledConsultations,
        totalSpent,
        averageDuration,
        preferredType,
        lastNotes,
        averageRating,
      ];
}

/// Mock clients data for UI testing
class MockClientsData {
  static List<ClientModel> getMockClients() {
    final now = DateTime.now();
    return [
      ClientModel(
        clientName: 'Priya Sharma',
        clientPhone: '+91 98765 43210',
        clientEmail: 'priya.sharma@example.com',
        firstConsultation: now.subtract(const Duration(days: 180)),
        lastConsultation: now.subtract(const Duration(days: 3)),
        totalConsultations: 12,
        completedConsultations: 10,
        cancelledConsultations: 2,
        totalSpent: 8500,
        averageDuration: 35,
        preferredType: 'video',
        lastNotes: 'Interested in career guidance and relationship advice.',
        averageRating: 4.8,
      ),
      ClientModel(
        clientName: 'Rahul Verma',
        clientPhone: '+91 98765 43211',
        clientEmail: 'rahul.verma@example.com',
        firstConsultation: now.subtract(const Duration(days: 90)),
        lastConsultation: now.subtract(const Duration(days: 1)),
        totalConsultations: 8,
        completedConsultations: 7,
        cancelledConsultations: 1,
        totalSpent: 5600,
        averageDuration: 40,
        preferredType: 'phone',
        lastNotes: 'Business consultation follow-up needed.',
        averageRating: 4.9,
      ),
      ClientModel(
        clientName: 'Anita Desai',
        clientPhone: '+91 98765 43212',
        clientEmail: 'anita.d@example.com',
        firstConsultation: now.subtract(const Duration(days: 365)),
        lastConsultation: now.subtract(const Duration(days: 5)),
        totalConsultations: 24,
        completedConsultations: 22,
        cancelledConsultations: 2,
        totalSpent: 16800,
        averageDuration: 45,
        preferredType: 'video',
        lastNotes: 'Regular monthly consultation client. Very satisfied.',
        averageRating: 5.0,
      ),
      ClientModel(
        clientName: 'Vikram Singh',
        clientPhone: '+91 98765 43213',
        clientEmail: 'vikram.singh@example.com',
        firstConsultation: now.subtract(const Duration(days: 45)),
        lastConsultation: now.subtract(const Duration(days: 10)),
        totalConsultations: 5,
        completedConsultations: 4,
        cancelledConsultations: 1,
        totalSpent: 3500,
        averageDuration: 30,
        preferredType: 'phone',
        lastNotes: 'Health and wellness focus.',
        averageRating: 4.5,
      ),
      ClientModel(
        clientName: 'Meera Krishnan',
        clientPhone: '+91 98765 43214',
        clientEmail: null,
        firstConsultation: now.subtract(const Duration(days: 200)),
        lastConsultation: now.subtract(const Duration(days: 7)),
        totalConsultations: 15,
        completedConsultations: 14,
        cancelledConsultations: 1,
        totalSpent: 10500,
        averageDuration: 38,
        preferredType: 'video',
        lastNotes: 'Family matters and astrological predictions.',
        averageRating: 4.7,
      ),
      ClientModel(
        clientName: 'Arjun Patel',
        clientPhone: '+91 98765 43215',
        clientEmail: 'arjun.patel@example.com',
        firstConsultation: now.subtract(const Duration(days: 15)),
        lastConsultation: now.subtract(const Duration(days: 15)),
        totalConsultations: 1,
        completedConsultations: 1,
        cancelledConsultations: 0,
        totalSpent: 700,
        averageDuration: 25,
        preferredType: 'phone',
        lastNotes: 'First-time client, interested in career counseling.',
        averageRating: 4.0,
      ),
      ClientModel(
        clientName: 'Lakshmi Nair',
        clientPhone: '+91 98765 43216',
        clientEmail: 'lakshmi.nair@example.com',
        firstConsultation: now.subtract(const Duration(days: 120)),
        lastConsultation: now.subtract(const Duration(days: 2)),
        totalConsultations: 9,
        completedConsultations: 9,
        cancelledConsultations: 0,
        totalSpent: 6300,
        averageDuration: 42,
        preferredType: 'video',
        lastNotes: 'Marriage and relationship consultation.',
        averageRating: 4.9,
      ),
      ClientModel(
        clientName: 'Sanjay Gupta',
        clientPhone: '+91 98765 43217',
        clientEmail: 'sanjay.g@example.com',
        firstConsultation: now.subtract(const Duration(days: 60)),
        lastConsultation: now.subtract(const Duration(days: 20)),
        totalConsultations: 6,
        completedConsultations: 5,
        cancelledConsultations: 1,
        totalSpent: 4200,
        averageDuration: 35,
        preferredType: 'phone',
        lastNotes: 'Financial planning and investments.',
        averageRating: 4.6,
      ),
    ];
  }
}

