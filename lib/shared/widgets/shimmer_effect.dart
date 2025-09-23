import 'package:flutter/material.dart';

/// Premium shimmer effect widget with sophisticated animations
/// Designed for professional loading states with smooth 60fps performance
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final double shimmerWidth;
  final bool enabled;
  final Curve curve;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.shimmerWidth = 0.3,
    this.enabled = true,
    this.curve = Curves.easeInOut,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ));

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                _animation.value - widget.shimmerWidth,
                _animation.value,
                _animation.value + widget.shimmerWidth,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton container with shimmer effect
class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool enabled;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
    this.padding,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      enabled: enabled,
      baseColor: color ?? Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton text with shimmer effect
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool enabled;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      enabled: enabled,
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}

/// Skeleton circle with shimmer effect
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? color;
  final bool enabled;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      enabled: enabled,
      baseColor: color ?? Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton list item with shimmer effect
class ShimmerListItem extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool enabled;

  const ShimmerListItem({
    super.key,
    this.height,
    this.padding,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      enabled: enabled,
      child: Container(
        height: height ?? 72.0,
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}



