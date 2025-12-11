import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/value_shimmer.dart';

/// Communication type options
enum CommunicationType { calls, messages }

/// Combined Communication Card with touch effects
class AnalyticsCommunicationCard extends StatefulWidget {
  final int callsToday;
  final int messagesCount;
  final int missedCalls;
  final int pendingMessages;
  final VoidCallback? onCallsTap;
  final VoidCallback? onMessagesTap;
  final bool isLoading;

  const AnalyticsCommunicationCard({
    super.key,
    required this.callsToday,
    this.messagesCount = 0,
    this.missedCalls = 0,
    this.pendingMessages = 0,
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

  // Colors for calls and messages
  static const Color _callsColor = Color(0xFF10B981); // Green
  static const Color _messagesColor = Color(0xFF3B82F6); // Blue

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  String get _currentLabel =>
      _selectedType == CommunicationType.calls ? 'Calls Today' : 'Messages Today';

  int get _statusCount => _selectedType == CommunicationType.calls
      ? widget.missedCalls
      : widget.pendingMessages;

  String get _statusLabel =>
      _selectedType == CommunicationType.calls ? 'Missed' : 'Unread';

  void _onTypeChanged(CommunicationType type) {
    if (type != _selectedType) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedType = type;
      });
      _animationController.forward(from: 0);
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.selectionClick();
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
            onTap: _selectedType == CommunicationType.calls
                ? widget.onCallsTap
                : widget.onMessagesTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed
                      ? _activeColor.withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? _activeColor.withOpacity(0.2)
                        : (isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.15)),
                    blurRadius: _isPressed ? 24 : 20,
                    offset: const Offset(0, 8),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectedType == CommunicationType.calls
                      ? widget.onCallsTap
                      : widget.onMessagesTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: _activeColor.withOpacity(0.15),
                  highlightColor: _activeColor.withOpacity(0.08),
                  hoverColor: _activeColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with type selector
                        _buildHeader(theme, isDark),
                        
                        const SizedBox(height: 24),

                        // Main content - Big number with status
                        _buildMainContent(theme, isDark),
                        
                        const SizedBox(height: 8),
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

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Communication',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.textColor,
          ),
        ),
        // Type selector - Flat rounded chips
        _buildTypeSelector(isDark),
      ],
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: CommunicationType.values.map((type) {
        final isSelected = _selectedType == type;
        final color = type == CommunicationType.calls ? _callsColor : _messagesColor;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => _onTypeChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.4)
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
                        ? color
                        : (isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == CommunicationType.calls ? 'Calls' : 'Chat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? color
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

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.isLoading
                  ? const ValueShimmer(width: 90, height: 64, borderRadius: 8)
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Text(
                          (_currentValue * _animation.value).round().toString(),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textColor,
                            letterSpacing: -2,
                            height: 1,
                            fontSize: 56,
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 6),
              Text(
                _currentLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Status indicator (if any)
        if (_statusCount > 0)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isPressed
                  ? Colors.red.withOpacity(0.2)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedType == CommunicationType.calls
                      ? Icons.phone_missed_rounded
                      : Icons.mark_chat_unread_rounded,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_statusCount $_statusLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          )
        else
          // Arrow indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isPressed
                  ? _activeColor.withOpacity(0.2)
                  : _activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: _isPressed ? 26 : 24,
              color: _activeColor,
            ),
          ),
      ],
    );
  }
}
