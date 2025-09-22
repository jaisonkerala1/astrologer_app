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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isInProgress
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isInProgress ? const Color(0xFF10B981) : Colors.black).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Timer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isInProgress ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isInProgress)
                FadeTransition(
                  opacity: _pulseController,
                  child: const Icon(Icons.circle, color: Colors.white, size: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formatDuration(_elapsedTime),
              style: const TextStyle(
                fontFamily: 'monospace', // Use a monospace font for timer
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.request.status == RequestStatus.confirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement start service functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Start service functionality not implemented yet')),
                  );
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Start Service', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (widget.request.status == RequestStatus.inProgress)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement pause functionality if needed
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pause not implemented yet')),
                      );
                    },
                    icon: const Icon(Icons.pause, color: AppTheme.primaryColor),
                    label: const Text('Pause', style: TextStyle(color: AppTheme.primaryColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement complete service functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Complete service functionality not implemented yet')),
                      );
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Mark as Complete', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}




