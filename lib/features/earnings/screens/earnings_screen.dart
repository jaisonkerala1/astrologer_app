import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../widgets/earnings_chart_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header with period selector
              _buildHeader(themeService),
              
              // Earnings Overview
              _buildEarningsOverview(l10n, themeService),
              
              // Tab Bar
              _buildTabBar(l10n, themeService),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(themeService),
                    _buildAnalyticsTab(themeService),
                    _buildWithdrawalsTab(themeService),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
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
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isDense: true,
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                items: ['Today', 'This Week', 'This Month', 'This Year']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview(AppLocalizations l10n, ThemeService themeService) {
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
                const Text(
                  '₹15,247',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+12.5% from last month',
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
                  '₹8,450',
                  Icons.account_balance_wallet,
                  themeService.successColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '₹3,200',
                  Icons.pending,
                  themeService.warningColor,
                  themeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Withdrawn',
                  '₹3,597',
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
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: themeService.borderRadius,
        border: Border.all(color: themeService.borderColor),
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
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l10n.transactions),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l10n.analytics),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l10n.withdrawals),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _mockTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _mockTransactions[index];
        return _buildTransactionTile(transaction, themeService);
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction, ThemeService themeService) {
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
              color: transaction['type'] == 'credit' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction['type'] == 'credit' ? Icons.add : Icons.remove,
              color: transaction['type'] == 'credit' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['date'],
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction['type'] == 'credit' ? '+' : '-'}₹${transaction['amount']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction['type'] == 'credit' ? Colors.green : Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Earnings Trend
          EarningsChartWidget(
            data: _weeklyEarningsData,
            title: 'Weekly Earnings Trend',
            primaryColor: themeService.primaryColor,
            secondaryColor: themeService.accentColor,
          ),
          
          const SizedBox(height: 20),
          
          // Daily Earnings Bar Chart
          EarningsBarChartWidget(
            data: _dailyEarningsData,
            title: 'Daily Earnings (This Week)',
            primaryColor: themeService.successColor,
          ),
          
          const SizedBox(height: 20),
          
          // Performance metrics
          _buildMetricsGrid(themeService),
          
          const SizedBox(height: 20),
          
          // Earnings by Consultation Type
          _buildConsultationTypeAnalysis(themeService),
          
          const SizedBox(height: 20),
          
          // Peak Hours Analysis
          _buildPeakHoursAnalysis(themeService),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeService themeService) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard('Average per Call', '₹287', Icons.phone, themeService.primaryColor, themeService),
        _buildMetricCard('Best Day', '₹1,250', Icons.calendar_today, themeService.successColor, themeService),
        _buildMetricCard('Total Calls', '53', Icons.call_made, themeService.infoColor, themeService),
        _buildMetricCard('Peak Hours', '7-9 PM', Icons.access_time, themeService.accentColor, themeService),
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

  Widget _buildWithdrawalsTab(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Withdraw button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showWithdrawDialog();
              },
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
            child: ListView.builder(
              itemCount: _mockWithdrawals.length,
              itemBuilder: (context, index) {
                final withdrawal = _mockWithdrawals[index];
                return _buildWithdrawalTile(withdrawal, themeService);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalTile(Map<String, dynamic> withdrawal, ThemeService themeService) {
    Color statusColor = withdrawal['status'] == 'completed' 
        ? themeService.successColor 
        : withdrawal['status'] == 'pending'
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
                  '₹${withdrawal['amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  withdrawal['date'],
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
              withdrawal['status'].toUpperCase(),
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

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Available Balance: ₹8,450'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                hintText: 'Enter amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeAnalysis(ThemeService themeService) {
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
          ..._consultationTypeData.map((item) => _buildTypeAnalysisItem(item, themeService)),
        ],
      ),
    );
  }

  Widget _buildTypeAnalysisItem(Map<String, dynamic> item, ThemeService themeService) {
    final percentage = item['percentage'] as double;
    final color = item['color'] as Color;
    
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
              item['type'] as String,
              style: TextStyle(
                fontSize: 14,
                color: themeService.textPrimary,
              ),
            ),
          ),
          Text(
            '₹${(item['amount'] as double).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursAnalysis(ThemeService themeService) {
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
                child: _buildPeakHourItem('Morning', '6 AM - 12 PM', '₹2,450', themeService.warningColor, themeService),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeakHourItem('Afternoon', '12 PM - 6 PM', '₹1,850', themeService.infoColor, themeService),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeakHourItem('Evening', '6 PM - 12 AM', '₹4,200', themeService.successColor, themeService),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPeakHourItem('Night', '12 AM - 6 AM', '₹750', themeService.accentColor, themeService),
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

// Mock data
final List<Map<String, dynamic>> _mockTransactions = [
  {
    'description': 'Consultation with Priya Sharma',
    'amount': '450',
    'date': 'Today, 2:30 PM',
    'type': 'credit',
  },
  {
    'description': 'Consultation with Amit Kumar',
    'amount': '300',
    'date': 'Today, 11:15 AM',
    'type': 'credit',
  },
  {
    'description': 'Platform Fee',
    'amount': '45',
    'date': 'Yesterday, 6:00 PM',
    'type': 'debit',
  },
  {
    'description': 'Consultation with Sunita Gupta',
    'amount': '600',
    'date': 'Yesterday, 4:30 PM',
    'type': 'credit',
  },
  {
    'description': 'Consultation with Vikas Singh',
    'amount': '375',
    'date': '2 days ago, 8:45 PM',
    'type': 'credit',
  },
];

final List<Map<String, dynamic>> _mockWithdrawals = [
  {
    'amount': '5000',
    'date': '15 Sep, 2024',
    'status': 'completed',
  },
  {
    'amount': '3000',
    'date': '10 Sep, 2024',
    'status': 'pending',
  },
  {
    'amount': '2500',
    'date': '5 Sep, 2024',
    'status': 'completed',
  },
];

// Analytics mock data
final List<Map<String, dynamic>> _weeklyEarningsData = [
  {'label': 'Mon', 'value': 1200.0},
  {'label': 'Tue', 'value': 1850.0},
  {'label': 'Wed', 'value': 2100.0},
  {'label': 'Thu', 'value': 1650.0},
  {'label': 'Fri', 'value': 2400.0},
  {'label': 'Sat', 'value': 3200.0},
  {'label': 'Sun', 'value': 2800.0},
];

final List<Map<String, dynamic>> _dailyEarningsData = [
  {'label': 'Mon', 'value': 1200.0},
  {'label': 'Tue', 'value': 1850.0},
  {'label': 'Wed', 'value': 2100.0},
  {'label': 'Thu', 'value': 1650.0},
  {'label': 'Fri', 'value': 2400.0},
  {'label': 'Sat', 'value': 3200.0},
  {'label': 'Sun', 'value': 2800.0},
];

final List<Map<String, dynamic>> _consultationTypeData = [
  {
    'type': 'Phone Calls',
    'amount': 8500.0,
    'percentage': 55.7,
    'color': const Color(0xFF1E40AF), // Primary blue
  },
  {
    'type': 'Video Calls',
    'amount': 4200.0,
    'percentage': 27.5,
    'color': const Color(0xFF3B82F6), // Info blue
  },
  {
    'type': 'In-Person',
    'amount': 1800.0,
    'percentage': 11.8,
    'color': const Color(0xFF10B981), // Success green
  },
  {
    'type': 'Chat',
    'amount': 747.0,
    'percentage': 4.9,
    'color': const Color(0xFFF59E0B), // Warning amber
  },
];
