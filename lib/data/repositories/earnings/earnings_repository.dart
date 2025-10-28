import '../../../features/earnings/models/earnings_summary_model.dart';
import '../../../features/earnings/models/transaction_model.dart';
import '../../../features/earnings/models/withdrawal_model.dart';
import '../../../features/earnings/models/earnings_analytics_model.dart';

/// Period enum for filtering earnings data
enum EarningsPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

/// Abstract interface for Earnings operations
abstract class EarningsRepository {
  // Instant data access (synchronous cache)
  Map<String, dynamic>? getInstantData(EarningsPeriod period);
  
  // Summary
  Future<EarningsSummaryModel> getEarningsSummary(EarningsPeriod period);
  
  // Transactions
  Future<List<TransactionModel>> getTransactions({
    EarningsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  
  // Analytics
  Future<EarningsAnalyticsModel> getEarningsAnalytics(EarningsPeriod period);
  
  // Withdrawals
  Future<List<WithdrawalModel>> getWithdrawals({
    WithdrawalStatus? status,
    int page = 1,
    int limit = 20,
  });
  Future<WithdrawalModel> requestWithdrawal({
    required double amount,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    String? notes,
  });
  Future<WithdrawalModel> cancelWithdrawal(String withdrawalId);
  
  // Cache management
  Future<void> cacheAllEarningsData(Map<String, dynamic> data, EarningsPeriod period);
  Future<void> cacheEarningsSummary(EarningsSummaryModel summary, EarningsPeriod period);
  Future<EarningsSummaryModel?> getCachedEarningsSummary(EarningsPeriod period);
  Future<void> clearCache();
}


