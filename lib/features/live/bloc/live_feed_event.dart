import 'package:equatable/equatable.dart';

/// Events for Live Feed feature
abstract class LiveFeedEvent extends Equatable {
  const LiveFeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial live feed
class LoadLiveFeedEvent extends LiveFeedEvent {
  final String? startStreamId; // Stream to start from (when tapped from dashboard)
  final String? category; // Optional category filter
  
  const LoadLiveFeedEvent({
    this.startStreamId,
    this.category,
  });
  
  @override
  List<Object?> get props => [startStreamId, category];
}

/// Load more live streams (pagination)
class LoadMoreLiveStreamsEvent extends LiveFeedEvent {
  const LoadMoreLiveStreamsEvent();
}

/// Change current active stream
class ChangeCurrentStreamEvent extends LiveFeedEvent {
  final int index;
  final String streamId;
  
  const ChangeCurrentStreamEvent({
    required this.index,
    required this.streamId,
  });
  
  @override
  List<Object?> get props => [index, streamId];
}

/// Refresh live feed
class RefreshLiveFeedEvent extends LiveFeedEvent {
  final String? category;
  
  const RefreshLiveFeedEvent({this.category});
  
  @override
  List<Object?> get props => [category];
}

/// Filter by category
class FilterByCategoryEvent extends LiveFeedEvent {
  final String? category; // null = all categories
  
  const FilterByCategoryEvent(this.category);
  
  @override
  List<Object?> get props => [category];
}

/// Preload next stream
class PreloadNextStreamEvent extends LiveFeedEvent {
  final int nextIndex;
  
  const PreloadNextStreamEvent(this.nextIndex);
  
  @override
  List<Object?> get props => [nextIndex];
}

