import 'package:equatable/equatable.dart';
import '../../../data/repositories/earnings/earnings_repository.dart';
import '../models/earnings_summary_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../models/earnings_analytics_model.dart';

/// Abstract base class for all Earnings states
abstract class EarningsState extends Equatable {
  const EarningsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when earnings is first loaded
class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

/// State when earnings data is being loaded
class EarningsLoading extends EarningsState {
  final bool isInitialLoad;

  const EarningsLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

/// State when earnings data is successfully loaded
class EarningsLoadedState extends EarningsState {
  final EarningsPeriod selectedPeriod;
  final EarningsSummaryModel summary;
  final List<TransactionModel> transactions;
  final EarningsAnalyticsModel analytics;
  final List<WithdrawalModel> withdrawals;
  final String? successMessage;

  EarningsLoadedState({
    required this.selectedPeriod,
    required this.summary,
    required this.transactions,
    required this.analytics,
    required this.withdrawals,
    this.successMessage,
  });

  @override
  List<Object?> get props => [
        selectedPeriod,
        summary,
        transactions,
        analytics,
        withdrawals,
        successMessage,
      ];

  /// Copy with method for easy state updates
  EarningsLoadedState copyWith({
    EarningsPeriod? selectedPeriod,
    EarningsSummaryModel? summary,
    List<TransactionModel>? transactions,
    EarningsAnalyticsModel? analytics,
    List<WithdrawalModel>? withdrawals,
    String? successMessage,
  }) {
    return EarningsLoadedState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      analytics: analytics ?? this.analytics,
      withdrawals: withdrawals ?? this.withdrawals,
      successMessage: successMessage,
    );
  }

  /// Helper: Get credit transactions
  List<TransactionModel> get creditTransactions {
    return transactions.where((t) => t.isCredit).toList();
  }

  /// Helper: Get debit transactions
  List<TransactionModel> get debitTransactions {
    return transactions.where((t) => t.isDebit).toList();
  }

  /// Helper: Get pending withdrawals
  List<WithdrawalModel> get pendingWithdrawals {
    return withdrawals.where((w) => w.isPending).toList();
  }

  /// Helper: Get completed withdrawals
  List<WithdrawalModel> get completedWithdrawals {
    return withdrawals.where((w) => w.isCompleted).toList();
  }

  /// Helper: Check if there are transactions
  bool get hasTransactions => transactions.isNotEmpty;

  /// Helper: Check if there are withdrawals
  bool get hasWithdrawals => withdrawals.isNotEmpty;

  /// Helper: Check if withdrawal can be requested (has available balance)
  bool get canRequestWithdrawal => summary.availableBalance > 0;

  /// Helper: Get period display name
  String get periodDisplayName {
    switch (selectedPeriod) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.thisWeek:
        return 'This Week';
      case EarningsPeriod.thisMonth:
        return 'This Month';
      case EarningsPeriod.thisYear:
        return 'This Year';
      case EarningsPeriod.custom:
        return 'Custom';
    }
  }
}

/// State when there's an error loading earnings data
class EarningsErrorState extends EarningsState {
  final String message;

  const EarningsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when withdrawal is being processed
class WithdrawalProcessing extends EarningsState {
  final String? withdrawalId;

  const WithdrawalProcessing({this.withdrawalId});

  @override
  List<Object?> get props => [withdrawalId];
}

/// State when withdrawal request is successful
class WithdrawalRequestSuccessState extends EarningsState {
  final WithdrawalModel withdrawal;

  const WithdrawalRequestSuccessState(this.withdrawal);

  @override
  List<Object?> get props => [withdrawal];
}

/// State when withdrawal is cancelled
class WithdrawalCancelledState extends EarningsState {
  final String withdrawalId;

  const WithdrawalCancelledState(this.withdrawalId);

  @override
  List<Object?> get props => [withdrawalId];
}


