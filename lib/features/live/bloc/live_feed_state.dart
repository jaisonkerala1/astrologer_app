import 'package:equatable/equatable.dart';
import '../models/live_stream_model.dart';

/// States for Live Feed feature
abstract class LiveFeedState extends Equatable {
  const LiveFeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LiveFeedInitial extends LiveFeedState {
  const LiveFeedInitial();
}

/// Loading state (initial load)
class LiveFeedLoading extends LiveFeedState {
  const LiveFeedLoading();
}

/// Loading more streams (pagination)
class LiveFeedLoadingMore extends LiveFeedState {
  final List<LiveStreamModel> currentStreams;
  final int currentIndex;
  final String? selectedCategory;
  
  const LiveFeedLoadingMore({
    required this.currentStreams,
    required this.currentIndex,
    this.selectedCategory,
  });
  
  @override
  List<Object?> get props => [currentStreams, currentIndex, selectedCategory];
}

/// Successfully loaded live feed
class LiveFeedLoaded extends LiveFeedState {
  final List<LiveStreamModel> streams;
  final int currentIndex;
  final bool hasMoreStreams;
  final String? selectedCategory;
  final int totalStreams;
  
  const LiveFeedLoaded({
    required this.streams,
    required this.currentIndex,
    this.hasMoreStreams = true,
    this.selectedCategory,
    required this.totalStreams,
  });
  
  @override
  List<Object?> get props => [
    streams,
    currentIndex,
    hasMoreStreams,
    selectedCategory,
    totalStreams,
  ];
  
  /// Get current active stream
  LiveStreamModel get currentStream => streams[currentIndex];
  
  /// Check if can load more
  bool get shouldLoadMore => hasMoreStreams && currentIndex >= streams.length - 2;
}

/// Error state
class LiveFeedError extends LiveFeedState {
  final String message;
  final List<LiveStreamModel>? cachedStreams; // Keep cached data for retry
  final int? cachedIndex;
  
  const LiveFeedError({
    required this.message,
    this.cachedStreams,
    this.cachedIndex,
  });
  
  @override
  List<Object?> get props => [message, cachedStreams, cachedIndex];
}

/// No live streams available
class LiveFeedEmpty extends LiveFeedState {
  final String? selectedCategory;
  
  const LiveFeedEmpty({this.selectedCategory});
  
  @override
  List<Object?> get props => [selectedCategory];
}

/// Stream ended during viewing
class LiveFeedStreamEnded extends LiveFeedState {
  final List<LiveStreamModel> remainingStreams;
  final int lastIndex;
  final String endedStreamId;
  
  const LiveFeedStreamEnded({
    required this.remainingStreams,
    required this.lastIndex,
    required this.endedStreamId,
  });
  
  @override
  List<Object?> get props => [remainingStreams, lastIndex, endedStreamId];
}

