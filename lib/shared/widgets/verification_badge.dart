import 'package:flutter/material.dart';

/// Meta/Facebook style verification badge widget
/// Shows a blue checkmark badge next to names or on avatars
class VerificationBadge extends StatelessWidget {
  final double size;
  final bool showBackground;
  
  const VerificationBadge({
    super.key,
    this.size = 16,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground ? BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1877F2), Color(0xFF0C63E4)], // Meta blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ) : null,
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.65,
      ),
    );
  }
}

/// Verified badge for inline text use (name with badge)
class VerifiedTextBadge extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final double badgeSize;
  final double spacing;
  
  const VerifiedTextBadge({
    super.key,
    required this.text,
    this.textStyle,
    this.badgeSize = 16,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: textStyle),
        SizedBox(width: spacing),
        VerificationBadge(size: badgeSize),
      ],
    );
  }
}

/// Verification badge overlay for avatars
class VerifiedAvatarBadge extends StatelessWidget {
  final Widget child; // The avatar widget
  final double badgeSize;
  final double badgeOffset;
  
  const VerifiedAvatarBadge({
    super.key,
    required this.child,
    this.badgeSize = 20,
    this.badgeOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          bottom: badgeOffset,
          right: badgeOffset,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: VerificationBadge(size: badgeSize),
          ),
        ),
      ],
    );
  }
}

