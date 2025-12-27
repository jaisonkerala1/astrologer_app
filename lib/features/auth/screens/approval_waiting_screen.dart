import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/astrologer_model.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../app/routes.dart';

class ApprovalWaitingScreen extends StatefulWidget {
  final AstrologerModel astrologer;

  const ApprovalWaitingScreen({
    super.key,
    required this.astrologer,
  });

  @override
  State<ApprovalWaitingScreen> createState() => _ApprovalWaitingScreenState();
}

class _ApprovalWaitingScreenState extends State<ApprovalWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<Map<String, dynamic>>? _onboardingApprovedSub;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Listen for real-time approval notification
    _listenForApproval();
  }

  void _listenForApproval() {
    final socketService = getIt<SocketService>();
    _onboardingApprovedSub = socketService.onboardingApprovedStream.listen((data) {
      print('✅ [ApprovalWaiting] Received onboarding_approved event: $data');
      // Refresh profile to get updated isApproved status
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _onboardingApprovedSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    context.read<AuthBloc>().add(CheckAuthStatusEvent());
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(LogoutEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccessState) {
              // Navigate to dashboard when approved
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            } else if (state is AuthUnauthenticatedState ||
                state is AuthLoggedOutState) {
              // Navigate to login when logged out
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            }
          },
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeService.primaryColor.withOpacity(0.05),
                    Colors.white,
                    themeService.accentColor.withOpacity(0.03),
                  ],
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Large Icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeService.primaryColor.withOpacity(0.2),
                                  themeService.accentColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.hourglass_empty,
                              size: 60,
                              color: themeService.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Title
                          Text(
                            'Account Under Review',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: themeService.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Message
                          Text(
                            'Your profile has been submitted!\nOur team will review it within 24-48 hours.\nYou\'ll receive a notification once approved.',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeService.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          // Timeline/Stepper
                          _buildTimeline(themeService),
                          const SizedBox(height: 48),
                          // Action Buttons
                          _buildActionButtons(themeService),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildTimeline(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            themeService,
            step: 1,
            title: 'Profile Submitted',
            status: 'completed',
            description: 'Your profile information has been received',
          ),
          const SizedBox(height: 24),
          _buildTimelineStep(
            themeService,
            step: 2,
            title: 'Under Admin Review',
            status: 'in_progress',
            description: 'Our team is reviewing your profile',
          ),
          const SizedBox(height: 24),
          _buildTimelineStep(
            themeService,
            step: 3,
            title: 'Approval Pending',
            status: 'pending',
            description: 'Waiting for final approval',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    ThemeService themeService, {
    required int step,
    required String title,
    required String status,
    required String description,
  }) {
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in_progress';
    final isPending = status == 'pending';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isInProgress
                        ? themeService.primaryColor
                        : Colors.grey.shade300,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : isInProgress
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        )
                      : null,
            ),
            if (step < 3)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isCompleted || isInProgress
                    ? (isCompleted ? Colors.green : themeService.primaryColor)
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeService themeService) {
    return Column(
      children: [
        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _refreshStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 8),
                Text(
                  'Refresh Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: themeService.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

