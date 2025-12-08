import 'package:flutter/material.dart';
import '../models/service_model.dart';

/// Widget to display category icon
/// Uses image asset if iconPath is provided, otherwise uses emoji
class CategoryIconWidget extends StatelessWidget {
  final ServiceCategory category;
  final double size;
  final BoxFit fit;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 24,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // Use image if iconPath is provided, otherwise use emoji
    if (category.iconPath != null && category.iconPath!.isNotEmpty) {
      return Image.asset(
        category.iconPath!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to emoji if image fails to load
          return Text(
            category.icon,
            style: TextStyle(fontSize: size * 0.8),
          );
        },
      );
    } else {
      // Use emoji
      return Text(
        category.icon,
        style: TextStyle(fontSize: size * 0.8),
      );
    }
  }
}


