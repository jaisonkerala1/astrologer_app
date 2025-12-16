import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/service_request_model.dart';
import '../screens/service_request_detail_screen.dart';
import '../bloc/heal_bloc.dart';

/// Minimal Flight-Booking Style Service Request Card
class ServiceRequestCardWidget extends StatefulWidget {
  final ServiceRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onStart;
  final VoidCallback? onPause;
  final VoidCallback? onTap;

  const ServiceRequestCardWidget({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onStart,
    this.onPause,
    this.onTap,
  });

  @override
  State<ServiceRequestCardWidget> createState() => _ServiceRequestCardWidgetState();
}

class _ServiceRequestCardWidgetState extends State<ServiceRequestCardWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isAccepting = false;
  bool _isStarting = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(ServiceRequestCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.status != oldWidget.request.status ||
        widget.request.startedAt != oldWidget.request.startedAt) {
      _stopTimer();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    if (widget.request.status == RequestStatus.inProgress && widget.request.startedAt != null) {
      _timer?.cancel();
      _elapsedTime = DateTime.now().difference(widget.request.startedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = DateTime.now().difference(widget.request.startedAt!);
          });
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}';
    return '${twoDigits(m)}:${twoDigits(s)}';
  }

  void _navigateToDetail() {
    final healBloc = context.read<HealBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: healBloc,
          child: ServiceRequestDetailScreen(request: widget.request),
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      widget.onAccept();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _handleStart() async {
    setState(() => _isStarting = true);
    try {
      _showStartSheet();
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isCompleting = true);
    try {
      widget.onComplete();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Color get _accentColor => Color(int.parse(widget.request.statusColor.replaceFirst('#', '0xFF')));
  
  static const _textDark = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF9CA3AF);

  IconData get _categoryIcon {
    final category = widget.request.serviceCategory.toLowerCase();
    if (category.contains('temple') || category.contains('pooja') || category.contains('devotional')) {
      return Icons.temple_hindu_rounded;
    } else if (category.contains('astro') || category.contains('horoscope')) {
      return Icons.auto_awesome_rounded;
    } else if (category.contains('vastu')) {
      return Icons.home_rounded;
    } else if (category.contains('numerology')) {
      return Icons.tag_rounded;
    } else if (category.contains('tarot')) {
      return Icons.style_rounded;
    } else if (category.contains('healing') || category.contains('reiki')) {
      return Icons.self_improvement_rounded;
    } else if (category.contains('palmistry')) {
      return Icons.back_hand_rounded;
    }
    return Icons.spa_rounded;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Same as consultation card
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              _navigateToDetail();
            }
          },
          // State-based ripple colors (same pattern as consultation)
          splashColor: _accentColor.withOpacity(0.1),
          highlightColor: _accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              _buildHeader(request),
              _buildMiddle(request),
              _buildDivider(),
              _buildFooter(request),
            ],
          ),
        ),
      ),
    );
  }

  /// Header: Logo Badge | Service Name | ID
  Widget _buildHeader(ServiceRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Logo Badge (like "Citilink")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcon,
                  size: 14,
                  color: _accentColor,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.request.serviceCategory.length > 8 
                      ? widget.request.serviceCategory.substring(0, 8)
                      : widget.request.serviceCategory,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Service Name (like "Citilink Airline")
          Expanded(
            child: Text(
              request.serviceName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ID/Status (like "ID3242113")
          Text(
            _getStatusLabel(request),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(ServiceRequest request) {
    if (request.status == RequestStatus.inProgress && request.startedAt != null) {
      return _formatDuration(_elapsedTime);
    }
    return 'ID${request.id.substring(request.id.length - 6).toUpperCase()}';
  }

  /// Middle: Time + Customer | Duration Icon | Price + Status
  Widget _buildMiddle(ServiceRequest request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left - Time & Customer (like "01:30 AM CGK (Jakarta)")
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requestedTime,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  request.customerPhone,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Center - Duration icon (like "7h 15m" with plane)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Icon(
                  _getDurationIcon(request.status),
                  size: 24,
                  color: _accentColor,
                ),
                const SizedBox(height: 4),
                Text(
                  _getDurationText(request),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Right - Price & Status (like "01:30 AM NRT (Tokyo)")
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${request.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  widget.request.serviceCategory,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDurationIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.schedule_outlined;
      case RequestStatus.confirmed:
        return Icons.event_available_outlined;
      case RequestStatus.inProgress:
        return Icons.access_time;
      case RequestStatus.completed:
        return Icons.check_circle_outline;
      case RequestStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getDurationText(ServiceRequest request) {
    if (request.status == RequestStatus.inProgress && request.startedAt != null) {
      return _formatDuration(_elapsedTime);
    }
    return 'Booking';
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(
          40,
          (i) => Expanded(
            child: Container(
              height: 1,
              color: i.isEven ? const Color(0xFFE5E7EB) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  /// Footer: DATE | TIME | Action
  Widget _buildFooter(ServiceRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          // DATE (like "TERMINAL 2A")
          _footerItem('DATE', _formatDate(request.requestedDate)),
          // TIME (like "GATE 19")
          _footerItem('TIME', request.requestedTime, center: true),
          // ACTION (like "Economy")
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ACTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                _buildAction(request),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value, {bool center = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(ServiceRequest request) {
    final isPrimary = request.status != RequestStatus.completed && 
                      request.status != RequestStatus.cancelled;
    
    String label;
    VoidCallback onTap;
    bool showLoader = false;
    
    switch (request.status) {
      case RequestStatus.pending:
        label = 'Accept';
        onTap = _handleAccept;
        showLoader = _isAccepting;
        break;
      case RequestStatus.confirmed:
        label = 'Start';
        onTap = _handleStart;
        showLoader = _isStarting;
        break;
      case RequestStatus.inProgress:
        label = 'Complete';
        onTap = _handleComplete;
        showLoader = _isCompleting;
        break;
      default:
        label = 'View';
        onTap = _navigateToDetail;
    }
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isPrimary ? _accentColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showLoader ? null : () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: showLoader
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPrimary ? Colors.white : _accentColor,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white : _textMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStartSheet() {
    final request = widget.request;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Start ${request.serviceName}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For ${request.customerName}',
              style: const TextStyle(
                fontSize: 14,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(24),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onStart();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: const Center(
                          child: Text(
                            'Start Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
