import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/consultation_model.dart';
import '../screens/consultation_detail_screen.dart';

class ConsultationCardWidget extends StatefulWidget {
  final ConsultationModel consultation;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const ConsultationCardWidget({
    super.key,
    required this.consultation,
    this.onTap,
    this.onStart,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<ConsultationCardWidget> createState() => _ConsultationCardWidgetState();
}

class _ConsultationCardWidgetState extends State<ConsultationCardWidget> {
  bool _isStarting = false;
  bool _isCompleting = false;
  bool _isCancelling = false;
  Timer? _timer;
  DateTime? _lastStartedAt;
  String? _lastConsultationId;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(ConsultationCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    // Only start timer if consultation is in progress and we don't have a timer running for this consultation
    if (widget.consultation.status == ConsultationStatus.inProgress && 
        widget.consultation.startedAt != null &&
        (_timer == null || _lastConsultationId != widget.consultation.id)) {
      
      // Cancel existing timer if it's for a different consultation
      if (_timer != null && _lastConsultationId != widget.consultation.id) {
        print('Stopping timer for different consultation $_lastConsultationId');
        _timer?.cancel();
      }
      
      _lastStartedAt = widget.consultation.startedAt;
      _lastConsultationId = widget.consultation.id;
      
      print('Starting timer for consultation ${widget.consultation.id} with startedAt: ${widget.consultation.startedAt}');
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    } else if (widget.consultation.status != ConsultationStatus.inProgress && _timer != null) {
      // Stop timer if consultation is no longer in progress
      print('Stopping timer for consultation ${widget.consultation.id}');
      _timer?.cancel();
      _timer = null;
      _lastStartedAt = null;
      _lastConsultationId = null;
    } else if (widget.consultation.status == ConsultationStatus.inProgress && 
               widget.consultation.startedAt != null &&
               _lastConsultationId == widget.consultation.id &&
               _timer != null) {
      // Timer is already running for this consultation, no need to restart
      print('Timer already running for consultation ${widget.consultation.id}, keeping existing timer');
    }
  }

  Future<void> _handleStart() async {
    if (widget.onStart == null) return;
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _isStarting = true;
    });
    
    try {
      widget.onStart!();
      // Wait a bit for the optimistic update to show
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _handleComplete() async {
    if (widget.onComplete == null) return;
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _isCompleting = true;
    });
    
    try {
      widget.onComplete!();
      // Wait a bit for the optimistic update to show
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    if (widget.onCancel == null) return;
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _isCancelling = true;
    });
    
    try {
      widget.onCancel!();
      // Wait a bit for the optimistic update to show
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            boxShadow: [
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
            borderRadius: themeService.borderRadius,
            child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (widget.onTap != null) {
                widget.onTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultationDetailScreen(
                      consultation: widget.consultation,
                    ),
                  ),
                );
              }
            },
            borderRadius: themeService.borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.consultation.clientName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeService.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.consultation.clientPhone,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeService.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.access_time,
                        DateFormat('MMM dd, yyyy - HH:mm').format(widget.consultation.scheduledTime),
                        themeService,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        _getTypeIcon(),
                        widget.consultation.type.displayName,
                        themeService,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.schedule,
                        '${widget.consultation.duration} min',
                        themeService,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        Icons.currency_rupee,
                        '₹${widget.consultation.amount.toStringAsFixed(0)}',
                        themeService,
                      ),
                    ],
                  ),
              if (widget.consultation.status == ConsultationStatus.inProgress && widget.consultation.startedAt != null) ...[
                const SizedBox(height: 8),
                _buildElapsedTime(),
              ],
                  if (widget.consultation.notes != null && widget.consultation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeService.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: themeService.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.consultation.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeService.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip() {
    final color = Color(int.parse(widget.consultation.status.colorCode.substring(1), radix: 16) + 0xFF000000);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            widget.consultation.status.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.consultation.status) {
      case ConsultationStatus.scheduled:
        return Icons.schedule;
      case ConsultationStatus.inProgress:
        return Icons.play_circle_fill;
      case ConsultationStatus.completed:
        return Icons.check_circle;
      case ConsultationStatus.cancelled:
        return Icons.cancel;
      case ConsultationStatus.noShow:
        return Icons.block;
    }
  }

  Widget _buildInfoItem(IconData icon, String text, ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: themeService.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: themeService.textSecondary,
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (widget.consultation.type) {
      case ConsultationType.phone:
        return Icons.phone;
      case ConsultationType.video:
        return Icons.videocam;
      case ConsultationType.inPerson:
        return Icons.person;
      case ConsultationType.chat:
        return Icons.chat;
    }
  }

  Widget _buildElapsedTime() {
    if (widget.consultation.startedAt != null) {
      final now = DateTime.now();
      final startedAt = widget.consultation.startedAt!;
      final elapsed = now.difference(startedAt);
      
      // If elapsed time is negative, it means startedAt is in the future
      if (elapsed.isNegative) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Time sync issue',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
      
      final minutes = elapsed.inMinutes;
      final seconds = elapsed.inSeconds % 60;
      
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Elapsed: ${minutes}m ${seconds.toString().padLeft(2, '0')}s',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Started recently',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    final now = DateTime.now();
    final isToday = widget.consultation.scheduledTime.day == now.day &&
        widget.consultation.scheduledTime.month == now.month &&
        widget.consultation.scheduledTime.year == now.year;
    
    // For testing: Can start if scheduled and within last 7 days or future
    final isRecentOrFuture = widget.consultation.scheduledTime.isAfter(now.subtract(const Duration(days: 7)));
    final canStart = widget.consultation.status == ConsultationStatus.scheduled && isRecentOrFuture;
    
    final canComplete = widget.consultation.status == ConsultationStatus.inProgress;
    
    final canCancel = widget.consultation.status == ConsultationStatus.scheduled;

    if (!canStart && !canComplete && !canCancel) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canStart) ...[
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Match heal tab Accept button green
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isStarting ? null : _handleStart,
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: _isStarting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _isStarting ? 'Starting...' : 'Start',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
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
        ],
        if (canComplete) ...[
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Match heal tab Accept button green
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCompleting ? null : _handleComplete,
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _isCompleting ? 'Completing...' : 'Complete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
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
        ],
        if (canCancel) ...[
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444), // Red solid like service request reject
                borderRadius: BorderRadius.circular(100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCancelling ? null : _handleCancel,
                  borderRadius: BorderRadius.circular(100),
                  child: Center(
                    child: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.close, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

