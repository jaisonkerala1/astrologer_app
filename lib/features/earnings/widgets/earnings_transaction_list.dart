import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/transaction_model.dart';

/// Grouped transaction list with date headers
/// Styled like modern fintech apps (Stripe/Razorpay)
class EarningsTransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(TransactionModel)? onTransactionTap;

  const EarningsTransactionList({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.onLoadMore,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingState(isDark);
    }

    if (transactions.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // Group transactions by date
    final groupedTransactions = _groupByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, groupIndex) {
        final group = groupedTransactions[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            _buildDateHeader(group.dateLabel, isDark),
            
            // Transactions for this date with staggered animations
            ...group.transactions.asMap().entries.map((entry) {
              final transactionIndex = entry.key;
              final transaction = entry.value;
              
              return _SlideInTransactionTile(
                transaction: transaction,
                isDark: isDark,
                delay: Duration(milliseconds: 50 * transactionIndex),
                onTap: () => onTransactionTap?.call(transaction),
              );
            }),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beautiful illustration with animated elements
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1 * value),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Middle circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.2),
                              AppTheme.infoColor.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                      // Inner icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Floating coins
                      ...List.generate(3, (index) {
                        final angle = (index * 120) * 3.14159 / 180;
                        final radius = 50.0;
                        return Positioned(
                          left: 70 + radius * math.cos(angle + value * 3.14159),
                          top: 70 + radius * math.sin(angle + value * 3.14159),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warningColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '₹',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Animated text
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Column(
                      children: [
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start your first consultation\nand watch your earnings grow!',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Motivational badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successColor.withOpacity(0.1),
                                AppTheme.infoColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 18,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your journey begins now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_TransactionGroup> _groupByDate(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      String label;
      if (transactionDate == today) {
        label = 'Today';
      } else if (transactionDate == yesterday) {
        label = 'Yesterday';
      } else if (today.difference(transactionDate).inDays < 7) {
        label = 'This Week';
      } else if (today.difference(transactionDate).inDays < 30) {
        label = 'This Month';
      } else {
        label = '${_getMonthName(transactionDate.month)} ${transactionDate.year}';
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(transaction);
    }

    // Sort groups by date
    final orderedLabels = ['Today', 'Yesterday', 'This Week', 'This Month'];
    final result = <_TransactionGroup>[];

    for (final label in orderedLabels) {
      if (groups.containsKey(label)) {
        result.add(_TransactionGroup(
          dateLabel: label,
          transactions: groups[label]!,
        ));
        groups.remove(label);
      }
    }

    // Add remaining groups (older months)
    for (final entry in groups.entries) {
      result.add(_TransactionGroup(
        dateLabel: entry.key,
        transactions: entry.value,
      ));
    }

    return result;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _TransactionGroup {
  final String dateLabel;
  final List<TransactionModel> transactions;

  const _TransactionGroup({
    required this.dateLabel,
    required this.transactions,
  });
}

/// Slide-in animation wrapper for transaction tiles
class _SlideInTransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final bool isDark;
  final Duration delay;
  final VoidCallback? onTap;

  const _SlideInTransactionTile({
    required this.transaction,
    required this.isDark,
    this.delay = Duration.zero,
    this.onTap,
  });

  @override
  State<_SlideInTransactionTile> createState() => _SlideInTransactionTileState();
}

class _SlideInTransactionTileState extends State<_SlideInTransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _TransactionTile(
          transaction: widget.transaction,
          isDark: widget.isDark,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final bool isDark;
  final VoidCallback? onTap;

  const _TransactionTile({
    required this.transaction,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  bool _isPressed = false;

  IconData get _transactionIcon {
    final description = widget.transaction.description.toLowerCase();
    if (description.contains('call') || description.contains('voice')) {
      return Icons.phone_rounded;
    } else if (description.contains('chat') || description.contains('message')) {
      return Icons.chat_bubble_rounded;
    } else if (description.contains('video')) {
      return Icons.videocam_rounded;
    } else if (description.contains('pooja') || description.contains('puja')) {
      return Icons.self_improvement_rounded;
    } else if (description.contains('withdraw')) {
      return Icons.arrow_upward_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  Color get _transactionColor {
    if (widget.transaction.isCredit) {
      return AppTheme.successColor;
    }
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: _isPressed ? 12 : 8,
              offset: Offset(0, _isPressed ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: _isPressed
                ? _transactionColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _transactionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _transactionIcon,
                color: _transactionColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            
            // Description & time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.transaction.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.transaction.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.white54
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.transaction.isCredit
                              ? AppTheme.successColor
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.transaction.isCredit ? 'Completed' : 'Processed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.transaction.isCredit
                              ? AppTheme.successColor
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Amount
            Text(
              widget.transaction.formattedAmount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _transactionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


