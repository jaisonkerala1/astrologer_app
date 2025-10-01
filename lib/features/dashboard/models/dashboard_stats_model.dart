import '../../auth/models/astrologer_model.dart';

class DashboardStatsModel {
  final double todayEarnings;
  final double totalEarnings;
  final int callsToday;
  final int totalCalls;
  final bool isOnline;
  final int totalSessions;
  final double averageSessionDuration;
  final double averageRating;
  final int todayCount;
  final AstrologerModel? astrologer;

  DashboardStatsModel({
    required this.todayEarnings,
    required this.totalEarnings,
    required this.callsToday,
    required this.totalCalls,
    required this.isOnline,
    required this.totalSessions,
    required this.averageSessionDuration,
    required this.averageRating,
    required this.todayCount,
    this.astrologer,
  });

  // Empty constructor for initial state
  DashboardStatsModel.empty()
      : todayEarnings = 0.0,
        totalEarnings = 0.0,
        callsToday = 0,
        totalCalls = 0,
        isOnline = false,
        totalSessions = 0,
        averageSessionDuration = 0.0,
        averageRating = 0.0,
        todayCount = 0,
        astrologer = null;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      callsToday: json['callsToday'] ?? 0,
      totalCalls: json['totalCalls'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      totalSessions: json['totalSessions'] ?? 0,
      averageSessionDuration: (json['averageSessionDuration'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      todayCount: json['todayCount'] ?? 0,
      astrologer: json['astrologer'] != null ? AstrologerModel.fromJson(json['astrologer']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayEarnings': todayEarnings,
      'totalEarnings': totalEarnings,
      'callsToday': callsToday,
      'totalCalls': totalCalls,
      'isOnline': isOnline,
      'totalSessions': totalSessions,
      'averageSessionDuration': averageSessionDuration,
      'averageRating': averageRating,
      'todayCount': todayCount,
    };
  }

  DashboardStatsModel copyWith({
    double? todayEarnings,
    double? totalEarnings,
    int? callsToday,
    int? totalCalls,
    bool? isOnline,
    int? totalSessions,
    double? averageSessionDuration,
    double? averageRating,
    int? todayCount,
    AstrologerModel? astrologer,
  }) {
    return DashboardStatsModel(
      todayEarnings: todayEarnings ?? this.todayEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      callsToday: callsToday ?? this.callsToday,
      totalCalls: totalCalls ?? this.totalCalls,
      isOnline: isOnline ?? this.isOnline,
      totalSessions: totalSessions ?? this.totalSessions,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      averageRating: averageRating ?? this.averageRating,
      todayCount: todayCount ?? this.todayCount,
      astrologer: astrologer ?? this.astrologer,
    );
  }
}









