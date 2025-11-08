import 'package:flutter/services.dart';

/// Gift haptic feedback
/// Simple, soft, and consistent feedback for all gifts
class GiftHaptics {
  /// Play haptic feedback for any gift
  /// All gifts use the same soft, quick pattern
  static Future<void> playGiftHaptic(String giftName) async {
    // Simple, soft double-tap pattern (160ms total)
    // Quick and sweet for all gifts
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.selectionClick();
  }
}
