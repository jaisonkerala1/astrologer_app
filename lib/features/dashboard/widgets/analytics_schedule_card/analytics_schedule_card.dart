import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/value_shimmer.dart';
import '../../../consultations/services/consultations_service.dart';

/// Schedule view options
enum ScheduleView { today, upcoming }

/// Schedule Card with touch effects
class AnalyticsScheduleCard extends StatefulWidget {
  final VoidCallback? onTap;

  const AnalyticsScheduleCard({
    super.key,
    this.onTap,
  });

  @override
  State<AnalyticsScheduleCard> createState() => _AnalyticsScheduleCardState();
}

class _AnalyticsScheduleCardState extends State<AnalyticsScheduleCard>
    with TickerProviderStateMixin {
  final ConsultationsService _consultationsService = ConsultationsService();
  
  ScheduleView _selectedView = ScheduleView.today;
  int _todayBookings = 0;
  int _upcomingBookings = 0;
  bool _isLoading = true;
  bool _isPressed = false;
  
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  // Colors
  static const Color _todayColor = Color(0xFFF59E0B); // Orange/Amber
  static const Color _upcomingColor = Color(0xFF8B5CF6); // Purple

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
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final todayConsultations = await _consultationsService.getTodaysConsultations();
      final upcomingConsultations = await _consultationsService.getUpcomingConsultations(limit: 10);
      
      setState(() {
        _todayBookings = todayConsultations.length;
        _upcomingBookings = upcomingConsultations.length;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color get _activeColor =>
      _selectedView == ScheduleView.today ? _todayColor : _upcomingColor;

  int get _currentValue =>
      _selectedView == ScheduleView.today ? _todayBookings : _upcomingBookings;

  String get _currentLabel =>
      _selectedView == ScheduleView.today ? 'Appointments Today' : 'Upcoming Appointments';

  void _onViewChanged(ScheduleView view) {
    if (view != _selectedView) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedView = view;
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
            onTap: widget.onTap,
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
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: _activeColor.withOpacity(0.15),
                  highlightColor: _activeColor.withOpacity(0.08),
                  hoverColor: _activeColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with view selector
                        _buildHeader(theme, isDark),
                        
                        const SizedBox(height: 20),

                        // Main content - Big number
                        _buildMainContent(theme, isDark),
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
          'Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.textColor,
          ),
        ),
        // View selector - Flat rounded chips
        _buildViewSelector(isDark),
      ],
    );
  }

  Widget _buildViewSelector(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ScheduleView.values.map((view) {
        final isSelected = _selectedView == view;
        final color = view == ScheduleView.today ? _todayColor : _upcomingColor;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => _onViewChanged(view),
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
                    view == ScheduleView.today
                        ? Icons.today_rounded
                        : Icons.date_range_rounded,
                    size: 14,
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    view == ScheduleView.today ? 'Today' : 'Upcoming',
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
              _isLoading
                  ? const ValueShimmer(width: 70, height: 52, borderRadius: 8)
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Text(
                          (_currentValue * _animation.value).round().toString(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textColor,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              Text(
                _currentLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Calendar icon button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isPressed
                ? _activeColor.withOpacity(0.2)
                : _activeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            size: _isPressed ? 22 : 20,
            color: _activeColor,
          ),
        ),
      ],
    );
  }
}
