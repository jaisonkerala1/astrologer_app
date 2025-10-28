import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/earnings/models/earnings_summary_model.dart';
import '../../../features/earnings/models/transaction_model.dart';
import '../../../features/earnings/models/withdrawal_model.dart';
import '../../../features/earnings/models/earnings_analytics_model.dart';
import '../base_repository.dart';
import 'earnings_repository.dart';

/// Implementation of EarningsRepository
/// Handles earnings, transactions, and withdrawal data operations
class EarningsRepositoryImpl extends BaseRepository implements EarningsRepository {
  final ApiService apiService;
  final StorageService storageService;

  // In-memory cache for instant loading
  Map<String, dynamic>? _cachedData;
  EarningsPeriod? _cachedPeriod;

  EarningsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // INSTANT DATA (Synchronous Cache Access)
  // ============================================================================

  @override
  Map<String, dynamic>? getInstantData(EarningsPeriod period) {
    try {
      // 1. Check in-memory cache first
      if (_cachedData != null && _cachedPeriod == period) {
        print('📊 Earnings: Instant data from memory cache');
        return _cachedData;
      }

      // 2. Try to read from SharedPreferences synchronously
      final key = 'earnings_data_${period.name}';
      final jsonString = storageService.getStringSync(key);
      
      if (jsonString != null) {
        print('📊 Earnings: Instant data from persistent cache');
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _cachedData = data;
        _cachedPeriod = period;
        return data;
      }

      // 3. Return null if no cache available
      print('📊 Earnings: No instant data available');
      return null;
    } catch (e) {
      print('Error getting instant earnings data: $e');
      return null;
    }
  }

  @override
  Future<void> cacheAllEarningsData(Map<String, dynamic> data, EarningsPeriod period) async {
    try {
      // Update in-memory cache
      _cachedData = data;
      _cachedPeriod = period;

      // Save to persistent storage
      final key = 'earnings_data_${period.name}';
      await storageService.setString(key, jsonEncode(data));
      print('💾 Earnings data cached for period: ${period.name}');
    } catch (e) {
      print('Error caching earnings data: $e');
    }
  }

  // ============================================================================
  // SUMMARY
  // ============================================================================

  @override
  Future<EarningsSummaryModel> getEarningsSummary(EarningsPeriod period) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getDummyEarningsSummary(period);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // TRANSACTIONS
  // ============================================================================

  @override
  Future<List<TransactionModel>> getTransactions({
    EarningsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _getDummyTransactions();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // ANALYTICS
  // ============================================================================

  @override
  Future<EarningsAnalyticsModel> getEarningsAnalytics(EarningsPeriod period) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _getDummyAnalytics();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // WITHDRAWALS
  // ============================================================================

  @override
  Future<List<WithdrawalModel>> getWithdrawals({
    WithdrawalStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _getDummyWithdrawals();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<WithdrawalModel> requestWithdrawal({
    required double amount,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    String? notes,
  }) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Mock successful withdrawal request
      return WithdrawalModel(
        id: 'WD${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        status: WithdrawalStatus.pending,
        requestedAt: DateTime.now(),
        bankAccountNumber: bankAccountNumber,
        ifscCode: ifscCode,
        upiId: upiId,
        notes: notes,
      );
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<WithdrawalModel> cancelWithdrawal(String withdrawalId) async {
    // TODO: Replace with real API call when backend is ready
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      // Mock cancelled withdrawal
      final withdrawals = _getDummyWithdrawals();
      final withdrawal = withdrawals.firstWhere((w) => w.id == withdrawalId);
      return withdrawal.copyWith(status: WithdrawalStatus.cancelled);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  @override
  Future<void> cacheEarningsSummary(
    EarningsSummaryModel summary,
    EarningsPeriod period,
  ) async {
    try {
      final key = 'earnings_summary_${period.name}';
      await storageService.setString(key, jsonEncode(summary.toJson()));
      await storageService.setString(
        '${key}_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error caching earnings summary: $e');
    }
  }

  @override
  Future<EarningsSummaryModel?> getCachedEarningsSummary(EarningsPeriod period) async {
    try {
      final key = 'earnings_summary_${period.name}';
      final jsonString = await storageService.getString(key);
      final timestamp = await storageService.getString('${key}_timestamp');

      if (jsonString != null && timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        // Cache valid for 5 minutes
        if (DateTime.now().difference(cacheTime).inMinutes < 5) {
          return EarningsSummaryModel.fromJson(jsonDecode(jsonString));
        }
      }
      return null;
    } catch (e) {
      print('Error getting cached earnings summary: $e');
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      for (final period in EarningsPeriod.values) {
        final key = 'earnings_summary_${period.name}';
        await storageService.remove(key);
        await storageService.remove('${key}_timestamp');
      }
    } catch (e) {
      print('Error clearing earnings cache: $e');
    }
  }

  // ============================================================================
  // DUMMY DATA (Remove when backend is connected)
  // ============================================================================

  EarningsSummaryModel _getDummyEarningsSummary(EarningsPeriod period) {
    return EarningsSummaryModel(
      totalEarnings: 15247,
      availableBalance: 8450,
      pendingAmount: 3200,
      withdrawnAmount: 3597,
      growthPercentage: 12.5,
      lastUpdated: DateTime.now(),
    );
  }

  List<TransactionModel> _getDummyTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'TXN1',
        description: 'Consultation with Priya Sharma',
        amount: 450,
        type: TransactionType.credit,
        date: now,
      ),
      TransactionModel(
        id: 'TXN2',
        description: 'Consultation with Amit Kumar',
        amount: 300,
        type: TransactionType.credit,
        date: now.subtract(const Duration(hours: 3)),
      ),
      TransactionModel(
        id: 'TXN3',
        description: 'Platform Fee',
        amount: 45,
        type: TransactionType.debit,
        date: now.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'TXN4',
        description: 'Consultation with Sunita Gupta',
        amount: 600,
        type: TransactionType.credit,
        date: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      TransactionModel(
        id: 'TXN5',
        description: 'Consultation with Vikas Singh',
        amount: 375,
        type: TransactionType.credit,
        date: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  EarningsAnalyticsModel _getDummyAnalytics() {
    return EarningsAnalyticsModel(
      averagePerCall: 287,
      bestDayEarnings: 1250,
      totalCalls: 53,
      peakHours: '7-9 PM',
      weeklyTrend: const [
        ChartDataPoint(label: 'Mon', value: 1200),
        ChartDataPoint(label: 'Tue', value: 1850),
        ChartDataPoint(label: 'Wed', value: 2100),
        ChartDataPoint(label: 'Thu', value: 1650),
        ChartDataPoint(label: 'Fri', value: 2400),
        ChartDataPoint(label: 'Sat', value: 3200),
        ChartDataPoint(label: 'Sun', value: 2800),
      ],
      dailyTrend: const [
        ChartDataPoint(label: 'Mon', value: 1200),
        ChartDataPoint(label: 'Tue', value: 1850),
        ChartDataPoint(label: 'Wed', value: 2100),
        ChartDataPoint(label: 'Thu', value: 1650),
        ChartDataPoint(label: 'Fri', value: 2400),
        ChartDataPoint(label: 'Sat', value: 3200),
        ChartDataPoint(label: 'Sun', value: 2800),
      ],
      earningsByType: const [
        ConsultationTypeEarning(
          type: 'Phone Calls',
          amount: 8500,
          percentage: 55.7,
        ),
        ConsultationTypeEarning(
          type: 'Video Calls',
          amount: 4200,
          percentage: 27.5,
        ),
        ConsultationTypeEarning(
          type: 'In-Person',
          amount: 1800,
          percentage: 11.8,
        ),
        ConsultationTypeEarning(
          type: 'Chat',
          amount: 747,
          percentage: 4.9,
        ),
      ],
      peakHoursAnalysis: const PeakHoursAnalysis(
        morning: PeakHourPeriod(
          period: 'Morning',
          timeRange: '6 AM - 12 PM',
          earnings: 2450,
        ),
        afternoon: PeakHourPeriod(
          period: 'Afternoon',
          timeRange: '12 PM - 6 PM',
          earnings: 1850,
        ),
        evening: PeakHourPeriod(
          period: 'Evening',
          timeRange: '6 PM - 12 AM',
          earnings: 4200,
        ),
        night: PeakHourPeriod(
          period: 'Night',
          timeRange: '12 AM - 6 AM',
          earnings: 750,
        ),
      ),
    );
  }

  List<WithdrawalModel> _getDummyWithdrawals() {
    final now = DateTime.now();
    return [
      WithdrawalModel(
        id: 'WD1',
        amount: 5000,
        status: WithdrawalStatus.completed,
        requestedAt: now.subtract(const Duration(days: 12)),
        processedAt: now.subtract(const Duration(days: 11)),
        completedAt: now.subtract(const Duration(days: 10)),
      ),
      WithdrawalModel(
        id: 'WD2',
        amount: 3000,
        status: WithdrawalStatus.pending,
        requestedAt: now.subtract(const Duration(days: 5)),
      ),
      WithdrawalModel(
        id: 'WD3',
        amount: 2500,
        status: WithdrawalStatus.completed,
        requestedAt: now.subtract(const Duration(days: 22)),
        processedAt: now.subtract(const Duration(days: 21)),
        completedAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<String> _getAstrologerId() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('Astrologer ID not found');
  }

  String _periodToString(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return 'today';
      case EarningsPeriod.thisWeek:
        return 'week';
      case EarningsPeriod.thisMonth:
        return 'month';
      case EarningsPeriod.thisYear:
        return 'year';
      case EarningsPeriod.custom:
        return 'custom';
    }
  }
}


