import 'package:equatable/equatable.dart';

/// Model representing earnings summary
class EarningsSummaryModel extends Equatable {
  final double totalEarnings;
  final double availableBalance;
  final double pendingAmount;
  final double withdrawnAmount;
  final double growthPercentage; // Month-over-month growth
  final DateTime lastUpdated;

  const EarningsSummaryModel({
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingAmount,
    required this.withdrawnAmount,
    required this.growthPercentage,
    required this.lastUpdated,
  });

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryModel(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      withdrawnAmount: (json['withdrawnAmount'] ?? 0).toDouble(),
      growthPercentage: (json['growthPercentage'] ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingAmount': pendingAmount,
      'withdrawnAmount': withdrawnAmount,
      'growthPercentage': growthPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  EarningsSummaryModel copyWith({
    double? totalEarnings,
    double? availableBalance,
    double? pendingAmount,
    double? withdrawnAmount,
    double? growthPercentage,
    DateTime? lastUpdated,
  }) {
    return EarningsSummaryModel(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      withdrawnAmount: withdrawnAmount ?? this.withdrawnAmount,
      growthPercentage: growthPercentage ?? this.growthPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get formatted total earnings with currency
  String get formattedTotalEarnings => '₹${totalEarnings.toStringAsFixed(0)}';

  /// Get formatted available balance
  String get formattedAvailableBalance => '₹${availableBalance.toStringAsFixed(0)}';

  /// Get formatted pending amount
  String get formattedPendingAmount => '₹${pendingAmount.toStringAsFixed(0)}';

  /// Get formatted withdrawn amount
  String get formattedWithdrawnAmount => '₹${withdrawnAmount.toStringAsFixed(0)}';

  /// Get formatted growth percentage
  String get formattedGrowthPercentage => '${growthPercentage >= 0 ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%';

  /// Check if growth is positive
  bool get hasPositiveGrowth => growthPercentage > 0;

  @override
  List<Object?> get props => [
        totalEarnings,
        availableBalance,
        pendingAmount,
        withdrawnAmount,
        growthPercentage,
        lastUpdated,
      ];

  /// Empty model factory
  factory EarningsSummaryModel.empty() {
    return EarningsSummaryModel(
      totalEarnings: 0,
      availableBalance: 0,
      pendingAmount: 0,
      withdrawnAmount: 0,
      growthPercentage: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

