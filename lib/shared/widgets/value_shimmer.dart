import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/services/theme_service.dart';
import './skeleton_loader.dart';

/// A small, inline shimmer widget for loading dynamic values
/// while keeping the static structure visible
class ValueShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ValueShimmer({
    super.key,
    this.width = 60,
    this.height = 20,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}

/// A shimmer widget for text values with automatic sizing
class TextShimmer extends StatelessWidget {
  final String placeholder;
  final TextStyle? style;
  final double? width;

  const TextShimmer({
    super.key,
    this.placeholder = '0000',
    this.style,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate approximate width based on placeholder if not provided
    final textPainter = TextPainter(
      text: TextSpan(text: placeholder, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return SkeletonLoader(
      width: width ?? textPainter.width,
      height: style?.fontSize ?? 14,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

