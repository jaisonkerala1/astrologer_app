import 'package:equatable/equatable.dart';
import '../../../data/repositories/earnings/earnings_repository.dart';
import '../models/withdrawal_model.dart';

/// Abstract base class for all Earnings events
abstract class EarningsEvent extends Equatable {
  const EarningsEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// SUMMARY EVENTS
// ============================================================================

/// Event to load earnings summary
class LoadEarningsSummaryEvent extends EarningsEvent {
  final EarningsPeriod period;

  const LoadEarningsSummaryEvent(this.period);

  @override
  List<Object?> get props => [period];
}

/// Event to change period filter
class ChangePeriodEvent extends EarningsEvent {
  final EarningsPeriod period;

  const ChangePeriodEvent(this.period);

  @override
  List<Object?> get props => [period];
}

// ============================================================================
// TRANSACTIONS EVENTS
// ============================================================================

/// Event to load transactions
class LoadTransactionsEvent extends EarningsEvent {
  final EarningsPeriod? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;

  const LoadTransactionsEvent({
    this.period,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  @override
  List<Object?> get props => [period, startDate, endDate, page];
}

/// Event to refresh transactions
class RefreshTransactionsEvent extends EarningsEvent {
  const RefreshTransactionsEvent();
}

// ============================================================================
// ANALYTICS EVENTS
// ============================================================================

/// Event to load earnings analytics
class LoadAnalyticsEvent extends EarningsEvent {
  final EarningsPeriod period;

  const LoadAnalyticsEvent(this.period);

  @override
  List<Object?> get props => [period];
}

// ============================================================================
// WITHDRAWALS EVENTS
// ============================================================================

/// Event to load withdrawals
class LoadWithdrawalsEvent extends EarningsEvent {
  final WithdrawalStatus? status;
  final int page;

  const LoadWithdrawalsEvent({
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [status, page];
}

/// Event to request a withdrawal
class RequestWithdrawalEvent extends EarningsEvent {
  final double amount;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? notes;

  const RequestWithdrawalEvent({
    required this.amount,
    this.bankAccountNumber,
    this.ifscCode,
    this.upiId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        amount,
        bankAccountNumber,
        ifscCode,
        upiId,
        notes,
      ];
}

/// Event to cancel a withdrawal
class CancelWithdrawalEvent extends EarningsEvent {
  final String withdrawalId;

  const CancelWithdrawalEvent(this.withdrawalId);

  @override
  List<Object?> get props => [withdrawalId];
}

// ============================================================================
// REFRESH & CACHE EVENTS
// ============================================================================

/// Event to refresh all earnings data
class RefreshEarningsEvent extends EarningsEvent {
  const RefreshEarningsEvent();
}

/// Event to clear cache
class ClearEarningsCacheEvent extends EarningsEvent {
  const ClearEarningsCacheEvent();
}


