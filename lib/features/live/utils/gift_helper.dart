import 'package:flutter/material.dart';

/// Helper class for gift-related utilities
class GiftHelper {
  /// Map of gift names to their image assets
  static const Map<String, String> giftImages = {
    'rose': 'rose.png',
    'star': 'assets/images/star.png',
    'heart': 'assets/images/heart.png',
    'diamond': 'assets/images/diamond.png',
    'rainbow': 'assets/images/rainbow.png',
    'crown': 'assets/images/crown.png',
  };

  /// Build gift image widget or emoji fallback
  static Widget buildGiftImage(String name, String emoji, double size) {
    final giftName = name.toLowerCase();
    
    if (giftImages.containsKey(giftName)) {
      return Image.asset(
        giftImages[giftName]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
      textAlign: TextAlign.center,
    );
  }

  /// Check if gift has a custom image
  static bool hasCustomImage(String name) {
    return giftImages.containsKey(name.toLowerCase());
  }

  /// Get gift image path if exists
  static String? getGiftImagePath(String name) {
    return giftImages[name.toLowerCase()];
  }

  /// Get the color for a specific gift type
  static Color getGiftColor(String giftName) {
    switch (giftName.toLowerCase()) {
      case 'rose':
        return const Color(0xFFFF4458); // Red
      case 'star':
        return const Color(0xFFFFC107); // Yellow/Gold
      case 'heart':
        return const Color(0xFFE91E63); // Pink
      case 'diamond':
        return const Color(0xFF2196F3); // Blue
      case 'rainbow':
        return const Color(0xFF4CAF50); // Green (representing rainbow)
      case 'crown':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFFFFC107); // Default gold
    }
  }

  /// Extract gift name from message like "🌹 sent Rose"
  static String? extractGiftName(String message) {
    final patterns = ['rose', 'star', 'heart', 'diamond', 'rainbow', 'crown'];
    for (final pattern in patterns) {
      if (message.toLowerCase().contains(pattern)) {
        return pattern[0].toUpperCase() + pattern.substring(1);
      }
    }
    return null;
  }
}

