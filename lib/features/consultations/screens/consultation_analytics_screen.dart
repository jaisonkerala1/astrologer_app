import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../widgets/consultation_analytics_widget.dart';
import '../widgets/consultation_analytics_skeleton.dart';
import '../services/consultations_service.dart';
import '../models/consultation_model.dart';

class ConsultationAnalyticsScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const ConsultationAnalyticsScreen({
    super.key,
    this.initialTabIndex = 2, // Default to All Time tab (index 2)
  });

  @override
  State<ConsultationAnalyticsScreen> createState() => _ConsultationAnalyticsScreenState();
}

class _ConsultationAnalyticsScreenState extends State<ConsultationAnalyticsScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ConsultationsService _consultationsService;
  
  // Analytics data
  Map<String, dynamic> _weeklyStats = {};
  Map<String, dynamic> _monthlyStats = {};
  Map<String, dynamic> _allTimeStats = {};
  
  // Consultation lists
  List<ConsultationModel> _weeklyConsultations = [];
  List<ConsultationModel> _monthlyConsultations = [];
  List<ConsultationModel> _allTimeConsultations = [];
  
  bool _isLoading = true;
  bool _isRefreshing = false; // For background refresh indicator

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _consultationsService = ConsultationsService();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    print('🔄 [AnalyticsScreen] Loading analytics data (two-phase pattern)...');
    
    // 🚀 PHASE 1: INSTANT LOAD - Show cached data immediately (no spinner!)
    try {
      final cachedData = _consultationsService.getInstantAnalyticsData();
      
      if (cachedData.isNotEmpty) {
        setState(() {
          // Load whatever is available from cache
          if (cachedData.containsKey('weeklyStats')) {
            _weeklyStats = cachedData['weeklyStats'] as Map<String, dynamic>;
          }
          if (cachedData.containsKey('monthlyStats')) {
            _monthlyStats = cachedData['monthlyStats'] as Map<String, dynamic>;
          }
          if (cachedData.containsKey('allTimeStats')) {
            _allTimeStats = cachedData['allTimeStats'] as Map<String, dynamic>;
          }
          if (cachedData.containsKey('weeklyConsultations')) {
            _weeklyConsultations = cachedData['weeklyConsultations'] as List<ConsultationModel>;
          }
          if (cachedData.containsKey('monthlyConsultations')) {
            _monthlyConsultations = cachedData['monthlyConsultations'] as List<ConsultationModel>;
          }
          if (cachedData.containsKey('allTimeConsultations')) {
            _allTimeConsultations = cachedData['allTimeConsultations'] as List<ConsultationModel>;
          }
          
          _isLoading = false;
          _isRefreshing = true; // Show subtle refresh indicator
        });
        print('⚡ [AnalyticsScreen] Phase 1: Displayed cached data instantly');
      } else {
        // No cache available, show loading spinner
        setState(() {
          _isLoading = true;
          _isRefreshing = false;
        });
        print('⚠️ [AnalyticsScreen] No cached data, showing loading spinner');
      }
    } catch (e) {
      print('⚠️ [AnalyticsScreen] Error in Phase 1: $e, showing loading spinner');
      setState(() {
        _isLoading = true;
        _isRefreshing = false;
      });
    }

    // 🔄 PHASE 2: BACKGROUND REFRESH - Silently fetch fresh data
    try {
      print('🌐 [AnalyticsScreen] Phase 2: Fetching fresh data from API...');
      
      // Load all analytics data and consultations in parallel
      final results = await Future.wait([
        _consultationsService.getWeeklyConsultationStats(),
        _consultationsService.getMonthlyConsultationStats(),
        _consultationsService.getAllTimeConsultationStats(),
        _consultationsService.getWeeklyConsultations(),
        _consultationsService.getMonthlyConsultations(),
        _consultationsService.getAllTimeConsultations(),
      ]);

      setState(() {
        _weeklyStats = results[0] as Map<String, dynamic>;
        _monthlyStats = results[1] as Map<String, dynamic>;
        _allTimeStats = results[2] as Map<String, dynamic>;
        _weeklyConsultations = results[3] as List<ConsultationModel>;
        _monthlyConsultations = results[4] as List<ConsultationModel>;
        _allTimeConsultations = results[5] as List<ConsultationModel>;
        _isLoading = false;
        _isRefreshing = false; // Hide refresh indicator
      });
      print('✅ [AnalyticsScreen] Phase 2: Fresh data loaded and displayed');
    } catch (e) {
      print('❌ [AnalyticsScreen] Error in Phase 2: $e');
      
      // If we already showed cached data, just hide refresh indicator
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load fresh analytics data: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Consultation Analytics'),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isRefreshing ? null : () {
                  HapticFeedback.selectionClick();
                  _loadAnalyticsData();
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'All Time'),
              ],
            ),
          ),
          body: _isLoading
              ? TabBarView(
                  controller: _tabController,
                  children: const [
                    // Weekly Analytics Skeleton
                    WeeklyAnalyticsSkeleton(),
                    
                    // Monthly Analytics Skeleton
                    MonthlyAnalyticsSkeleton(),
                    
                    // All Time Analytics Skeleton
                    AllTimeAnalyticsSkeleton(),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Weekly Analytics
                    ConsultationAnalyticsWidget(
                      stats: _weeklyStats,
                      period: 'week',
                      consultations: _weeklyConsultations,
                    ),
                    
                    // Monthly Analytics
                    ConsultationAnalyticsWidget(
                      stats: _monthlyStats,
                      period: 'month',
                      consultations: _monthlyConsultations,
                    ),
                    
                    // All Time Analytics
                    ConsultationAnalyticsWidget(
                      stats: _allTimeStats,
                      period: 'all',
                      consultations: _allTimeConsultations,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
