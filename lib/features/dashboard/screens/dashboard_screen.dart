import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/status_service.dart';
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
import '../../heal/screens/heal_screen.dart';
import '../../heal/screens/discussion_screen.dart';
import '../../communication/screens/communication_screen.dart';
import '../../communication/screens/incoming_call_screen.dart';
import '../../reviews/screens/reviews_overview_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';

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
    // Load user data first, then load dashboard stats
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load user data first
    await _loadUserData();
    
    // Then load dashboard stats
    if (mounted) {
      context.read<DashboardBloc>().add(LoadDashboardStatsEvent());
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null && mounted) {
        final userDataMap = jsonDecode(userData);
        setState(() {
          _currentUser = AstrologerModel.fromJson(userDataMap);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Set a fallback user to prevent null issues
      if (mounted) {
        setState(() {
          _currentUser = AstrologerModel(
            id: 'unknown',
            name: 'User',
            email: '',
            phone: '',
            specializations: [],
            languages: [],
            experience: 0,
            ratePerMinute: 0.0,
            isOnline: false,
            totalEarnings: 0.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }
    }
  }

  // Method to refresh user data when profile is updated
  void refreshUserData() {
    _loadUserData();
  }

  ImageProvider? _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('/uploads/')) {
      // Network URL - construct full URL for Railway backend
      if (imagePath.startsWith('/uploads/')) {
        return NetworkImage('https://astrologerapp-production.up.railway.app$imagePath');
      }
      return NetworkImage(imagePath);
    } else {
      // Local file path
      return FileImage(File(imagePath));
    }
  }

  // Method to open communication screen with specific tab
  void _openCommunicationScreen(String tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunicationScreen(initialTab: tab),
      ),
    );
  }

  // Method to simulate incoming call
  void _simulateIncomingCall() {
    print('📞 [DASHBOARD] Simulating incoming call');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomingCallScreen(
          phoneNumber: '+91 98765 43210',
          contactName: 'Sarah Miller',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          const ConsultationsScreen(),
          const HealScreen(),
          const EarningsScreen(),
          ProfileScreen(onProfileUpdated: refreshUserData),
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
            // Add soft haptic feedback
            HapticFeedback.lightImpact();
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
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                label: l10n.dashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                label: l10n.consultations,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.auto_awesome),
                label: l10n.heal,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.trending_up_outlined),
                label: l10n.earnings,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle_outlined),
                label: l10n.profile,
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            // Always show loading if user data is not ready yet
            if (_currentUser == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }
            
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            } else if (state is DashboardLoadedState) {
              return _buildDashboardBody(state.stats);
            } else if (state is DashboardErrorState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        textAlign: TextAlign.center,
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
                ),
              );
            } else {
              // Fallback for any unhandled states (like StatusUpdatedState)
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDashboardBody(stats) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppConstants.defaultPadding * 2,
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
            // Header
            _buildHeader(_currentUser),
            const SizedBox(height: 24),
            
            // Status Toggle
            Consumer<StatusService>(
              builder: (context, statusService, child) {
                if (statusService == null) {
                  // Fallback widget if service is not available
                  return Container(
                    height: 60,
                    child: const Center(
                      child: Text('Status service unavailable'),
                    ),
                  );
                }
                
                return StatusToggleWidget(
                  isOnline: statusService.isOnline,
                  onToggle: (isOnline) {
                    try {
                      HapticFeedback.lightImpact();
                      statusService.setOnlineStatus(isOnline);
                    } catch (e) {
                      print('Error toggling status: $e');
                    }
                  },
                );
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
                  _selectedIndex = 3; // Earnings tab (updated index)
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Communication Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openCommunicationScreen('calls'),
                    child: StatsCardWidget(
                      title: 'Calls Today',
                      value: stats.callsToday.toString(),
                      icon: Icons.phone,
                      color: AppTheme.callsColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openCommunicationScreen('messages'),
                    child: StatsCardWidget(
                      title: 'Messages Today',
                      value: '12', // Mock data - replace with actual messages today
                      icon: Icons.message,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openReviewsScreen(),
                    child: StatsCardWidget(
                      title: 'Avg Rating',
                      value: stats.averageRating.toStringAsFixed(1),
                      icon: Icons.star,
                      color: AppTheme.ratingColor,
                    ),
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
            const SizedBox(height: 24),
            
            // Discussion Card
            _buildDiscussionCard(),
            
            const SizedBox(height: 16),
            
            // Temporary Test Button for Incoming Call
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _simulateIncomingCall,
                icon: const Icon(Icons.call_received, color: Colors.white),
                label: const Text(
                  'Test Incoming Call',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AstrologerModel? user) {
    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to profile
              setState(() {
                _selectedIndex = 4; // Profile tab (updated index)
              });
            },
            child: Container(
              width: 60,
              height: 60,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                    ? _getImageProvider(user!.profilePicture!)
                    : null,
                child: user?.profilePicture == null || user!.profilePicture!.isEmpty
                    ? Text(
                        user?.name?.isNotEmpty == true 
                            ? user!.name!.substring(0, 1).toUpperCase()
                            : 'J',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Loading...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)], // Purple to blue-purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SimpleTouchFeedback(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DiscussionScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Discuss topics of interest with loved ones',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // 3D Illustration placeholder - you can replace this with an actual illustration
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.forum,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReviewsScreen() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewsOverviewScreen(),
      ),
    );
  }
}
