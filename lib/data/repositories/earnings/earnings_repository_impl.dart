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

  EarningsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // SUMMARY
  // ============================================================================

  @override
  Future<EarningsSummaryModel> getEarningsSummary(EarningsPeriod period) async {
    try {
      // Try cache first
      final cached = await getCachedEarningsSummary(period);
      if (cached != null) {
        return cached;
      }

      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/earnings/$astrologerId/summary',
        queryParameters: {
          'period': _periodToString(period),
        },
      );

      if (response.data['success'] == true) {
        final summary = EarningsSummaryModel.fromJson(response.data['data']);
        
        // Cache the result
        await cacheEarningsSummary(summary, period);
        
        return summary;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load earnings summary');
      }
    } catch (e) {
      // Fallback to cache on error
      final cached = await getCachedEarningsSummary(period);
      if (cached != null) {
        return cached;
      }
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
    try {
      final astrologerId = await _getAstrologerId();
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (period != null) {
        queryParams['period'] = _periodToString(period);
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await apiService.get(
        '/api/earnings/$astrologerId/transactions',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> transactionsData = response.data['data'] ?? [];
        return transactionsData
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // ANALYTICS
  // ============================================================================

  @override
  Future<EarningsAnalyticsModel> getEarningsAnalytics(EarningsPeriod period) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/earnings/$astrologerId/analytics',
        queryParameters: {
          'period': _periodToString(period),
        },
      );

      if (response.data['success'] == true) {
        return EarningsAnalyticsModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load analytics');
      }
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
    try {
      final astrologerId = await _getAstrologerId();
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) {
        queryParams['status'] = status.name;
      }

      final response = await apiService.get(
        '/api/earnings/$astrologerId/withdrawals',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> withdrawalsData = response.data['data'] ?? [];
        return withdrawalsData
            .map((json) => WithdrawalModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load withdrawals');
      }
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
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/earnings/$astrologerId/withdrawals',
        data: {
          'amount': amount,
          if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
          if (ifscCode != null) 'ifscCode': ifscCode,
          if (upiId != null) 'upiId': upiId,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        return WithdrawalModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to request withdrawal');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<WithdrawalModel> cancelWithdrawal(String withdrawalId) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.patch(
        '/api/earnings/$astrologerId/withdrawals/$withdrawalId/cancel',
      );

      if (response.data['success'] == true) {
        return WithdrawalModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to cancel withdrawal');
      }
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


