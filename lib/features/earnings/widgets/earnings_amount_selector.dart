import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';

/// Amount selector widget with slider and quick buttons
/// Inspired by fintech apps like Razorpay
class EarningsAmountSelector extends StatefulWidget {
  final double availableBalance;
  final double selectedAmount;
  final double minAmount;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback? onWithdraw;
  final bool isProcessing;

  const EarningsAmountSelector({
    super.key,
    required this.availableBalance,
    required this.selectedAmount,
    this.minAmount = 100,
    required this.onAmountChanged,
    this.onWithdraw,
    this.isProcessing = false,
  });

  @override
  State<EarningsAmountSelector> createState() => _EarningsAmountSelectorState();
}

class _EarningsAmountSelectorState extends State<EarningsAmountSelector>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Quick amount options
  List<double> get _quickAmounts {
    final balance = widget.availableBalance;
    if (balance <= 500) {
      return [100, 200, 300, balance];
    } else if (balance <= 2000) {
      return [100, 500, 1000, balance];
    } else if (balance <= 10000) {
      return [500, 1000, 5000, balance];
    } else {
      return [1000, 5000, 10000, balance];
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label
          Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Large amount display
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.selectedAmount == widget.availableBalance
                    ? _pulseAnimation.value
                    : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatAmount(widget.selectedAmount),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Slider
          _buildSlider(isDark),
          
          const SizedBox(height: 8),
          
          // Slider labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${widget.minAmount.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                Text(
                  '₹${_formatAmount(widget.availableBalance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick amount buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _quickAmounts.map((amount) {
              final isSelected = (widget.selectedAmount - amount).abs() < 1;
              final isMax = amount == widget.availableBalance;
              return _QuickAmountButton(
                amount: amount,
                isSelected: isSelected,
                isMax: isMax,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onAmountChanged(amount);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Withdraw button
          _buildWithdrawButton(isDark),
        ],
      ),
    );
  }

  Widget _buildSlider(bool isDark) {
    final sliderValue = widget.selectedAmount.clamp(
      widget.minAmount,
      widget.availableBalance,
    );
    
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: AppTheme.primaryColor,
        inactiveTrackColor: isDark
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        thumbColor: Colors.white,
        thumbShape: const _CustomThumbShape(),
        overlayColor: AppTheme.primaryColor.withOpacity(0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      child: Slider(
        value: sliderValue,
        min: widget.minAmount,
        max: widget.availableBalance,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          widget.onAmountChanged(value.roundToDouble());
        },
      ),
    );
  }

  Widget _buildWithdrawButton(bool isDark) {
    final canWithdraw = widget.selectedAmount >= widget.minAmount &&
        widget.selectedAmount <= widget.availableBalance;

    return GestureDetector(
      onTap: canWithdraw && !widget.isProcessing
          ? () {
              HapticFeedback.mediumImpact();
              widget.onWithdraw?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: canWithdraw && !widget.isProcessing
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1E40AF),
                    Color(0xFF3B82F6),
                  ],
                )
              : null,
          color: canWithdraw && !widget.isProcessing
              ? null
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canWithdraw && !widget.isProcessing
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Withdraw',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: canWithdraw
                            ? Colors.white
                            : isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: canWithdraw
                          ? Colors.white
                          : isDark
                              ? Colors.white38
                              : Colors.grey.shade500,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      final value = amount / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

class _QuickAmountButton extends StatefulWidget {
  final double amount;
  final bool isSelected;
  final bool isMax;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.isSelected,
    required this.isMax,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickAmountButton> createState() => _QuickAmountButtonState();
}

class _QuickAmountButtonState extends State<_QuickAmountButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.primaryColor
              : widget.isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.primaryColor
                : widget.isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: widget.isSelected || _isPressed
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isMax)
              Icon(
                Icons.all_inclusive_rounded,
                size: 14,
                color: widget.isSelected
                    ? Colors.white
                    : widget.isDark
                        ? Colors.white54
                        : Colors.grey.shade600,
              ),
            Text(
              widget.isMax ? 'Max' : '₹${_formatAmount(widget.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isSelected
                    ? Colors.white
                    : widget.isDark
                        ? Colors.white70
                        : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final value = amount / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Custom thumb shape for the slider
class _CustomThumbShape extends SliderComponentShape {
  const _CustomThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer shadow
    final shadowPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 12, shadowPaint);

    // White circle
    final thumbPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 12, thumbPaint);

    // Inner colored circle
    final innerPaint = Paint()..color = AppTheme.primaryColor;
    canvas.drawCircle(center, 6, innerPaint);
  }
}


