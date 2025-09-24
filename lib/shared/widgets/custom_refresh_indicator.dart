import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sophisticated custom refresh indicator
/// Designed for professional pull-to-refresh experience
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppTheme.primaryColor,
      backgroundColor: backgroundColor ?? Colors.white,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.0,
      child: child,
    );
  }
}

/// Custom refresh indicator with sophisticated animations
class AnimatedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;
  final String? refreshText;

  const AnimatedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.refreshText,
  });

  @override
  State<AnimatedRefreshIndicator> createState() => _AnimatedRefreshIndicatorState();
}

class _AnimatedRefreshIndicatorState extends State<AnimatedRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? AppTheme.primaryColor,
      backgroundColor: widget.backgroundColor ?? Colors.white,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      strokeWidth: 2.0,
      child: Stack(
        children: [
          widget.child,
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: (widget.backgroundColor ?? Colors.white).withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value * 2 * 3.14159,
                            child: Icon(
                              Icons.refresh,
                              color: widget.color ?? AppTheme.primaryColor,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      if (widget.refreshText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          widget.refreshText!,
                          style: TextStyle(
                            color: widget.color ?? AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sophisticated loading overlay for refresh states
class RefreshLoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isRefreshing;
  final String? message;
  final Color? color;

  const RefreshLoadingOverlay({
    super.key,
    required this.child,
    required this.isRefreshing,
    this.message,
    this.color,
  });

  @override
  State<RefreshLoadingOverlay> createState() => _RefreshLoadingOverlayState();
}

class _RefreshLoadingOverlayState extends State<RefreshLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isRefreshing) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RefreshLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isRefreshing)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: (widget.color ?? AppTheme.primaryColor).withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          if (widget.message != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              widget.message!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}


