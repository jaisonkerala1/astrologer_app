import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';
import '../screens/service_request_detail_screen.dart';
import '../bloc/heal_bloc.dart';

/// World-class Service Request Card with "One Primary Action" design
/// Matches dashboard card aesthetic with clean, minimal, deliberate interactions
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
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  
  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initAnimations();
  }

  void _initAnimations() {
    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    // Glow animation for in-progress status
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    if (widget.request.status == RequestStatus.inProgress) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ServiceRequestCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.status != oldWidget.request.status ||
        widget.request.startedAt != oldWidget.request.startedAt) {
      _stopTimer();
      _startTimer();
      
      // Update glow animation
      if (widget.request.status == RequestStatus.inProgress) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _scaleController.dispose();
    _glowController.dispose();
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

  void _navigateToDetail(ServiceRequest request) {
    final healBloc = context.read<HealBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: healBloc,
          child: ServiceRequestDetailScreen(
            request: request,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = widget.request;
    final isInProgress = request.status == RequestStatus.inProgress;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                // Base shadow
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
                // Glow effect for in-progress
                if (isInProgress)
                  BoxShadow(
                    color: _getStatusColor().withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                // Press shadow glow
                if (_isPressed)
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
              // Glow border for in-progress
              border: isInProgress
                  ? Border.all(
                      color: _getStatusColor().withOpacity(_glowAnimation.value),
                      width: 2,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (widget.onTap != null) {
                    widget.onTap!();
                  } else {
                    _navigateToDetail(request);
                  }
                },
                splashColor: _getStatusColor().withOpacity(0.1),
                highlightColor: _getStatusColor().withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Gradient Divider
                    _buildGradientDivider(),
                    
                    // Content
                    _buildContent(),
                    
                    // Single Primary Action
                    _buildPrimaryAction(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final request = widget.request;
    final isInProgress = request.status == RequestStatus.inProgress;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor().withOpacity(0.12),
            _getStatusColor().withOpacity(0.06),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Avatar with status indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _getStatusColor().withOpacity(0.2),
                child: Text(
                  request.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              // Live indicator for in-progress
              if (isInProgress)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
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
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.customerPhone,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Status chip or Timer
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildGradientDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _getStatusColor().withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final request = widget.request;
    
    return Padding(
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
                // Service icon + name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getServiceIcon(),
                        size: 16,
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        request.serviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category
                Text(
                  request.serviceCategory,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor.withOpacity(0.5),
                  ),
                ),
                // Special Instructions
                if (request.specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            request.specialInstructions,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Vertical Divider
          Container(
            width: 1,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.textColor.withOpacity(0.0),
                  AppTheme.textColor.withOpacity(0.1),
                  AppTheme.textColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          
          // Right Side: Price + Timing
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price - Hero
                Text(
                  '₹${request.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _getStatusColor(),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                // Date with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppTheme.textColor.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.requestedDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Time with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.textColor.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final request = widget.request;
    
    // Show live timer for in-progress requests
    if (request.status == RequestStatus.inProgress && request.startedAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor().withOpacity(0.2),
              _getStatusColor().withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(_glowAnimation.value),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              _formatDuration(_elapsedTime),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        request.statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, AppLocalizations l10n) {
    final request = widget.request;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _buildSingleActionButton(request.status),
    );
  }

  Widget _buildSingleActionButton(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Align(
          alignment: Alignment.centerRight,
          child: _buildActionPill(
            label: 'View Request',
            icon: Icons.arrow_forward_rounded,
            color: _getStatusColor(),
            onTap: () {
              HapticFeedback.selectionClick();
              _navigateToDetail(widget.request);
            },
          ),
        );
      
      case RequestStatus.confirmed:
        return Align(
          alignment: Alignment.centerRight,
          child: _buildActionPill(
            label: 'Start Pooja',
            icon: Icons.play_arrow_rounded,
            color: _getStatusColor(),
            onTap: () {
              HapticFeedback.mediumImpact();
              _showStartConfirmation();
            },
          ),
        );
      
      case RequestStatus.inProgress:
        return Align(
          alignment: Alignment.centerRight,
          child: _buildActionPill(
            label: 'Complete',
            icon: Icons.check_rounded,
            color: _getStatusColor(),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onComplete();
            },
          ),
        );
      
      case RequestStatus.completed:
        return Align(
          alignment: Alignment.centerRight,
          child: _buildActionPill(
            label: 'View Details',
            icon: Icons.arrow_forward_rounded,
            color: AppTheme.textColor.withOpacity(0.4),
            onTap: () {
              HapticFeedback.selectionClick();
              _navigateToDetail(widget.request);
            },
          ),
        );
      
      case RequestStatus.cancelled:
        return Align(
          alignment: Alignment.centerRight,
          child: _buildActionPill(
            label: 'View Details',
            icon: Icons.arrow_forward_rounded,
            color: AppTheme.textColor.withOpacity(0.4),
            onTap: () {
              HapticFeedback.selectionClick();
              _navigateToDetail(widget.request);
            },
          ),
        );
    }
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isCompleted = widget.request.status == RequestStatus.completed || 
                        widget.request.status == RequestStatus.cancelled;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCompleted ? color.withOpacity(0.15) : color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: !isCompleted
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isCompleted ? color : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              icon,
              size: 14,
              color: isCompleted ? color : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _showStartConfirmation() {
    final request = widget.request;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Start Pooja?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              'You are about to start ${request.serviceName} for ${request.customerName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Start
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context);
                      widget.onStart();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Start Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon() {
    final category = widget.request.serviceCategory.toLowerCase();
    if (category.contains('temple') || category.contains('pooja')) {
      return Icons.temple_hindu_rounded;
    } else if (category.contains('astro')) {
      return Icons.auto_awesome_rounded;
    } else if (category.contains('vastu')) {
      return Icons.home_rounded;
    } else if (category.contains('numerology')) {
      return Icons.numbers_rounded;
    } else if (category.contains('healing')) {
      return Icons.self_improvement_rounded;
    }
    return Icons.spa_rounded;
  }

  Color _getStatusColor() {
    return Color(int.parse(widget.request.statusColor.replaceFirst('#', '0xFF')));
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
