import 'package:equatable/equatable.dart';

/// Comprehensive loading states for calendar functionality
/// Designed for smooth user experience with clear state transitions
enum CalendarLoadingState {
  /// Initial state - showing skeleton loading
  initial,
  
  /// Loading astrologer ID from local storage
  loadingAstrologerId,
  
  /// Loading consultations from server
  loadingConsultations,
  
  /// Data successfully loaded
  loaded,
  
  /// Error occurred during loading
  error,
  
  /// Refreshing data (pull-to-refresh)
  refreshing,
  
  /// Loading more data (pagination)
  loadingMore,
}

/// Calendar loading state model with additional context
class CalendarLoadingModel extends Equatable {
  final CalendarLoadingState state;
  final String? errorMessage;
  final bool hasData;
  final DateTime? lastUpdated;
  final int retryCount;

  const CalendarLoadingModel({
    required this.state,
    this.errorMessage,
    this.hasData = false,
    this.lastUpdated,
    this.retryCount = 0,
  });

  /// Create initial state
  factory CalendarLoadingModel.initial() {
    return const CalendarLoadingModel(
      state: CalendarLoadingState.initial,
      hasData: false,
    );
  }

  /// Create loading state
  factory CalendarLoadingModel.loading(CalendarLoadingState loadingState) {
    return CalendarLoadingModel(
      state: loadingState,
      hasData: false,
    );
  }

  /// Create loaded state
  factory CalendarLoadingModel.loaded() {
    return CalendarLoadingModel(
      state: CalendarLoadingState.loaded,
      hasData: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create error state
  factory CalendarLoadingModel.error(String message, {int retryCount = 0}) {
    return CalendarLoadingModel(
      state: CalendarLoadingState.error,
      errorMessage: message,
      hasData: false,
      retryCount: retryCount,
    );
  }

  /// Create refreshing state
  factory CalendarLoadingModel.refreshing() {
    return const CalendarLoadingModel(
      state: CalendarLoadingState.refreshing,
      hasData: true,
    );
  }

  /// Copy with new values
  CalendarLoadingModel copyWith({
    CalendarLoadingState? state,
    String? errorMessage,
    bool? hasData,
    DateTime? lastUpdated,
    int? retryCount,
  }) {
    return CalendarLoadingModel(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      hasData: hasData ?? this.hasData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Check if currently loading
  bool get isLoading {
    return state == CalendarLoadingState.initial ||
           state == CalendarLoadingState.loadingAstrologerId ||
           state == CalendarLoadingState.loadingConsultations ||
           state == CalendarLoadingState.refreshing ||
           state == CalendarLoadingState.loadingMore;
  }

  /// Check if has error
  bool get hasError {
    return state == CalendarLoadingState.error;
  }

  /// Check if data is loaded
  bool get isLoaded {
    return state == CalendarLoadingState.loaded;
  }

  /// Check if can retry
  bool get canRetry {
    return hasError && retryCount < 3;
  }

  /// Get loading message for current state
  String get loadingMessage {
    switch (state) {
      case CalendarLoadingState.initial:
        return 'Initializing calendar...';
      case CalendarLoadingState.loadingAstrologerId:
        return 'Loading profile...';
      case CalendarLoadingState.loadingConsultations:
        return 'Loading consultations...';
      case CalendarLoadingState.refreshing:
        return 'Refreshing data...';
      case CalendarLoadingState.loadingMore:
        return 'Loading more data...';
      case CalendarLoadingState.loaded:
        return 'Calendar ready';
      case CalendarLoadingState.error:
        return errorMessage ?? 'An error occurred';
    }
  }

  @override
  List<Object?> get props => [
        state,
        errorMessage,
        hasData,
        lastUpdated,
        retryCount,
      ];
}


