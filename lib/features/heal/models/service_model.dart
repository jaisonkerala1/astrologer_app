class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String duration;
  final String requirements;
  final List<String> benefits;
  final bool isActive;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.requirements,
    required this.benefits,
    required this.isActive,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      requirements: json['requirements'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'duration': duration,
      'requirements': requirements,
      'benefits': benefits,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? duration,
    String? requirements,
    List<String>? benefits,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static List<ServiceCategory> getDefaultCategories() {
    return [
      ServiceCategory(
        id: 'e_pooja',
        name: 'E-Pooja',
        description: 'Online Pooja Services',
        icon: '🕉️',
        color: '#FF6B6B',
      ),
      ServiceCategory(
        id: 'reiki_healing',
        name: 'Reiki Healing',
        description: 'Energy Healing Sessions',
        icon: '✨',
        color: '#4ECDC4',
      ),
      ServiceCategory(
        id: 'evil_eye_removal',
        name: 'Evil Eye Removal',
        description: 'Protection & Cleansing',
        icon: '👁️',
        color: '#45B7D1',
      ),
      ServiceCategory(
        id: 'vastu_shastra',
        name: 'Vastu Shastra',
        description: 'Space & Architecture Consultation',
        icon: '🏠',
        color: '#96CEB4',
      ),
      ServiceCategory(
        id: 'gemstone_consultation',
        name: 'Gemstone Consultation',
        description: 'Precious Stone Guidance',
        icon: '💎',
        color: '#FFEAA7',
      ),
      ServiceCategory(
        id: 'yantra',
        name: 'Yantra',
        description: 'Sacred Geometry & Symbols',
        icon: '🔯',
        color: '#DDA0DD',
      ),
    ];
  }
}

class ServiceAvailability {
  final String id;
  final String serviceId;
  final List<int> availableDays; // 0-6 (Sunday-Saturday)
  final String startTime;
  final String endTime;
  final int maxBookingsPerDay;
  final int currentBookings;
  final bool isActive;

  ServiceAvailability({
    required this.id,
    required this.serviceId,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.maxBookingsPerDay,
    required this.currentBookings,
    required this.isActive,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      availableDays: List<int>.from(json['availableDays'] ?? []),
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '18:00',
      maxBookingsPerDay: json['maxBookingsPerDay'] ?? 10,
      currentBookings: json['currentBookings'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'maxBookingsPerDay': maxBookingsPerDay,
      'currentBookings': currentBookings,
      'isActive': isActive,
    };
  }
}




































