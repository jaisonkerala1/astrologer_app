import 'package:equatable/equatable.dart';

class AddOnModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String icon; // Icon name or emoji
  final bool isPopular;

  const AddOnModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    this.isPopular = false,
  });

  factory AddOnModel.fromJson(Map<String, dynamic> json) {
    return AddOnModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      icon: json['icon'] ?? '🎁',
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'icon': icon,
      'isPopular': isPopular,
    };
  }

  AddOnModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? icon,
    bool? isPopular,
  }) {
    return AddOnModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      icon: icon ?? this.icon,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, icon, isPopular];
}

