import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/status_toggle_widget.dart';
import '../widgets/earnings_card_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../../consultations/screens/consultations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../../../shared/widgets/animated_avatar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Start with Dashboard (first tab) as default
  AstrologerModel? _currentUser;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardStatsEvent());
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        setState(() {
          _currentUser = AstrologerModel.fromJson(userDataMap);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          const ConsultationsScreen(),
          const EarningsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80, // Increased height for better touch targets
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          iconSize: 22, // Slightly larger icons for better visibility
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              label: 'Consultations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          } else if (state is DashboardLoadedState) {
            return _buildDashboardBody(state.stats);
        } else if (state is DashboardErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<DashboardBloc>().add(LoadDashboardStatsEvent());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      ),
    );
  }

  Widget _buildDashboardBody(stats) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(_currentUser),
            const SizedBox(height: 24),
            
            // Status Toggle
            StatusToggleWidget(
              isOnline: stats.isOnline,
              onToggle: (isOnline) {
                context.read<DashboardBloc>().add(UpdateOnlineStatusEvent(isOnline));
              },
            ),
            const SizedBox(height: 24),
            
            // Earnings Card
            EarningsCardWidget(
              todayEarnings: stats.todayEarnings,
              totalEarnings: stats.totalEarnings,
              onRefresh: () {
                context.read<DashboardBloc>().add(RefreshDashboardEvent());
              },
              onTap: () {
                // Navigate to earnings screen
                setState(() {
                  _selectedIndex = 2; // Earnings tab
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Calls Today',
                    value: stats.callsToday.toString(),
                    icon: Icons.phone,
                    color: AppTheme.callsColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Total Calls',
                    value: stats.totalCalls.toString(),
                    icon: Icons.call_made,
                    color: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Avg Rating',
                    value: stats.averageRating.toStringAsFixed(1),
                    icon: Icons.star,
                    color: AppTheme.ratingColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Avg Duration',
                    value: '${stats.averageSessionDuration.toStringAsFixed(0)}m',
                    icon: Icons.timer,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AstrologerModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.infoColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnimatedAvatar(
            imagePath: user?.profilePicture,
            radius: 30,
            backgroundColor: Colors.white,
            textColor: AppTheme.primaryColor,
            onTap: () {
              // Navigate to profile
              setState(() {
                _selectedIndex = 3; // Profile tab
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Loading...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
