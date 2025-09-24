import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../widgets/consultation_analytics_widget.dart';
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
    setState(() {
      _isLoading = true;
    });

    try {
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
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics data: $e'),
            backgroundColor: Colors.red,
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  HapticFeedback.lightImpact();
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeService.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading analytics...',
                        style: TextStyle(
                          color: themeService.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
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
