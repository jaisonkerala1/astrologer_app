import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../screens/service_request_detail_screen.dart';

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

class _ServiceRequestCardWidgetState extends State<ServiceRequestCardWidget> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

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
    } else {
      _stopTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = widget.request; // Local reference for cleaner code
    final onTap = widget.onTap;
    final onAccept = widget.onAccept;
    final onReject = widget.onReject;
    final onComplete = widget.onComplete;
    final onStart = widget.onStart;
    final onPause = widget.onPause;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Transparent to allow ripple effect
        borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick(); // Add haptic feedback
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceRequestDetailScreen(
                  request: request,
                ),
              ),
            );
          }
        },
        splashColor: _getStatusColor().withOpacity(0.1), // Status color ripple
        highlightColor: _getStatusColor().withOpacity(0.05), // Status color highlight
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.20), // Harder color - 20%
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor(),
                    child: Text(
                      request.customerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.customerPhone,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
            ),
            
            // Content - HORIZONTAL SPLIT (Apple Wallet Style)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Service Info
                  Expanded(
                    flex: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Service Name
                        Text(
                          request.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                            letterSpacing: -0.3,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Category
                        Text(
                          request.serviceCategory,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColor.withOpacity(0.6),
                        ),
                      ),
                        // Special Instructions (if exists)
                        if (request.specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 12,
                                color: AppTheme.primaryColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.specialInstructions,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textColor.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.textColor.withOpacity(0.0),
                          AppTheme.textColor.withOpacity(0.15),
                          AppTheme.textColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right Side: Price + Timing
                  Expanded(
                    flex: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        // Price - Hero
                        Text(
                          '₹${request.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.successColor,
                            letterSpacing: -0.8,
                          ),
                      ),
                        const SizedBox(height: 8),
                        // Date
                      Text(
                        _formatDate(request.requestedDate),
                        style: TextStyle(
                          fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                      ),
                        const SizedBox(height: 4),
                        // Time
                      Text(
                        request.requestedTime,
                        style: TextStyle(
                          fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            _buildActionButtons(context, l10n),
          ],
        ),
      ),
      ), // Close Material wrapper
    );
  }

  Widget _buildStatusChip() {
    // Show minimal timer for in-progress requests
    if (widget.request.status == RequestStatus.inProgress && widget.request.startedAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor().withOpacity(0.15),
              _getStatusColor().withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatDuration(_elapsedTime),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    
    // Default status chip
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.request.statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Increased padding, flat design
      child: Row(
        children: _getActionButtons(context, l10n),
      ),
    );
  }

  List<Widget> _getActionButtons(BuildContext context, AppLocalizations l10n) {
    switch (widget.request.status) {
      case RequestStatus.pending:
        return [
          // Accept button - Primary action (65% width for balance)
          Flexible(
            flex: 65,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _getButtonColor(), // Status-matched color (Orange for pending)
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onAccept();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Reject button - Icon only
          Container(
            width: 40,
              height: 40,
              decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                  widget.onReject();
                  },
                  borderRadius: BorderRadius.circular(100),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ),
        ];
      
      case RequestStatus.confirmed:
        return [
          // Start button - Primary action (65% width for balance)
          Flexible(
            flex: 65,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _getButtonColor(), // Status-matched color (Green #10B981 for confirmed)
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onStart();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.play_arrow, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button - Icon only
          Container(
            width: 40,
              height: 40,
              decoration: BoxDecoration(
              color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onReject();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ];
      
      case RequestStatus.inProgress:
        return [
          // Complete button - Primary action (65% width for balance)
          Flexible(
            flex: 65,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _getButtonColor(), // Status-matched color (Blue for in-progress)
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onComplete();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Complete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onPause != null) ...[
            const SizedBox(width: 8),
            // Pause button - Icon only
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onPause!();
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: const Center(
                    child: Icon(
                      Icons.pause,
                      size: 20,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ];
      
      case RequestStatus.completed:
      case RequestStatus.cancelled:
        return [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.request.status == RequestStatus.completed
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 16,
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.request.status == RequestStatus.completed
                        ? 'Completed'
                        : 'Cancelled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textColor.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    return Color(int.parse(widget.request.statusColor.replaceFirst('#', '0xFF')));
  }

  Color _getButtonColor() {
    // Keep the exact current green shade for confirmed status
    if (widget.request.status == RequestStatus.confirmed) {
      return const Color(0xFF10B981); // Current green - DON'T CHANGE
    }
    // For other statuses, match the header color
    return _getStatusColor();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}