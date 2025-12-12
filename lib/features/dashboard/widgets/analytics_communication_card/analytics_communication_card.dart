import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/value_shimmer.dart';

/// Communication type options
enum CommunicationType { calls, messages }

/// Combined Communication Card with world-class UI/UX design
class AnalyticsCommunicationCard extends StatefulWidget {
  final int callsToday;
  final int messagesCount;
  final int missedCalls;
  final int pendingMessages;
  final int callsYesterday;
  final int messagesYesterday;
  final VoidCallback? onCallsTap;
  final VoidCallback? onMessagesTap;
  final bool isLoading;

  const AnalyticsCommunicationCard({
    super.key,
    required this.callsToday,
    this.messagesCount = 0,
    this.missedCalls = 0,
    this.pendingMessages = 0,
    this.callsYesterday = 0,
    this.messagesYesterday = 0,
    this.onCallsTap,
    this.onMessagesTap,
    this.isLoading = false,
  });

  @override
  State<AnalyticsCommunicationCard> createState() =>
      _AnalyticsCommunicationCardState();
}

class _AnalyticsCommunicationCardState extends State<AnalyticsCommunicationCard>
    with TickerProviderStateMixin {
  CommunicationType _selectedType = CommunicationType.calls;
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Colors
  static const Color _callsColor = Color(0xFF10B981); // Green
  static const Color _messagesColor = Color(0xFF3B82F6); // Blue

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color get _activeColor =>
      _selectedType == CommunicationType.calls ? _callsColor : _messagesColor;

  int get _currentValue => _selectedType == CommunicationType.calls
      ? widget.callsToday
      : widget.messagesCount;

  int get _statusCount => _selectedType == CommunicationType.calls
      ? widget.missedCalls
      : widget.pendingMessages;

  String get _statusLabel =>
      _selectedType == CommunicationType.calls ? 'missed' : 'unread';

  int get _yesterdayValue => _selectedType == CommunicationType.calls
      ? widget.callsYesterday
      : widget.messagesYesterday;

  double get _trendPercentage {
    if (_yesterdayValue == 0) {
      return _currentValue > 0 ? 100.0 : 0.0;
    }
    return ((_currentValue - _yesterdayValue) / _yesterdayValue) * 100;
  }

  bool get _isTrendPositive => _trendPercentage >= 0;

  void _onTypeChanged(CommunicationType type) {
    if (type != _selectedType) {
      HapticFeedback.selectionClick();
      setState(() => _selectedType = type);
      _animationController.forward(from: 0);
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _navigateToDetail() {
    HapticFeedback.lightImpact();
    if (_selectedType == CommunicationType.calls) {
      widget.onCallsTap?.call();
    } else {
      widget.onMessagesTap?.call();
    }
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
            onTap: _navigateToDetail,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed
                      ? _activeColor.withOpacity(0.4)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? _activeColor.withOpacity(0.15)
                        : (isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1)),
                    blurRadius: _isPressed ? 20 : 16,
                    offset: const Offset(0, 6),
                    spreadRadius: _isPressed ? 1 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Toggle + View All
                        _buildTopRow(isDark),
                        
                        const SizedBox(height: 20),

                        // Row 2: Big number + Trend
                        _buildMainRow(theme, isDark),
                        
                        const SizedBox(height: 16),
                        
                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                isDark ? Colors.white12 : Colors.grey.shade200,
                                isDark ? Colors.white12 : Colors.grey.shade200,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.8, 1.0],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Status bar
                        _buildStatusBar(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRow(bool isDark) {
    return Row(
      children: [
        // Toggle chips
        _buildToggleChips(isDark),
        
        const Spacer(),
        
        // Active status badge
        _buildActiveBadge(isDark),
      ],
    );
  }

  Widget _buildToggleChips(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: CommunicationType.values.map((type) {
        final isSelected = _selectedType == type;
        final color = type == CommunicationType.calls ? _callsColor : _messagesColor;
        
        return Padding(
          padding: EdgeInsets.only(left: type == CommunicationType.calls ? 0 : 6),
          child: GestureDetector(
            onTap: () => _onTypeChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == CommunicationType.calls
                        ? Icons.phone_rounded
                        : Icons.chat_bubble_rounded,
                    size: 14,
                    color: isSelected 
                        ? Colors.white 
                        : (isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    type == CommunicationType.calls ? 'Calls' : 'Chat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _activeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _activeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Active',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _navigateToDetail,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _activeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainRow(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left: Big number + label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big animated number
              widget.isLoading
                  ? const ValueShimmer(width: 80, height: 52, borderRadius: 8)
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Text(
                          (_currentValue * _animation.value).round().toString(),
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textColor,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              Text(
                _selectedType == CommunicationType.calls ? 'calls today' : 'messages today',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        
        // Right: Trend badge
        _buildTrendBadge(isDark),
      ],
    );
  }

  Widget _buildTrendBadge(bool isDark) {
    if (widget.isLoading || (_yesterdayValue == 0 && _currentValue == 0)) {
      return const SizedBox.shrink();
    }

    final trendColor = _isTrendPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return AnimatedOpacity(
          opacity: _animation.value,
          duration: const Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 16,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_isTrendPositive ? '+' : ''}${_trendPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'vs yesterday',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return Row(
      children: [
        // Status indicator (missed/unread) with icon
        if (_statusCount > 0) ...[
          Icon(
            _selectedType == CommunicationType.calls
                ? Icons.phone_missed_rounded
                : Icons.mark_chat_unread_rounded,
            size: 16,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            '$_statusCount $_statusLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Last activity
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _selectedType == CommunicationType.calls ? 'Last call 12m ago' : 'Last message 5m ago',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // View All button
        GestureDetector(
          onTap: _navigateToDetail,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _activeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
