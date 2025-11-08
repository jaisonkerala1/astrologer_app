import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/live_feed_repository.dart';
import 'live_feed_event.dart';
import 'live_feed_state.dart';

/// BLoC for managing live feed (vertical scrolling)
class LiveFeedBloc extends Bloc<LiveFeedEvent, LiveFeedState> {
  final LiveFeedRepository _repository;
  
  // Pagination state
  int _currentPage = 1;
  static const int _pageSize = 10;
  
  LiveFeedBloc({
    required LiveFeedRepository repository,
  })  : _repository = repository,
        super(const LiveFeedInitial()) {
    on<LoadLiveFeedEvent>(_onLoadLiveFeed);
    on<LoadMoreLiveStreamsEvent>(_onLoadMoreStreams);
    on<ChangeCurrentStreamEvent>(_onChangeCurrentStream);
    on<RefreshLiveFeedEvent>(_onRefreshLiveFeed);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<PreloadNextStreamEvent>(_onPreloadNextStream);
  }
  
  /// Load initial live feed
  Future<void> _onLoadLiveFeed(
    LoadLiveFeedEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    try {
      emit(const LiveFeedLoading());
      
      // Fetch live streams
      final streams = await _repository.getActiveLiveStreams(
        page: 1,
        limit: _pageSize,
        category: event.category,
      );
      
      if (streams.isEmpty) {
        emit(LiveFeedEmpty(selectedCategory: event.category));
        return;
      }
      
      // Find starting index if specific stream was tapped
      int startIndex = 0;
      if (event.startStreamId != null) {
        final index = streams.indexWhere((s) => s.id == event.startStreamId);
        if (index != -1) {
          startIndex = index;
        }
      }
      
      _currentPage = 1;
      
      emit(LiveFeedLoaded(
        streams: streams,
        currentIndex: startIndex,
        hasMoreStreams: streams.length == _pageSize, // If full page, likely more available
        selectedCategory: event.category,
        totalStreams: streams.length,
      ));
      
    } catch (e) {
      emit(LiveFeedError(message: 'Failed to load live streams: $e'));
    }
  }
  
  /// Load more streams (pagination)
  Future<void> _onLoadMoreStreams(
    LoadMoreLiveStreamsEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LiveFeedLoaded) return;
    if (!currentState.hasMoreStreams) return;
    
    try {
      emit(LiveFeedLoadingMore(
        currentStreams: currentState.streams,
        currentIndex: currentState.currentIndex,
        selectedCategory: currentState.selectedCategory,
      ));
      
      _currentPage++;
      
      final newStreams = await _repository.getActiveLiveStreams(
        page: _currentPage,
        limit: _pageSize,
        category: currentState.selectedCategory,
      );
      
      final allStreams = [...currentState.streams, ...newStreams];
      
      emit(LiveFeedLoaded(
        streams: allStreams,
        currentIndex: currentState.currentIndex,
        hasMoreStreams: newStreams.length == _pageSize,
        selectedCategory: currentState.selectedCategory,
        totalStreams: allStreams.length,
      ));
      
    } catch (e) {
      // Emit error but keep current streams cached
      emit(LiveFeedError(
        message: 'Failed to load more streams: $e',
        cachedStreams: currentState.streams,
        cachedIndex: currentState.currentIndex,
      ));
    }
  }
  
  /// Change current active stream
  Future<void> _onChangeCurrentStream(
    ChangeCurrentStreamEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LiveFeedLoaded) return;
    
    // Handle looping: if at end, go back to start
    int newIndex = event.index;
    if (newIndex >= currentState.streams.length) {
      newIndex = 0; // Loop back to first stream
    } else if (newIndex < 0) {
      newIndex = currentState.streams.length - 1; // Loop to last stream
    }
    
    emit(LiveFeedLoaded(
      streams: currentState.streams,
      currentIndex: newIndex,
      hasMoreStreams: currentState.hasMoreStreams,
      selectedCategory: currentState.selectedCategory,
      totalStreams: currentState.totalStreams,
    ));
    
    // Check if should load more (near end)
    if (currentState.shouldLoadMore) {
      add(const LoadMoreLiveStreamsEvent());
    }
  }
  
  /// Refresh live feed
  Future<void> _onRefreshLiveFeed(
    RefreshLiveFeedEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    try {
      final streams = await _repository.getActiveLiveStreams(
        page: 1,
        limit: _pageSize,
        category: event.category,
      );
      
      if (streams.isEmpty) {
        emit(LiveFeedEmpty(selectedCategory: event.category));
        return;
      }
      
      _currentPage = 1;
      
      emit(LiveFeedLoaded(
        streams: streams,
        currentIndex: 0, // Reset to first stream on refresh
        hasMoreStreams: streams.length == _pageSize,
        selectedCategory: event.category,
        totalStreams: streams.length,
      ));
      
    } catch (e) {
      emit(LiveFeedError(message: 'Failed to refresh: $e'));
    }
  }
  
  /// Filter by category
  Future<void> _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    // Trigger new load with category filter
    add(LoadLiveFeedEvent(category: event.category));
  }
  
  /// Preload next stream (for performance)
  Future<void> _onPreloadNextStream(
    PreloadNextStreamEvent event,
    Emitter<LiveFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LiveFeedLoaded) return;
    
    // Check if next stream exists
    if (event.nextIndex < currentState.streams.length) {
      final nextStream = currentState.streams[event.nextIndex];
      // Preload stream data (ready for Agora integration)
      await _repository.preloadStreamData(nextStream.id);
    }
  }
}

