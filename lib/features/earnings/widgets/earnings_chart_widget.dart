import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../shared/theme/app_theme.dart';

class EarningsChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const EarningsChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.primaryColor = AppTheme.primaryColor,
    this.secondaryColor = AppTheme.infoColor,
  });

  @override
  State<EarningsChartWidget> createState() => _EarningsChartWidgetState();
}

class _EarningsChartWidgetState extends State<EarningsChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: EarningsChartPainter(
                    data: widget.data,
                    animation: _animation.value,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EarningsChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;

  EarningsChartPainter({
    required this.data,
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Calculate chart dimensions
    final chartHeight = size.height * 0.7;
    final chartWidth = size.width;
    final padding = 20.0;
    final stepX = (chartWidth - 2 * padding) / (data.length - 1);

    // Find min and max values
    final values = data.map((e) => e['value'] as double).toList();
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = maxValue - minValue;

    // Create path for line chart
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height - padding - (normalizedValue * chartHeight * animation);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - padding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width - padding, size.height - padding);
    fillPath.close();

    // Draw gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.3),
        primaryColor.withOpacity(0.1),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    paint.color = primaryColor;
    canvas.drawPath(path, paint);

    // Draw data points
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height - padding - (normalizedValue * chartHeight * animation);

      // Draw point
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = primaryColor,
      );

      // Draw white center
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.white,
      );
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final label = data[i]['label'] as String;
      
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EarningsBarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final Color primaryColor;

  const EarningsBarChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.primaryColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final maxValue = data.map((e) => e['value'] as double).reduce(math.max);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((item) {
                final height = (item['value'] as double) / maxValue;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: 120 * height,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(item['value'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}





















