import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/repositories/earnings/earnings_repository.dart';
import '../widgets/earnings_chart_widget.dart';
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

class _EarningsScreenState extends State<EarningsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load earnings data using BLoC
    context.read<EarningsBloc>().add(const LoadEarningsSummaryEvent(EarningsPeriod.thisMonth));
  }

  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    
    return BlocBuilder<EarningsBloc, EarningsState>(
      builder: (context, state) {
        // Loading state
        if (state is EarningsLoading && state.isInitialLoad) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: _buildLoadingState(themeService),
          );
        }

        // Error state
        if (state is EarningsErrorState) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: _buildErrorState(state.message, themeService),
          );
        }

        // Loaded state
        if (state is EarningsLoadedState) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            body: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header with period selector
                    _buildHeader(themeService, state),
                
                // Earnings Overview
                _buildEarningsOverview(l10n, themeService, state),
                
                // Tab Bar
                _buildTabBar(l10n, themeService),
                
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTransactionsTab(themeService, state),
                          _buildAnalyticsTab(themeService, state),
                          _buildWithdrawalsTab(themeService, state),
                        ],
                      ),
                    ),
                  ],
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

        // Initial state
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: _buildLoadingState(themeService),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 120, height: 28),
              SkeletonLoader(
                width: 150,
                height: 40,
                borderRadius: themeService.borderRadius,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
          child: SkeletonLoader(
            width: double.infinity,
            height: 150,
            borderRadius: themeService.borderRadius,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
          child: Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: themeService.borderRadius,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: themeService.borderRadius,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: themeService.borderRadius,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeService.errorColor,
            ),
            const SizedBox(height: 16),
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
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<EarningsBloc>().add(const RefreshEarningsEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService, EarningsLoadedState state) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Earnings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: themeService.borderRadius,
              border: Border.all(color: themeService.primaryColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EarningsPeriod>(
                value: state.selectedPeriod,
                isDense: true,
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w500,
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
                    context.read<EarningsBloc>().add(ChangePeriodEvent(value));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview(AppLocalizations l10n, ThemeService themeService, EarningsLoadedState state) {
    final summary = state.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        children: [
          // Main earnings card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeService.primaryColor, themeService.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: themeService.borderRadius,
            ),
            child: Column(
              children: [
                Text(
                  l10n.totalEarnings,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.formattedTotalEarnings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      summary.hasPositiveGrowth ? Icons.trending_up : Icons.trending_down,
                      color: summary.hasPositiveGrowth ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.formattedGrowthPercentage} from last month',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available',
                  summary.formattedAvailableBalance,
                  Icons.account_balance_wallet,
                  themeService.successColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  summary.formattedPendingAmount,
                  Icons.pending,
                  themeService.warningColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Withdrawn',
                  summary.formattedWithdrawnAmount,
                  Icons.arrow_upward,
                  themeService.infoColor,
                  themeService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, IconData icon, Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 16, left: AppConstants.defaultPadding, right: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: themeService.borderRadius,
        border: Border.all(color: themeService.borderColor.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: themeService.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicator: BoxDecoration(
          color: themeService.primaryColor,
          borderRadius: themeService.borderRadius,
          boxShadow: [
            BoxShadow(
              color: themeService.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(6),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(l10n.transactions),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(l10n.analytics),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(l10n.withdrawals),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeService themeService, EarningsLoadedState state) {
    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: themeService.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(color: themeService.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: AppConstants.defaultPadding, right: AppConstants.defaultPadding, bottom: AppConstants.defaultPadding),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final transaction = state.transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            boxShadow: [themeService.cardShadow],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transaction.isCredit 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.isCredit ? Icons.add : Icons.remove,
                  color: transaction.isCredit ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: themeService.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.formattedDate,
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.isCredit ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(ThemeService themeService, EarningsLoadedState state) {
    final analytics = state.analytics;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppConstants.defaultPadding, right: AppConstants.defaultPadding, bottom: AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Earnings Trend
          EarningsChartWidget(
            data: analytics.weeklyTrend.map((point) => {'label': point.label, 'value': point.value}).toList(),
            title: 'Weekly Earnings Trend',
            primaryColor: themeService.primaryColor,
            secondaryColor: themeService.accentColor,
          ),
          
          const SizedBox(height: 20),
          
          // Daily Earnings Bar Chart
          EarningsBarChartWidget(
            data: analytics.dailyTrend.map((point) => {'label': point.label, 'value': point.value}).toList(),
            title: 'Daily Earnings (This Week)',
            primaryColor: themeService.successColor,
          ),
          
          const SizedBox(height: 20),
          
          // Performance metrics
          _buildMetricsGrid(themeService, analytics),
          
          const SizedBox(height: 20),
          
          // Earnings by Consultation Type
          _buildConsultationTypeAnalysis(themeService, analytics),
          
          const SizedBox(height: 20),
          
          // Peak Hours Analysis
          _buildPeakHoursAnalysis(themeService, analytics),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeService themeService, EarningsAnalyticsModel analytics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard('Average per Call', '₹${analytics.averagePerCall.toStringAsFixed(0)}', Icons.phone, themeService.primaryColor, themeService),
        _buildMetricCard('Best Day', '₹${analytics.bestDayEarnings.toStringAsFixed(0)}', Icons.calendar_today, themeService.successColor, themeService),
        _buildMetricCard('Total Calls', '${analytics.totalCalls}', Icons.call_made, themeService.infoColor, themeService),
        _buildMetricCard('Peak Hours', analytics.peakHours, Icons.access_time, themeService.accentColor, themeService),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTab(ThemeService themeService, EarningsLoadedState state) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.defaultPadding, right: AppConstants.defaultPadding, bottom: AppConstants.defaultPadding),
      child: Column(
        children: [
          // Withdraw button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.canRequestWithdrawal ? () {
                _showWithdrawDialog(state);
              } : null,
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Request Withdrawal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: themeService.borderRadius,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Withdrawal history
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Withdrawal History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeService.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: state.withdrawals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, size: 64, color: themeService.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No withdrawals yet',
                        style: TextStyle(color: themeService.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.withdrawals.length,
                  itemBuilder: (context, index) {
                    final withdrawal = state.withdrawals[index];
                    return _buildWithdrawalTile(withdrawal, themeService);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalTile(WithdrawalModel withdrawal, ThemeService themeService) {
    Color statusColor = withdrawal.isCompleted
        ? themeService.successColor
        : withdrawal.isPending
            ? themeService.warningColor
            : themeService.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_upward, color: statusColor),
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
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  withdrawal.formattedRequestDate,
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              withdrawal.statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(EarningsLoadedState state) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Request Withdrawal',
          style: TextStyle(
            color: themeService.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available Balance: ${state.summary.formattedAvailableBalance}',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              style: TextStyle(color: themeService.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                labelStyle: TextStyle(color: themeService.textSecondary),
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: themeService.textHint),
                prefixText: '₹',
                prefixStyle: TextStyle(color: themeService.textPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: themeService.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: themeService.primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: themeService.borderColor),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: themeService.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          Container(
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && amount <= state.summary.availableBalance) {
                    // Dispatch withdrawal request event
                    context.read<EarningsBloc>().add(RequestWithdrawalEvent(amount: amount));
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Withdrawal request submitted successfully'),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a valid amount (max ${state.summary.formattedAvailableBalance})'),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeAnalysis(ThemeService themeService, EarningsAnalyticsModel analytics) {
    final colors = [
      const Color(0xFF1E40AF), // Primary blue
      const Color(0xFF3B82F6), // Info blue
      const Color(0xFF10B981), // Success green
      const Color(0xFFF59E0B), // Warning amber
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings by Consultation Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.earningsByType.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = colors[index % colors.length];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${item.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeakHoursAnalysis(ThemeService themeService, EarningsAnalyticsModel analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Hours Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPeakHourItem(
                  analytics.peakHoursAnalysis.morning.period, 
                  analytics.peakHoursAnalysis.morning.timeRange, 
                  '₹${analytics.peakHoursAnalysis.morning.earnings.toStringAsFixed(0)}', 
                  themeService.warningColor, 
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeakHourItem(
                  analytics.peakHoursAnalysis.afternoon.period, 
                  analytics.peakHoursAnalysis.afternoon.timeRange, 
                  '₹${analytics.peakHoursAnalysis.afternoon.earnings.toStringAsFixed(0)}', 
                  themeService.infoColor, 
                  themeService,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeakHourItem(
                  analytics.peakHoursAnalysis.evening.period, 
                  analytics.peakHoursAnalysis.evening.timeRange, 
                  '₹${analytics.peakHoursAnalysis.evening.earnings.toStringAsFixed(0)}', 
                  themeService.successColor, 
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeakHourItem(
                  analytics.peakHoursAnalysis.night.period, 
                  analytics.peakHoursAnalysis.night.timeRange, 
                  '₹${analytics.peakHoursAnalysis.night.earnings.toStringAsFixed(0)}', 
                  themeService.accentColor, 
                  themeService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHourItem(String period, String time, String amount, Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: themeService.borderRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
