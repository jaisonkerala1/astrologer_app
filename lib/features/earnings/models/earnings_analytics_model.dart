import 'package:equatable/equatable.dart';

/// Model for earnings analytics data
class EarningsAnalyticsModel extends Equatable {
  final double averagePerCall;
  final double bestDayEarnings;
  final int totalCalls;
  final String peakHours;
  final List<ChartDataPoint> weeklyTrend;
  final List<ChartDataPoint> dailyTrend;
  final List<ConsultationTypeEarning> earningsByType;
  final PeakHoursAnalysis peakHoursAnalysis;

  const EarningsAnalyticsModel({
    required this.averagePerCall,
    required this.bestDayEarnings,
    required this.totalCalls,
    required this.peakHours,
    required this.weeklyTrend,
    required this.dailyTrend,
    required this.earningsByType,
    required this.peakHoursAnalysis,
  });

  factory EarningsAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return EarningsAnalyticsModel(
      averagePerCall: (json['averagePerCall'] ?? 0).toDouble(),
      bestDayEarnings: (json['bestDayEarnings'] ?? 0).toDouble(),
      totalCalls: json['totalCalls'] ?? 0,
      peakHours: json['peakHours'] ?? '',
      weeklyTrend: (json['weeklyTrend'] as List<dynamic>?)
              ?.map((e) => ChartDataPoint.fromJson(e))
              .toList() ??
          [],
      dailyTrend: (json['dailyTrend'] as List<dynamic>?)
              ?.map((e) => ChartDataPoint.fromJson(e))
              .toList() ??
          [],
      earningsByType: (json['earningsByType'] as List<dynamic>?)
              ?.map((e) => ConsultationTypeEarning.fromJson(e))
              .toList() ??
          [],
      peakHoursAnalysis: json['peakHoursAnalysis'] != null
          ? PeakHoursAnalysis.fromJson(json['peakHoursAnalysis'])
          : PeakHoursAnalysis.empty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePerCall': averagePerCall,
      'bestDayEarnings': bestDayEarnings,
      'totalCalls': totalCalls,
      'peakHours': peakHours,
      'weeklyTrend': weeklyTrend.map((e) => e.toJson()).toList(),
      'dailyTrend': dailyTrend.map((e) => e.toJson()).toList(),
      'earningsByType': earningsByType.map((e) => e.toJson()).toList(),
      'peakHoursAnalysis': peakHoursAnalysis.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        averagePerCall,
        bestDayEarnings,
        totalCalls,
        peakHours,
        weeklyTrend,
        dailyTrend,
        earningsByType,
        peakHoursAnalysis,
      ];

  /// Empty analytics model
  static const empty = EarningsAnalyticsModel(
    averagePerCall: 0,
    bestDayEarnings: 0,
    totalCalls: 0,
    peakHours: '',
    weeklyTrend: [],
    dailyTrend: [],
    earningsByType: [],
    peakHoursAnalysis: PeakHoursAnalysis.empty,
  );
}

/// Chart data point for trends
class ChartDataPoint extends Equatable {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [label, value];
}

/// Earnings by consultation type
class ConsultationTypeEarning extends Equatable {
  final String type;
  final double amount;
  final double percentage;

  const ConsultationTypeEarning({
    required this.type,
    required this.amount,
    required this.percentage,
  });

  factory ConsultationTypeEarning.fromJson(Map<String, dynamic> json) {
    return ConsultationTypeEarning(
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'percentage': percentage,
    };
  }

  @override
  List<Object?> get props => [type, amount, percentage];
}

/// Peak hours analysis data
class PeakHoursAnalysis extends Equatable {
  final PeakHourPeriod morning;
  final PeakHourPeriod afternoon;
  final PeakHourPeriod evening;
  final PeakHourPeriod night;

  const PeakHoursAnalysis({
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
  });

  factory PeakHoursAnalysis.fromJson(Map<String, dynamic> json) {
    return PeakHoursAnalysis(
      morning: json['morning'] != null
          ? PeakHourPeriod.fromJson(json['morning'])
          : PeakHourPeriod.empty,
      afternoon: json['afternoon'] != null
          ? PeakHourPeriod.fromJson(json['afternoon'])
          : PeakHourPeriod.empty,
      evening: json['evening'] != null
          ? PeakHourPeriod.fromJson(json['evening'])
          : PeakHourPeriod.empty,
      night: json['night'] != null
          ? PeakHourPeriod.fromJson(json['night'])
          : PeakHourPeriod.empty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning': morning.toJson(),
      'afternoon': afternoon.toJson(),
      'evening': evening.toJson(),
      'night': night.toJson(),
    };
  }

  @override
  List<Object?> get props => [morning, afternoon, evening, night];

  static const empty = PeakHoursAnalysis(
    morning: PeakHourPeriod.empty,
    afternoon: PeakHourPeriod.empty,
    evening: PeakHourPeriod.empty,
    night: PeakHourPeriod.empty,
  );
}

/// Peak hour period data
class PeakHourPeriod extends Equatable {
  final String period;
  final String timeRange;
  final double earnings;

  const PeakHourPeriod({
    required this.period,
    required this.timeRange,
    required this.earnings,
  });

  factory PeakHourPeriod.fromJson(Map<String, dynamic> json) {
    return PeakHourPeriod(
      period: json['period'] ?? '',
      timeRange: json['timeRange'] ?? '',
      earnings: (json['earnings'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'timeRange': timeRange,
      'earnings': earnings,
    };
  }

  @override
  List<Object?> get props => [period, timeRange, earnings];

  static const empty = PeakHourPeriod(
    period: '',
    timeRange: '',
    earnings: 0,
  );
}


