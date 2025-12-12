import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/earnings_analytics_model.dart';

/// Animated Area Chart for Analytics Tab
/// Matches the dashboard earnings chart style
class EarningsAnalyticsChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final String subtitle;
  final Color lineColor;
  final Color fillColor;
  final bool showLabels;
  final double height;

  const EarningsAnalyticsChart({
    super.key,
    required this.data,
    this.title = 'Earnings Trend',
    this.subtitle = 'Last 7 days',
    this.lineColor = const Color(0xFF10B981),
    this.fillColor = const Color(0xFF10B981),
    this.showLabels = true,
    this.height = 180,
  });

  @override
  State<EarningsAnalyticsChart> createState() => _EarningsAnalyticsChartState();
}

class _EarningsAnalyticsChartState extends State<EarningsAnalyticsChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    // Don't start animation immediately - wait for visibility
  }

  void _startAnimationIfNeeded() {
    if (!_hasAnimated && mounted) {
      _hasAnimated = true;
      // Small delay for smoother experience
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _VisibilityDetector(
      onVisible: _startAnimationIfNeeded,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              // Total indicator
              if (widget.data.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.lineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 16,
                        color: widget.lineColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${_formatAmount(_calculateTotal())}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.lineColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) => _handleTap(details, constraints),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _AreaChartPainter(
                          data: widget.data,
                          animation: _animation.value,
                          selectedIndex: _selectedIndex,
                          isDark: isDark,
                          lineColor: widget.lineColor,
                          fillColor: widget.fillColor,
                          showLabels: widget.showLabels,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Selected value tooltip
          if (_selectedIndex != null && _selectedIndex! < widget.data.length)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.lineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.lineColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.data[_selectedIndex!].label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.lineColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${widget.data[_selectedIndex!].value.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.lineColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    if (widget.data.isEmpty) return;
    
    final tapX = details.localPosition.dx;
    final chartWidth = constraints.maxWidth - 32;
    final stepX = chartWidth / (widget.data.length - 1);
    final padding = 16.0;

    int nearestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < widget.data.length; i++) {
      final pointX = padding + (i * stepX);
      final distance = (tapX - pointX).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = nearestIndex == _selectedIndex ? null : nearestIndex;
    });
  }

  double _calculateTotal() {
    return widget.data.fold(0.0, (sum, point) => sum + point.value);
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Custom painter for the animated area chart
class _AreaChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double animation;
  final int? selectedIndex;
  final bool isDark;
  final Color lineColor;
  final Color fillColor;
  final bool showLabels;

  _AreaChartPainter({
    required this.data,
    required this.animation,
    this.selectedIndex,
    required this.isDark,
    required this.lineColor,
    required this.fillColor,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 16.0;
    final chartHeight = size.height - (showLabels ? 30 : 10);
    final chartWidth = size.width - (2 * padding);
    final stepX = chartWidth / (data.length - 1);

    // Find min and max values
    final values = data.map((e) => e.value).toList();
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final valueRange = maxValue - minValue;

    // Calculate normalized heights
    double normalizeY(double value) {
      if (valueRange == 0) return chartHeight / 2;
      return chartHeight - ((value - minValue) / valueRange * chartHeight * 0.8 + chartHeight * 0.1);
    }

    // Build path for the line
    final linePath = Path();
    final fillPath = Path();

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final y = normalizeY(data[i].value) * animation + (chartHeight / 2) * (1 - animation);
      points.add(Offset(x, y));
    }

    // Create smooth curve using Catmull-Rom spline
    if (points.length >= 2) {
      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, chartHeight);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i + 2 < points.length ? points[i + 2] : p2;

        // Control points for cubic bezier
        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
        fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }

      // Close fill path
      fillPath.lineTo(points.last.dx, chartHeight);
      fillPath.close();
    }

    // Draw fill gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, chartHeight),
        [
          fillColor.withOpacity(0.4 * animation),
          fillColor.withOpacity(0.05 * animation),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line with glow effect
    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.3 * animation)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(linePath, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..color = lineColor.withOpacity(animation)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Draw data points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = i == selectedIndex;

      if (isSelected) {
        // Selected point glow
        final selectedGlowPaint = Paint()
          ..color = lineColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(point, 12, selectedGlowPaint);
      }

      // Outer ring
      final outerPaint = Paint()
        ..color = lineColor.withOpacity(animation)
        ..style = isSelected ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(point, isSelected ? 8 : 5, outerPaint);

      // Inner dot
      if (!isSelected) {
        final innerPaint = Paint()
          ..color = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        canvas.drawCircle(point, 3, innerPaint);
      }
    }

    // Draw labels
    if (showLabels) {
      final textStyle = TextStyle(
        color: isDark ? Colors.white54 : Colors.grey.shade500,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

      for (int i = 0; i < data.length; i++) {
        final point = points[i];
        final textPainter = TextPainter(
          text: TextSpan(text: data[i].label, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(point.dx - textPainter.width / 2, size.height - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Creative Metric Card with centered design and mini sparkline
class CreativeMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<double>? sparklineData;
  final bool showTrend;
  final double? trendValue;

  const CreativeMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.sparklineData,
    this.showTrend = false,
    this.trendValue,
  });

  @override
  State<CreativeMetricCard> createState() => _CreativeMetricCardState();
}

class _CreativeMetricCardState extends State<CreativeMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Start immediately since these cards are at the top of the page
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (_isPressed ? 0.95 : 1.0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Simple flat icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Value
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 2),

                    // Label
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Trend indicator (minimal)
                    if (widget.showTrend && widget.trendValue != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trendValue! >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: widget.trendValue! >= 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.trendValue!.abs().toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.trendValue! >= 0
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Mini sparkline
                    if (widget.sparklineData != null &&
                        widget.sparklineData!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 20,
                        child: CustomPaint(
                          size: const Size(double.infinity, 20),
                          painter: _MiniSparklinePainter(
                            data: widget.sparklineData!,
                            color: widget.color,
                          ),
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
    );
  }
}

/// Mini sparkline painter for metric cards
class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final valueRange = maxValue - minValue;

    final stepX = size.width / (data.length - 1);

    double normalizeY(double value) {
      if (valueRange == 0) return size.height / 2;
      return size.height - ((value - minValue) / valueRange * size.height * 0.8 + size.height * 0.1);
    }

    final path = Path();
    final fillPath = Path();

    fillPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = normalizeY(data[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [color.withOpacity(0.3), color.withOpacity(0.05)],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Donut Chart for earnings by type
class EarningsDonutChart extends StatefulWidget {
  final List<ConsultationTypeEarning> data;
  final double size;

  const EarningsDonutChart({
    super.key,
    required this.data,
    this.size = 160,
  });

  @override
  State<EarningsDonutChart> createState() => _EarningsDonutChartState();
}

class _EarningsDonutChartState extends State<EarningsDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasAnimated = false;

  final List<Color> _colors = const [
    Color(0xFF10B981), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    // Don't start animation immediately - wait for visibility
  }

  void _startAnimationIfNeeded() {
    if (!_hasAnimated && mounted) {
      _hasAnimated = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _VisibilityDetector(
      onVisible: _startAnimationIfNeeded,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _DonutChartPainter(
              data: widget.data,
              colors: _colors,
              animation: _animation.value,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ConsultationTypeEarning> data;
  final List<Color> colors;
  final double animation;
  final bool isDark;

  _DonutChartPainter({
    required this.data,
    required this.colors,
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 24.0;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].percentage / 100) * 2 * math.pi * animation;
      final color = colors[i % colors.length];

      // Shadow
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );

      // Main arc
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Center circle
    final centerPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    canvas.drawCircle(center, radius - strokeWidth / 2 - 8, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Simple visibility detector that triggers callback when widget is first visible
class _VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;

  const _VisibilityDetector({
    required this.child,
    required this.onVisible,
  });

  @override
  State<_VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<_VisibilityDetector> {
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to check visibility after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (_hasTriggered || !mounted) return;
    
    // Get render object
    final renderObject = context.findRenderObject();
    if (renderObject == null) return;

    // Find scroll ancestor to check if in viewport
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) {
      // No scroll ancestor, widget is visible
      _triggerCallback();
      return;
    }

    // Check if visible in viewport
    final offsetToReveal = viewport.getOffsetToReveal(renderObject, 0.5);
    final viewportHeight = viewport.paintBounds.height;
    
    // If offset is within a reasonable range, consider visible
    if (offsetToReveal.offset.abs() < viewportHeight * 2) {
      _triggerCallback();
    } else {
      // Schedule another check
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibility();
      });
    }
  }

  void _triggerCallback() {
    if (!_hasTriggered && mounted) {
      _hasTriggered = true;
      widget.onVisible();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_hasTriggered) {
          _checkVisibility();
        }
        return false;
      },
      child: widget.child,
    );
  }
}

