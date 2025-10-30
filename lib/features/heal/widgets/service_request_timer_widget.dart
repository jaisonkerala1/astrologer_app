import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';

class ServiceRequestTimerWidget extends StatefulWidget {
  final ServiceRequest request;

  const ServiceRequestTimerWidget({super.key, required this.request});

  @override
  State<ServiceRequestTimerWidget> createState() => _ServiceRequestTimerWidgetState();
}

class _ServiceRequestTimerWidgetState extends State<ServiceRequestTimerWidget> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startTimer();
  }

  @override
  void didUpdateWidget(ServiceRequestTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.id != oldWidget.request.id ||
        widget.request.status != oldWidget.request.status ||
        widget.request.startedAt != oldWidget.request.startedAt) {
      _stopTimer();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (widget.request.status == RequestStatus.inProgress && widget.request.startedAt != null) {
      _timer?.cancel(); // Cancel any existing timer
      _elapsedTime = DateTime.now().difference(widget.request.startedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = DateTime.now().difference(widget.request.startedAt!);
          });
        }
      });
      _pulseController.forward();
    } else {
      _stopTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _pulseController.stop();
    _pulseController.reset();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String hours = twoDigits(duration.inHours);
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final bool isInProgress = widget.request.status == RequestStatus.inProgress;

    if (!isInProgress) {
      return const SizedBox.shrink(); // Don't show timer if not in progress
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Service in Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(_elapsedTime),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




