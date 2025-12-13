import 'package:flutter/material.dart';

/// Gift Helper Utilities
/// Provides helper methods for gift display and interactions
class GiftHelper {
  /// Extract gift name from message
  /// Example: "🌹 sent Rose (₹10)" -> "rose"
  static String? extractGiftName(String message) {
    final lowerMessage = message.toLowerCase();
    
    final giftNames = ['rose', 'star', 'heart', 'diamond', 'rainbow', 'crown'];
    
    for (final name in giftNames) {
      if (lowerMessage.contains(name)) {
        return name;
      }
    }
    
    return null;
  }
  
  /// Get gift color based on gift name
  static Color getGiftColor(String giftName) {
    switch (giftName.toLowerCase()) {
      case 'rose':
        return const Color(0xFFFF1744);
      case 'star':
        return const Color(0xFFFFC107);
      case 'heart':
        return const Color(0xFFE91E63);
      case 'diamond':
        return const Color(0xFF00BCD4);
      case 'rainbow':
        return const Color(0xFF9C27B0);
      case 'crown':
        return const Color(0xFFFFD700);
      default:
        return Colors.amber;
    }
  }
}
