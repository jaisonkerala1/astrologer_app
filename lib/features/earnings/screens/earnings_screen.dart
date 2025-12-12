import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/repositories/earnings/earnings_repository.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_state.dart';
import '../widgets/earnings_credit_card_widget.dart';
import '../widgets/earnings_quick_stats_row.dart';
import '../widgets/earnings_transaction_list.dart';
import '../widgets/earnings_withdraw_card.dart';
import '../widgets/earnings_amount_selector.dart';
import '../widgets/earnings_analytics_chart.dart';
import '../bloc/earnings_bloc.dart';
import '../bloc/earnings_event.dart';
import '../bloc/earnings_state.dart';
import '../models/withdrawal_model.dart';
import '../models/earnings_analytics_model.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  double _selectedWithdrawAmount = 0;

  // Mock bank accounts for UI demonstration
  final List<BankAccountInfo> _bankAccounts = const [
    BankAccountInfo(
      id: '1',
      bankName: 'HDFC Bank',
      accountNumber: '50100123456789',
      holderName: 'Guruji Name',
      isPrimary: true,
    ),
    BankAccountInfo(
      id: '2',
      bankName: 'ICICI Bank',
      accountNumber: '12345678901234',
      holderName: 'Guruji Name',
    ),
  ];
  String _selectedBankId = '1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load earnings data using BLoC
    context.read<EarningsBloc>().add(const LoadEarningsSummaryEvent(EarningsPeriod.thisMonth));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode();

    return BlocBuilder<EarningsBloc, EarningsState>(
      builder: (context, state) {
        if (state is EarningsLoading && state.isInitialLoad) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: _buildLoadingState(themeService),
          );
        }

        if (state is EarningsErrorState) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: _buildErrorState(state.message, themeService),
          );
        }

        if (state is EarningsLoadedState) {
          // Initialize withdraw amount if not set
          if (_selectedWithdrawAmount == 0 && state.summary.availableBalance > 0) {
            _selectedWithdrawAmount = state.summary.availableBalance;
          }

          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // App Bar
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        backgroundColor: themeService.backgroundColor,
                        elevation: 0,
                        toolbarHeight: 60,
                        title: Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: themeService.textPrimary,
                          ),
                        ),
                        actions: [
                          // Period selector
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeService.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<EarningsPeriod>(
                                value: state.selectedPeriod,
                                isDense: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: themeService.primaryColor,
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: themeService.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: EarningsPeriod.today,
                                    child: Text('Today'),
                                  ),
                                  DropdownMenuItem(
                                    value: EarningsPeriod.thisWeek,
                                    child: Text('This Week'),
                                  ),
                                  DropdownMenuItem(
                                    value: EarningsPeriod.thisMonth,
                                    child: Text('This Month'),
                                  ),
                                  DropdownMenuItem(
                                    value: EarningsPeriod.thisYear,
                                    child: Text('This Year'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    HapticFeedback.selectionClick();
                                    context.read<EarningsBloc>().add(ChangePeriodEvent(value));
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Hero Credit Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: BlocBuilder<ProfileBloc, ProfileState>(
                            builder: (context, profileState) {
                              String? profileName;
                              String? profileImageUrl;
                              
                              if (profileState is ProfileLoadedState) {
                                profileName = profileState.astrologer.name;
                                profileImageUrl = profileState.astrologer.profilePicture;
                              }
                              
                              return EarningsCreditCardWidget(
                                totalEarnings: state.summary.totalEarnings,
                                availableBalance: state.summary.availableBalance,
                                pendingAmount: state.summary.pendingAmount,
                                growthPercentage: state.summary.growthPercentage,
                                periodLabel: state.periodDisplayName,
                                weeklyData: state.analytics.weeklyTrend
                                    .map((e) => e.value)
                                    .toList(),
                                profileName: profileName,
                                profileImageUrl: profileImageUrl,
                              );
                            },
                          ),
                        ),
                      ),

                      // Quick Stats Row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: EarningsQuickStatsRow(
                            title: 'Earnings by Source',
                            items: _getQuickStatsItems(state.analytics),
                          ),
                        ),
                      ),

                      // Tab Bar
                      SliverToBoxAdapter(
                        child: _buildTabBar(l10n, themeService),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsTab(themeService, state),
                      _buildAnalyticsTab(themeService, state),
                      _buildWithdrawalsTab(themeService, state),
                    ],
                  ),
                ),

                // Subtle refresh indicator at top
                if (state.isRefreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: _buildLoadingState(themeService),
        );
      },
    );
  }

  List<QuickStatItem> _getQuickStatsItems(EarningsAnalyticsModel analytics) {
    if (analytics.earningsByType.isEmpty) {
      // Return mock data if no data available
      return [
        QuickStatItem(
          label: 'Voice Calls',
          amount: 8450,
          icon: Icons.phone_rounded,
          color: AppTheme.successColor,
        ),
        QuickStatItem(
          label: 'Video Calls',
          amount: 4320,
          icon: Icons.videocam_rounded,
          color: AppTheme.infoColor,
        ),
        QuickStatItem(
          label: 'Chat',
          amount: 2100,
          icon: Icons.chat_bubble_rounded,
          color: AppTheme.warningColor,
        ),
        QuickStatItem(
          label: 'Pooja',
          amount: 1500,
          icon: Icons.self_improvement_rounded,
          color: AppTheme.primaryColor,
        ),
      ];
    }

    return analytics.earningsByType.map((type) {
      IconData icon;
      Color color;
      
      switch (type.type.toLowerCase()) {
        case 'voice':
        case 'call':
          icon = Icons.phone_rounded;
          color = AppTheme.successColor;
          break;
        case 'video':
          icon = Icons.videocam_rounded;
          color = AppTheme.infoColor;
          break;
        case 'chat':
          icon = Icons.chat_bubble_rounded;
          color = AppTheme.warningColor;
          break;
        case 'pooja':
        case 'puja':
          icon = Icons.self_improvement_rounded;
          color = AppTheme.primaryColor;
          break;
        default:
          icon = Icons.monetization_on_rounded;
          color = AppTheme.successColor;
      }

      return QuickStatItem(
        label: type.type,
        amount: type.amount,
        icon: icon,
        color: color,
      );
    }).toList();
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Header skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLoader(width: 100, height: 32),
                SkeletonLoader(
                  width: 100,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Credit card skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          // Quick stats skeleton
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SkeletonLoader(
                    width: 100,
                    height: 110,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: themeService.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: themeService.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading earnings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<EarningsBloc>().add(const RefreshEarningsEvent());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeService.primaryColor, themeService.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode()
            ? const Color(0xFF1E1E2E)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: themeService.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeService.primaryColor, themeService.accentColor],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeService.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(12),
        onTap: (index) => HapticFeedback.selectionClick(),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l10n.transactions),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l10n.analytics),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 16),
                const SizedBox(width: 6),
                Text(l10n.withdrawals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeService themeService, EarningsLoadedState state) {
    return EarningsTransactionList(
      transactions: state.transactions,
      isLoading: false,
    );
  }

  Widget _buildAnalyticsTab(ThemeService themeService, EarningsLoadedState state) {
    final analytics = state.analytics;
    final isDark = themeService.isDarkMode();

    // Generate mock sparkline data for metric cards
    final avgCallSparkline = List.generate(7, (i) => 200 + (i * 15.0) + (i % 2 == 0 ? 30 : -20));
    final bestDaySparkline = List.generate(7, (i) => 500 + (i * 50.0) + (i % 3 == 0 ? 100 : -50));
    final totalCallsSparkline = List.generate(7, (i) => 10.0 + i + (i % 2 == 0 ? 3 : -2));
    final peakHoursSparkline = List.generate(7, (i) => 8.0 + (i * 0.5) + (i % 2 == 0 ? 1 : -0.5));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creative Performance Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              CreativeMetricCard(
                label: 'Avg / Call',
                value: '₹${analytics.averagePerCall.toStringAsFixed(0)}',
                icon: Icons.phone_in_talk_rounded,
                color: AppTheme.successColor,
                sparklineData: avgCallSparkline,
                showTrend: true,
                trendValue: 12.5,
              ),
              CreativeMetricCard(
                label: 'Best Day',
                value: '₹${analytics.bestDayEarnings.toStringAsFixed(0)}',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.warningColor,
                sparklineData: bestDaySparkline,
                showTrend: true,
                trendValue: 8.3,
              ),
              CreativeMetricCard(
                label: 'Total Calls',
                value: '${analytics.totalCalls}',
                icon: Icons.call_made_rounded,
                color: AppTheme.infoColor,
                sparklineData: totalCallsSparkline,
                showTrend: true,
                trendValue: 15.0,
              ),
              CreativeMetricCard(
                label: 'Peak Hours',
                value: analytics.peakHours.isNotEmpty ? analytics.peakHours : '8-10 PM',
                icon: Icons.schedule_rounded,
                color: AppTheme.primaryColor,
                sparklineData: peakHoursSparkline,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Earnings Trend Chart
          EarningsAnalyticsChart(
            data: analytics.weeklyTrend.isNotEmpty
                ? analytics.weeklyTrend
                : _getMockWeeklyData(),
            title: 'Earnings Trend',
            subtitle: 'Last 7 days',
            lineColor: AppTheme.successColor,
            fillColor: AppTheme.successColor,
            height: 180,
          ),
          const SizedBox(height: 20),

          // Daily Activity Chart
          EarningsAnalyticsChart(
            data: analytics.dailyTrend.isNotEmpty
                ? analytics.dailyTrend
                : _getMockDailyData(),
            title: 'Daily Activity',
            subtitle: 'Today\'s hourly breakdown',
            lineColor: AppTheme.infoColor,
            fillColor: AppTheme.infoColor,
            height: 160,
          ),
          const SizedBox(height: 20),

          // Earnings by Type with Donut Chart
          _buildEarningsByTypeCard(themeService, analytics),
          const SizedBox(height: 20),

          // Peak Hours
          _buildPeakHoursCard(themeService, analytics),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<ChartDataPoint> _getMockWeeklyData() {
    return const [
      ChartDataPoint(label: 'Mon', value: 1250),
      ChartDataPoint(label: 'Tue', value: 1800),
      ChartDataPoint(label: 'Wed', value: 1450),
      ChartDataPoint(label: 'Thu', value: 2200),
      ChartDataPoint(label: 'Fri', value: 1900),
      ChartDataPoint(label: 'Sat', value: 2500),
      ChartDataPoint(label: 'Sun', value: 2100),
    ];
  }

  List<ChartDataPoint> _getMockDailyData() {
    return const [
      ChartDataPoint(label: '6AM', value: 150),
      ChartDataPoint(label: '9AM', value: 320),
      ChartDataPoint(label: '12PM', value: 480),
      ChartDataPoint(label: '3PM', value: 350),
      ChartDataPoint(label: '6PM', value: 520),
      ChartDataPoint(label: '9PM', value: 680),
    ];
  }

  Widget _buildEarningsByTypeCard(ThemeService themeService, EarningsAnalyticsModel analytics) {
    final isDark = themeService.isDarkMode();
    final types = analytics.earningsByType.isNotEmpty
        ? analytics.earningsByType
        : [
            const ConsultationTypeEarning(type: 'Voice Calls', amount: 12500, percentage: 50),
            const ConsultationTypeEarning(type: 'Video Calls', amount: 8000, percentage: 32),
            const ConsultationTypeEarning(type: 'Chat', amount: 3000, percentage: 12),
            const ConsultationTypeEarning(type: 'Pooja', amount: 1500, percentage: 6),
          ];

    final colors = [
      AppTheme.successColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
      AppTheme.primaryColor,
    ];

    // Calculate total earnings
    final totalAmount = types.fold<double>(0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings by Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '₹${_formatEarningsAmount(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Donut chart + Legend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Chart
              Stack(
                alignment: Alignment.center,
                children: [
                  EarningsDonutChart(
                    data: types,
                    size: 130,
                  ),
                  // Center text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${types.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'Sources',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Legend
              Expanded(
                child: Column(
                  children: types.asMap().entries.map((entry) {
                    final index = entry.key;
                    final type = entry.value;
                    final color = colors[index % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          // Color dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Type name
                          Expanded(
                            child: Text(
                              type.type,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Percentage
                          Text(
                            '${type.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEarningsAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildPeakHoursCard(ThemeService themeService, EarningsAnalyticsModel analytics) {
    final isDark = themeService.isDarkMode();
    final peakHours = analytics.peakHoursAnalysis;

    final periods = [
      (peakHours.morning, 'Morning', Icons.wb_sunny_rounded, AppTheme.warningColor),
      (peakHours.afternoon, 'Afternoon', Icons.wb_twilight_rounded, AppTheme.infoColor),
      (peakHours.evening, 'Evening', Icons.nights_stay_rounded, AppTheme.successColor),
      (peakHours.night, 'Night', Icons.dark_mode_rounded, AppTheme.primaryColor),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: periods.map((p) {
              final (period, label, icon, color) = p;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                          Text(
                            '₹${period.earnings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTab(ThemeService themeService, EarningsLoadedState state) {
    final isDark = themeService.isDarkMode();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Bank Card (Hero)
          EarningsWithdrawCard(
            bankAccount: _bankAccounts.firstWhere((b) => b.id == _selectedBankId),
            isSelected: true,
          ),

          const SizedBox(height: 16),

          // Other bank accounts
          if (_bankAccounts.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Other Accounts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _bankAccounts
                    .where((b) => b.id != _selectedBankId)
                    .map((bank) => EarningsWithdrawCardCompact(
                          bankAccount: bank,
                          isSelected: false,
                          onTap: () {
                            setState(() => _selectedBankId = bank.id);
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Amount Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EarningsAmountSelector(
              availableBalance: state.summary.availableBalance,
              selectedAmount: _selectedWithdrawAmount,
              onAmountChanged: (amount) {
                setState(() => _selectedWithdrawAmount = amount);
              },
              onWithdraw: () => _showWithdrawConfirmation(state),
            ),
          ),

          const SizedBox(height: 24),

          // Withdrawal History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Withdrawals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textColor,
                  ),
                ),
                if (state.withdrawals.isNotEmpty)
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Withdrawal list
          if (state.withdrawals.isEmpty)
            _buildEmptyWithdrawals(isDark)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: state.withdrawals.take(5).map((withdrawal) {
                  return _buildWithdrawalTile(withdrawal, themeService);
                }).toList(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyWithdrawals(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No withdrawals yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your withdrawal history will appear here',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalTile(WithdrawalModel withdrawal, ThemeService themeService) {
    final isDark = themeService.isDarkMode();
    Color statusColor = withdrawal.isCompleted
        ? AppTheme.successColor
        : withdrawal.isPending
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  withdrawal.formattedAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  withdrawal.formattedRequestDate,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              withdrawal.statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawConfirmation(EarningsLoadedState state) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode();
    final selectedBank = _bankAccounts.firstWhere((b) => b.id == _selectedBankId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Confirm Withdrawal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              Text(
                '₹${_selectedWithdrawAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: themeService.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'to ${selectedBank.bankName}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              Text(
                selectedBank.maskedAccountNumber,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.infoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Amount will be credited within 2-3 business days',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<EarningsBloc>().add(
                              RequestWithdrawalEvent(amount: _selectedWithdrawAmount),
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Withdrawal request submitted!'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeService.primaryColor,
                              themeService.accentColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm Withdrawal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}
