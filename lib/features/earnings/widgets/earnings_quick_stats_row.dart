import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';

/// Quick Stats data model
class QuickStatItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickStatItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// Horizontal scrollable quick stats row
/// Shows earnings breakdown by source (Calls, Chat, Pooja, etc.)
class EarningsQuickStatsRow extends StatelessWidget {
  final List<QuickStatItem> items;
  final String title;
  final bool isLoading;

  const EarningsQuickStatsRow({
    super.key,
    required this.items,
    this.title = 'Recent Earnings',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Horizontal scrollable cards
        SizedBox(
          height: 118,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: isLoading ? 4 : items.length,
            itemBuilder: (context, index) {
              if (isLoading) {
                return _buildSkeletonCard(isDark);
              }
              return _buildStatCard(context, items[index], isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, QuickStatItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _QuickStatCard(item: item, isDark: isDark),
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _QuickStatCard extends StatefulWidget {
  final QuickStatItem item;
  final bool isDark;

  const _QuickStatCard({
    required this.item,
    required this.isDark,
  });

  @override
  State<_QuickStatCard> createState() => _QuickStatCardState();
}

class _QuickStatCardState extends State<_QuickStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.item.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: _isPressed ? 15 : 10,
                    offset: Offset(0, _isPressed ? 6 : 4),
                  ),
                ],
                border: Border.all(
                  color: _isPressed
                      ? widget.item.color.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon in colored circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.item.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: widget.item.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Label
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Amount
                  Text(
                    '₹${_formatAmount(widget.item.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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


