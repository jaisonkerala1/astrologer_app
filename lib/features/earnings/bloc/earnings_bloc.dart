import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/earnings/earnings_repository.dart';
import '../models/earnings_summary_model.dart';
import '../models/transaction_model.dart';
import '../models/earnings_analytics_model.dart';
import '../models/withdrawal_model.dart';
import 'earnings_event.dart';
import 'earnings_state.dart';

/// BLoC for managing earnings, transactions, and withdrawals
/// Follows clean architecture principles with repository pattern
class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  final EarningsRepository repository;

  EarningsBloc({required this.repository}) : super(const EarningsInitial()) {
    on<LoadEarningsSummaryEvent>(_onLoadEarningsSummary);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<RefreshTransactionsEvent>(_onRefreshTransactions);
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
    on<LoadWithdrawalsEvent>(_onLoadWithdrawals);
    on<RequestWithdrawalEvent>(_onRequestWithdrawal);
    on<CancelWithdrawalEvent>(_onCancelWithdrawal);
    on<RefreshEarningsEvent>(_onRefreshEarnings);
    on<ClearEarningsCacheEvent>(_onClearCache);
  }

  // ============================================================================
  // SUMMARY
  // ============================================================================

  Future<void> _onLoadEarningsSummary(
    LoadEarningsSummaryEvent event,
    Emitter<EarningsState> emit,
  ) async {
    // PHASE 1: Check for cached data and emit instantly
    final cachedData = repository.getInstantData(event.period);
    
    if (cachedData != null) {
      try {
        // Parse cached data
        final summary = EarningsSummaryModel.fromJson(cachedData['summary'] as Map<String, dynamic>);
        final transactions = (cachedData['transactions'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final analytics = EarningsAnalyticsModel.fromJson(cachedData['analytics'] as Map<String, dynamic>);
        final withdrawals = (cachedData['withdrawals'] as List)
            .map((e) => WithdrawalModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Emit cached data instantly
        emit(EarningsLoadedState(
          selectedPeriod: event.period,
          summary: summary,
          transactions: transactions,
          analytics: analytics,
          withdrawals: withdrawals,
          isRefreshing: false,
        ));
        print('✅ Earnings: Instant load complete');
      } catch (e) {
        print('Error parsing cached earnings data: $e');
        // If parsing fails, show loading state
        emit(const EarningsLoading());
      }
    } else {
      // No cache, show loading state
      emit(const EarningsLoading());
    }

    // PHASE 2: Fetch fresh data in background
    try {
      // Update to refreshing state if we had cached data
      if (cachedData != null && state is EarningsLoadedState) {
        final currentState = state as EarningsLoadedState;
        emit(currentState.copyWith(isRefreshing: true));
      }

      final summary = await repository.getEarningsSummary(event.period);
      final transactions = await repository.getTransactions(period: event.period);
      final analytics = await repository.getEarningsAnalytics(event.period);
      final withdrawals = await repository.getWithdrawals();

      // Cache the fresh data
      await _cacheEarningsData(summary, transactions, analytics, withdrawals, event.period);

      // Emit fresh data
      emit(EarningsLoadedState(
        selectedPeriod: event.period,
        summary: summary,
        transactions: transactions,
        analytics: analytics,
        withdrawals: withdrawals,
        isRefreshing: false,
      ));
      print('✅ Earnings: Background refresh complete');
    } catch (e) {
      // Only emit error if we don't have cached data showing
      if (state is! EarningsLoadedState) {
        emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
      } else {
        // We have cached data showing, just stop refreshing
        final currentState = state as EarningsLoadedState;
        emit(currentState.copyWith(isRefreshing: false));
        print('⚠️ Earnings: Background refresh failed, showing cached data');
      }
    }
  }

  Future<void> _cacheEarningsData(
    EarningsSummaryModel summary,
    List<TransactionModel> transactions,
    EarningsAnalyticsModel analytics,
    List<WithdrawalModel> withdrawals,
    EarningsPeriod period,
  ) async {
    try {
      final data = {
        'summary': summary.toJson(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'analytics': analytics.toJson(),
        'withdrawals': withdrawals.map((e) => e.toJson()).toList(),
      };
      
      await repository.cacheAllEarningsData(data, period);
    } catch (e) {
      print('Error caching earnings data in bloc: $e');
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<EarningsState> emit,
  ) async {
    // Reload data for new period
    add(LoadEarningsSummaryEvent(event.period));
  }

  // ============================================================================
  // TRANSACTIONS
  // ============================================================================

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const EarningsLoading(isInitialLoad: false));

    try {
      final transactions = await repository.getTransactions(
        period: event.period,
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
      );

      if (state is EarningsLoadedState) {
        final currentState = state as EarningsLoadedState;
        emit(currentState.copyWith(transactions: transactions));
      }
    } catch (e) {
      emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactionsEvent event,
    Emitter<EarningsState> emit,
  ) async {
    if (state is EarningsLoadedState) {
      final currentState = state as EarningsLoadedState;
      add(LoadTransactionsEvent(period: currentState.selectedPeriod));
    }
  }

  // ============================================================================
  // ANALYTICS
  // ============================================================================

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      final analytics = await repository.getEarningsAnalytics(event.period);

      if (state is EarningsLoadedState) {
        final currentState = state as EarningsLoadedState;
        emit(currentState.copyWith(analytics: analytics));
      }
    } catch (e) {
      emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // WITHDRAWALS
  // ============================================================================

  Future<void> _onLoadWithdrawals(
    LoadWithdrawalsEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      final withdrawals = await repository.getWithdrawals(
        status: event.status,
        page: event.page,
      );

      if (state is EarningsLoadedState) {
        final currentState = state as EarningsLoadedState;
        emit(currentState.copyWith(withdrawals: withdrawals));
      }
    } catch (e) {
      emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestWithdrawal(
    RequestWithdrawalEvent event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const WithdrawalProcessing());

    try {
      final withdrawal = await repository.requestWithdrawal(
        amount: event.amount,
        bankAccountNumber: event.bankAccountNumber,
        ifscCode: event.ifscCode,
        upiId: event.upiId,
        notes: event.notes,
      );

      // Emit success state
      emit(WithdrawalRequestSuccessState(withdrawal));

      // Reload earnings data
      if (state is EarningsLoadedState) {
        final currentState = state as EarningsLoadedState;
        add(LoadEarningsSummaryEvent(currentState.selectedPeriod));
      } else {
        add(const LoadEarningsSummaryEvent(EarningsPeriod.thisMonth));
      }
    } catch (e) {
      emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelWithdrawal(
    CancelWithdrawalEvent event,
    Emitter<EarningsState> emit,
  ) async {
    emit(WithdrawalProcessing(withdrawalId: event.withdrawalId));

    try {
      await repository.cancelWithdrawal(event.withdrawalId);

      // Emit cancelled state
      emit(WithdrawalCancelledState(event.withdrawalId));

      // Reload withdrawals
      add(const LoadWithdrawalsEvent());
    } catch (e) {
      emit(EarningsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // REFRESH & CACHE
  // ============================================================================

  Future<void> _onRefreshEarnings(
    RefreshEarningsEvent event,
    Emitter<EarningsState> emit,
  ) async {
    if (state is EarningsLoadedState) {
      final currentState = state as EarningsLoadedState;
      add(LoadEarningsSummaryEvent(currentState.selectedPeriod));
    } else {
      add(const LoadEarningsSummaryEvent(EarningsPeriod.thisMonth));
    }
  }

  Future<void> _onClearCache(
    ClearEarningsCacheEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      await repository.clearCache();
    } catch (e) {
      print('Error clearing earnings cache: $e');
    }
  }
}


