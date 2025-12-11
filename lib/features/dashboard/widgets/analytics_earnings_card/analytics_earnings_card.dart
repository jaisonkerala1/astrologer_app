import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/value_shimmer.dart';

/// Period options for the chart
enum ChartPeriod { today, week, month }

/// Data point model for the chart
class EarningsDataPoint {
  final String label;
  final double value;
  final DateTime? dateTime;

  const EarningsDataPoint({
    required this.label,
    required this.value,
    this.dateTime,
  });
}

/// Interactive Analytics Earnings Card with animated chart
class AnalyticsEarningsCard extends StatefulWidget {
  final double todayEarnings;
  final double totalEarnings;
  final int totalCalls;
  final double averageRating;
  final List<EarningsDataPoint>? weeklyData;
  final List<EarningsDataPoint>? dailyData;
  final List<EarningsDataPoint>? monthlyData;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const AnalyticsEarningsCard({
    super.key,
    required this.todayEarnings,
    required this.totalEarnings,
    this.totalCalls = 0,
    this.averageRating = 0.0,
    this.weeklyData,
    this.dailyData,
    this.monthlyData,
    this.onTap,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<AnalyticsEarningsCard> createState() => _AnalyticsEarningsCardState();
}

class _AnalyticsEarningsCardState extends State<AnalyticsEarningsCard>
    with TickerProviderStateMixin {
  ChartPeriod _selectedPeriod = ChartPeriod.week;
  int? _selectedDataIndex;
  late AnimationController _chartAnimationController;
  late AnimationController _countUpController;
  late Animation<double> _chartAnimation;
  late Animation<double> _countUpAnimation;

  // Chart colors - Emerald Green gradient (positive, motivating)
  static const Color _chartLineStart = Color(0xFF10B981); // Emerald green
  static const Color _chartLineEnd = Color(0xFF34D399);   // Light emerald
  static const Color _chartFillStart = Color(0x4010B981); // Semi-transparent green
  static const Color _chartFillEnd = Color(0x0834D399);   // Very light green fade

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _countUpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    );
    _countUpAnimation = CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOut,
    );

    _chartAnimationController.forward();
    _countUpController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _countUpController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnalyticsEarningsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayEarnings != widget.todayEarnings ||
        oldWidget.totalEarnings != widget.totalEarnings) {
      _countUpController.forward(from: 0);
    }
  }

  List<EarningsDataPoint> get _currentData {
    switch (_selectedPeriod) {
      case ChartPeriod.today:
        return widget.dailyData ?? _generateMockDailyData();
      case ChartPeriod.week:
        return widget.weeklyData ?? _generateMockWeeklyData();
      case ChartPeriod.month:
        return widget.monthlyData ?? _generateMockMonthlyData();
    }
  }

  // Generate mock data if no real data available
  List<EarningsDataPoint> _generateMockWeeklyData() {
    final random = math.Random(42);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final baseValue = widget.todayEarnings > 0 ? widget.todayEarnings : 500;
    return days.map((day) {
      return EarningsDataPoint(
        label: day,
        value: baseValue * (0.5 + random.nextDouble()),
      );
    }).toList();
  }

  List<EarningsDataPoint> _generateMockDailyData() {
    final random = math.Random(42);
    final hours = ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM'];
    final baseValue = widget.todayEarnings > 0 ? widget.todayEarnings / 6 : 100;
    return hours.map((hour) {
      return EarningsDataPoint(
        label: hour,
        value: baseValue * (0.3 + random.nextDouble() * 1.2),
      );
    }).toList();
  }

  List<EarningsDataPoint> _generateMockMonthlyData() {
    final random = math.Random(42);
    final weeks = ['W1', 'W2', 'W3', 'W4'];
    final baseValue = widget.totalEarnings > 0 ? widget.totalEarnings / 4 : 2000;
    return weeks.map((week) {
      return EarningsDataPoint(
        label: week,
        value: baseValue * (0.6 + random.nextDouble() * 0.8),
      );
    }).toList();
  }

  void _onPeriodChanged(ChartPeriod period) {
    if (period != _selectedPeriod) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedPeriod = period;
        _selectedDataIndex = null;
      });
      _chartAnimationController.forward(from: 0);
    }
  }

  void _onChartTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDataIndex = _selectedDataIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(theme, isDark),

              // Main Earnings Display
              _buildEarningsDisplay(theme, isDark),

              // Interactive Chart
              _buildChart(theme, isDark),

              // Mini Stats Row
              _buildMiniStats(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Earnings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textColor,
            ),
          ),
          // Period Selector - Flat rounded chips
          _buildPeriodSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ChartPeriod.values.map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => _onPeriodChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade100)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white24 : Colors.grey.shade300)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: 1,
                ),
              ),
              child: Text(
                _periodLabel(period),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.textColor)
                      : (isDark ? Colors.white54 : Colors.grey.shade500),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _periodLabel(ChartPeriod period) {
    switch (period) {
      case ChartPeriod.today:
        return 'Today';
      case ChartPeriod.week:
        return 'Week';
      case ChartPeriod.month:
        return 'Month';
    }
  }

  Widget _buildEarningsDisplay(ThemeData theme, bool isDark) {
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );

    // Calculate trend percentage (mock for now)
    final trendPercentage = 12.5;
    final isPositiveTrend = trendPercentage >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              widget.isLoading
                  ? const ValueShimmer(width: 140, height: 40, borderRadius: 8)
                  : AnimatedBuilder(
                      animation: _countUpAnimation,
                      builder: (context, _) {
                        final displayValue =
                            widget.todayEarnings * _countUpAnimation.value;
                        return Text(
                          currencyFormat.format(displayValue.round()),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textColor,
                            letterSpacing: -1,
                          ),
                        );
                      },
                    ),
              const SizedBox(width: 12),
              if (!widget.isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend
                            ? AppTheme.successColor
                            : AppTheme.errorColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isPositiveTrend
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendPercentage.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositiveTrend
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Today\'s Earnings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme, bool isDark) {
    final data = _currentData;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        height: 140,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final tapX = details.localPosition.dx;
                    final chartWidth = constraints.maxWidth - 32;
                    final stepX = chartWidth / (data.length - 1);
                    final padding = 16.0;

                    // Find nearest data point
                    int nearestIndex = 0;
                    double minDistance = double.infinity;
                    for (int i = 0; i < data.length; i++) {
                      final pointX = padding + (i * stepX);
                      final distance = (tapX - pointX).abs();
                      if (distance < minDistance) {
                        minDistance = distance;
                        nearestIndex = i;
                      }
                    }
                    _onChartTap(nearestIndex);
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 140),
                    painter: _AreaChartPainter(
                      data: data,
                      animation: _chartAnimation.value,
                      selectedIndex: _selectedDataIndex,
                      isDark: isDark,
                      lineGradientStart: _chartLineStart,
                      lineGradientEnd: _chartLineEnd,
                      fillGradientStart: _chartFillStart,
                      fillGradientEnd: _chartFillEnd,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStats(ThemeData theme, bool isDark) {
    // Generate smart insight based on data
    final insight = _generateInsight();
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: insight.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight.icon,
                size: 16,
                color: insight.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight.message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  _SmartInsight _generateInsight() {
    final data = _currentData;
    if (data.isEmpty || widget.isLoading) {
      return _SmartInsight(
        icon: Icons.insights_rounded,
        message: 'Tap to view detailed analytics',
        color: AppTheme.infoColor,
      );
    }

    // Find best performing day
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final bestDayIndex = data.indexWhere((e) => e.value == maxValue);
    final bestDayLabel = data[bestDayIndex].label;

    // Calculate trend
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );

    switch (_selectedPeriod) {
      case ChartPeriod.today:
        return _SmartInsight(
          icon: Icons.access_time_rounded,
          message: 'Peak earning time was $bestDayLabel',
          color: Colors.orange,
        );
      case ChartPeriod.week:
        return _SmartInsight(
          icon: Icons.trending_up_rounded,
          message: 'Best day: $bestDayLabel with ${currencyFormat.format(maxValue)}',
          color: AppTheme.successColor,
        );
      case ChartPeriod.month:
        return _SmartInsight(
          icon: Icons.calendar_month_rounded,
          message: 'Highest earning week: $bestDayLabel',
          color: AppTheme.primaryColor,
        );
    }
  }
}

/// Model for smart insights
class _SmartInsight {
  final IconData icon;
  final String message;
  final Color color;

  _SmartInsight({
    required this.icon,
    required this.message,
    required this.color,
  });
}

/// Custom painter for the area chart
class _AreaChartPainter extends CustomPainter {
  final List<EarningsDataPoint> data;
  final double animation;
  final int? selectedIndex;
  final bool isDark;
  final Color lineGradientStart;
  final Color lineGradientEnd;
  final Color fillGradientStart;
  final Color fillGradientEnd;

  _AreaChartPainter({
    required this.data,
    required this.animation,
    this.selectedIndex,
    required this.isDark,
    required this.lineGradientStart,
    required this.lineGradientEnd,
    required this.fillGradientStart,
    required this.fillGradientEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 16.0;
    final chartHeight = size.height - 30;
    final chartWidth = size.width - (2 * padding);
    final stepX = chartWidth / (data.length - 1);

    // Find min and max values
    final values = data.map((e) => e.value).toList();
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = maxValue - minValue;

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = 10 + (chartHeight - 20) * (1 - normalizedValue * animation);
      points.add(Offset(x, y));
    }

    // Create smooth curve path
    final linePath = Path();
    final fillPath = Path();

    // Start fill path from bottom
    fillPath.moveTo(padding, chartHeight);
    fillPath.lineTo(points.first.dx, points.first.dy);

    // Draw curve using Catmull-Rom spline
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      for (double t = 0; t <= 1; t += 0.1) {
        final point = _catmullRom(p0, p1, p2, p3, t);
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    // Complete fill path
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    // Draw gradient fill
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillGradientStart, fillGradientEnd],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawPath(fillPath, fillPaint);

    // Draw gradient line
    final lineGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [lineGradientStart, lineGradientEnd],
    );
    final linePaint = Paint()
      ..shader = lineGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Draw data points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = selectedIndex == i;

      // Draw outer glow for selected point
      if (isSelected) {
        canvas.drawCircle(
          point,
          12,
          Paint()..color = lineGradientStart.withOpacity(0.2),
        );
        canvas.drawCircle(
          point,
          8,
          Paint()..color = lineGradientStart.withOpacity(0.3),
        );
      }

      // Draw point
      canvas.drawCircle(
        point,
        isSelected ? 6 : 4,
        Paint()..color = lineGradientStart,
      );
      canvas.drawCircle(
        point,
        isSelected ? 3 : 2,
        Paint()..color = Colors.white,
      );

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade500,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(point.dx - labelPainter.width / 2, size.height - 14),
      );

      // Draw tooltip for selected point
      if (isSelected) {
        _drawTooltip(canvas, point, data[i].value, isDark);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Offset point, double value, bool isDark) {
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );
    final text = currencyFormat.format(value);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = 28.0;
    final tooltipX = point.dx - tooltipWidth / 2;
    final tooltipY = point.dy - tooltipHeight - 12;

    // Draw tooltip background
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(8),
    );

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withOpacity(0.1),
    );

    // Background
    canvas.drawRRect(
      rrect,
      Paint()..color = isDark ? const Color(0xFF2D2D3D) : Colors.white,
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = lineGradientStart.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw pointer
    final pointerPath = Path()
      ..moveTo(point.dx - 6, tooltipY + tooltipHeight)
      ..lineTo(point.dx, tooltipY + tooltipHeight + 6)
      ..lineTo(point.dx + 6, tooltipY + tooltipHeight)
      ..close();
    canvas.drawPath(
      pointerPath,
      Paint()..color = isDark ? const Color(0xFF2D2D3D) : Colors.white,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(tooltipX + 8, tooltipY + (tooltipHeight - textPainter.height) / 2),
    );
  }

  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x = 0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y = 0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}

