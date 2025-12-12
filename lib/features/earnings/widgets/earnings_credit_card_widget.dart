import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';

/// Hero Credit Card Widget - Fintech-inspired earnings display
/// Displays wallet balance in a stunning credit card design with mini chart
class EarningsCreditCardWidget extends StatefulWidget {
  final double totalEarnings;
  final double availableBalance;
  final double pendingAmount;
  final double growthPercentage;
  final List<double>? weeklyData;
  final String periodLabel;
  final VoidCallback? onTap;
  final VoidCallback? onProfileTap;
  final bool isLoading;
  
  // Profile data from backend
  final String? profileName;
  final String? profileImageUrl;

  const EarningsCreditCardWidget({
    super.key,
    required this.totalEarnings,
    required this.availableBalance,
    this.pendingAmount = 0,
    this.growthPercentage = 0,
    this.weeklyData,
    this.periodLabel = 'This Week',
    this.onTap,
    this.onProfileTap,
    this.isLoading = false,
    this.profileName,
    this.profileImageUrl,
  });

  @override
  State<EarningsCreditCardWidget> createState() => _EarningsCreditCardWidgetState();
}

class _EarningsCreditCardWidgetState extends State<EarningsCreditCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _countUpController;
  late AnimationController _chartController;
  late AnimationController _scaleController;
  late Animation<double> _countUpAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Theme colors - Using app's primary colors
  static const Color _gradientStart = Color(0xFF1E40AF); // Primary Blue
  static const Color _gradientMiddle = Color(0xFF3B82F6); // Info Blue
  static const Color _gradientEnd = Color(0xFF6366F1); // Indigo accent

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _countUpController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _countUpAnimation = CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOutCubic,
    );

    // Dedicated chart animation - slower and smoother
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOutCubic,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start animations with slight delay for chart
    _countUpController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _countUpController.dispose();
    _chartController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EarningsCreditCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalEarnings != widget.totalEarnings) {
      _countUpController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _chartController.forward(from: 0);
      });
    }
  }

  List<double> get _chartData {
    if (widget.weeklyData != null && widget.weeklyData!.isNotEmpty) {
      return widget.weeklyData!;
    }
    // Generate mock data based on total earnings
    final random = math.Random(42);
    final base = widget.totalEarnings > 0 ? widget.totalEarnings / 7 : 500;
    return List.generate(7, (i) => base * (0.4 + random.nextDouble() * 1.2));
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientMiddle, _gradientEnd],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _gradientStart.withOpacity(_isPressed ? 0.5 : 0.4),
                    blurRadius: _isPressed ? 30 : 20,
                    offset: Offset(0, _isPressed ? 15 : 10),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  
                  // Shimmer effect
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0),
                              ],
                              stops: [
                                _shimmerController.value - 0.3,
                                _shimmerController.value,
                                _shimmerController.value + 0.3,
                              ].map((s) => s.clamp(0.0, 1.0)).toList(),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Period label & Mini chart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.periodLabel,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Earnings',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            // Mini Area Chart (like dashboard style)
                            _buildMiniAreaChart(),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Main amount with count-up animation
                        AnimatedBuilder(
                          animation: _countUpAnimation,
                          builder: (context, _) {
                            final displayAmount = (widget.availableBalance * _countUpAnimation.value);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatAmount(displayAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Growth indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.growthPercentage >= 0
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.growthPercentage >= 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.growthPercentage >= 0 ? '+' : ''}${widget.growthPercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'vs last period',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Bottom row: Pending & Profile
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Pending amount
                            if (widget.pendingAmount > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹${widget.pendingAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                            
                            // Profile with name and image from backend
                            GestureDetector(
                              onTap: widget.onProfileTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Profile image or placeholder
                                    _buildProfileAvatar(),
                                    const SizedBox(width: 6),
                                    // Profile name or "Profile"
                                    Text(
                                      widget.profileName != null
                                          ? _getFirstName(widget.profileName!)
                                          : 'Profile',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build mini area chart like dashboard earnings chart
  Widget _buildMiniAreaChart() {
    final data = _chartData;
    
    return SizedBox(
      width: 90,
      height: 45,
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, _) {
          return CustomPaint(
            painter: _MiniAreaChartPainter(
              data: data,
              animation: _chartAnimation.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final hasValidUrl = widget.profileImageUrl != null && 
                        widget.profileImageUrl!.isNotEmpty &&
                        (widget.profileImageUrl!.startsWith('http://') || 
                         widget.profileImageUrl!.startsWith('https://'));
    
    if (hasValidUrl) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.3),
        ),
        child: ClipOval(
          child: Image.network(
            widget.profileImageUrl!,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  _getInitials(widget.profileName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Show initials if no valid image URL
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: Text(
        _getInitials(widget.profileName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'G';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getFirstName(String name) {
    final parts = name.trim().split(' ');
    final firstName = parts[0];
    // Limit to 8 characters
    if (firstName.length > 8) {
      return '${firstName.substring(0, 7)}...';
    }
    return firstName;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

/// Custom painter for mini area chart (matches dashboard earnings chart style)
class _MiniAreaChartPainter extends CustomPainter {
  final List<double> data;
  final double animation;

  // Chart colors - White gradient on card background
  static const Color _lineColor = Colors.white;
  static const Color _fillStart = Color(0x60FFFFFF);
  static const Color _fillEnd = Color(0x10FFFFFF);

  _MiniAreaChartPainter({
    required this.data,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = size.height - 4;
    final chartWidth = size.width;
    final stepX = chartWidth / (data.length - 1);

    // Find min and max values
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
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
      final x = i * stepX;
      final y = normalizeY(data[i]) * animation + (chartHeight / 2) * (1 - animation);
      points.add(Offset(x, y));
    }

    // Create smooth curve using Catmull-Rom spline
    if (points.length >= 2) {
      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
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
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
    }

    // Draw fill gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [_fillStart, _fillEnd],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line with glow effect
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(linePath, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..color = _lineColor.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Draw end dot
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      
      // Glow
      final dotGlowPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(lastPoint, 5, dotGlowPaint);
      
      // White dot
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(lastPoint, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniAreaChartPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.data != data;
  }
}

