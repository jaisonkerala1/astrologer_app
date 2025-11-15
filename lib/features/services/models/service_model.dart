import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'service_type_enum.dart';
import 'delivery_method_enum.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationInMinutes;
  final ServiceType serviceType;
  final List<DeliveryMethod> availableDeliveryMethods;
  final String iconName; // Material icon name
  final bool isPopular;
  final List<String> whatsIncluded;
  final List<String> howItWorks;
  final String? sampleOutputUrl; // URL to sample output image/PDF
  
  // Astrologer reference
  final String astrologerId;
  
  // Statistics
  final int totalBookings;
  final double averageRating;
  final int reviewCount;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInMinutes,
    required this.serviceType,
    required this.availableDeliveryMethods,
    required this.iconName,
    required this.astrologerId,
    this.isPopular = false,
    this.whatsIncluded = const [],
    this.howItWorks = const [],
    this.sampleOutputUrl,
    this.totalBookings = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  // Helper to get Material icon
  IconData get icon {
    switch (iconName) {
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'work_outline':
        return Icons.work_outline;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'diamond_outlined':
        return Icons.diamond_outlined;
      case 'healing':
        return Icons.healing;
      case 'family_restroom':
        return Icons.family_restroom;
      default:
        return Icons.star;
    }
  }

  // Formatted price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  // Duration display
  String get durationDisplay {
    if (durationInMinutes < 60) {
      return '$durationInMinutes mins';
    } else {
      final hours = durationInMinutes ~/ 60;
      final mins = durationInMinutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $mins mins';
    }
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationInMinutes: json['durationInMinutes'] ?? json['duration'] ?? 0,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == json['serviceType'],
        orElse: () => ServiceType.live,
      ),
      availableDeliveryMethods: (json['availableDeliveryMethods'] as List?)
              ?.map((e) => DeliveryMethod.values.firstWhere(
                    (method) => method.name == e,
                    orElse: () => DeliveryMethod.videoCall,
                  ))
              .toList() ??
          [DeliveryMethod.videoCall],
      iconName: json['iconName'] ?? json['icon'] ?? 'auto_awesome',
      astrologerId: json['astrologerId'] ?? json['astrologer'] ?? '',
      isPopular: json['isPopular'] ?? false,
      whatsIncluded: List<String>.from(json['whatsIncluded'] ?? []),
      howItWorks: List<String>.from(json['howItWorks'] ?? []),
      sampleOutputUrl: json['sampleOutputUrl'],
      totalBookings: json['totalBookings'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationInMinutes': durationInMinutes,
      'serviceType': serviceType.name,
      'availableDeliveryMethods':
          availableDeliveryMethods.map((e) => e.name).toList(),
      'iconName': iconName,
      'astrologerId': astrologerId,
      'isPopular': isPopular,
      'whatsIncluded': whatsIncluded,
      'howItWorks': howItWorks,
      'sampleOutputUrl': sampleOutputUrl,
      'totalBookings': totalBookings,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationInMinutes,
    ServiceType? serviceType,
    List<DeliveryMethod>? availableDeliveryMethods,
    String? iconName,
    String? astrologerId,
    bool? isPopular,
    List<String>? whatsIncluded,
    List<String>? howItWorks,
    String? sampleOutputUrl,
    int? totalBookings,
    double? averageRating,
    int? reviewCount,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      serviceType: serviceType ?? this.serviceType,
      availableDeliveryMethods:
          availableDeliveryMethods ?? this.availableDeliveryMethods,
      iconName: iconName ?? this.iconName,
      astrologerId: astrologerId ?? this.astrologerId,
      isPopular: isPopular ?? this.isPopular,
      whatsIncluded: whatsIncluded ?? this.whatsIncluded,
      howItWorks: howItWorks ?? this.howItWorks,
      sampleOutputUrl: sampleOutputUrl ?? this.sampleOutputUrl,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        durationInMinutes,
        serviceType,
        availableDeliveryMethods,
        iconName,
        astrologerId,
        isPopular,
        whatsIncluded,
        howItWorks,
        sampleOutputUrl,
        totalBookings,
        averageRating,
        reviewCount,
      ];
}

