import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/live_feed_bloc.dart';
import '../bloc/live_feed_event.dart';
import '../bloc/live_feed_state.dart';
import '../widgets/live_category_filter_widget.dart';
import 'live_stream_viewer_page.dart';

/// Vertical scrolling live feed screen (like Instagram Reels)
/// Allows users to swipe between different live streams
class LiveFeedScreen extends StatefulWidget {
  final String? initialStreamId; // Stream to start from (when tapped from dashboard)
  final String? initialCategory; // Optional category filter
  
  const LiveFeedScreen({
    super.key,
    this.initialStreamId,
    this.initialCategory,
  });

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showCategoryFilter = false;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Set full-screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    print('📱 LiveFeedScreen initState');
    print('   initialStreamId: ${widget.initialStreamId}');
    print('   initialCategory: ${widget.initialCategory}');
    
    // Check if bloc already has data
    final state = context.read<LiveFeedBloc>().state;
    print('   Current state: ${state.runtimeType}');
    
    if (state is LiveFeedLoaded) {
      print('   ✅ Bloc already loaded with ${state.streams.length} streams');
      // Don't reload - data is already there
      // Just set the current page if initialStreamId is provided
      if (widget.initialStreamId != null) {
        final index = state.streams.indexWhere((s) => s.id == widget.initialStreamId);
        if (index != -1) {
          print('   ✅ Found stream at index: $index');
          _currentPage = index;
          // Jump to page after frame renders
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(index);
            }
          });
        }
      }
    } else {
      print('   ⚠️ Bloc not loaded, dispatching LoadLiveFeedEvent');
      // Load live feed only if not already loaded
      context.read<LiveFeedBloc>().add(LoadLiveFeedEvent(
        startStreamId: widget.initialStreamId,
        category: widget.initialCategory,
      ));
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    
    final state = context.read<LiveFeedBloc>().state;
    if (state is LiveFeedLoaded && index < state.streams.length) {
      final stream = state.streams[index];
      
      // Notify BLoC of page change
      context.read<LiveFeedBloc>().add(ChangeCurrentStreamEvent(
        index: index,
        streamId: stream.id,
      ));
      
      // Preload next stream (Instagram-style optimization)
      if (index + 1 < state.streams.length) {
        context.read<LiveFeedBloc>().add(PreloadNextStreamEvent(index + 1));
      }
      
      // Memory optimization: Log which streams should be kept
      // Only keep current, previous, and next (3 total)
      // This is a placeholder for future optimization with Agora
      final keepRange = [
        if (index > 0) index - 1, // Previous
        index, // Current
        if (index + 1 < state.streams.length) index + 1, // Next
      ];
      
      print('📊 Active streams: ${keepRange.map((i) => state.streams[i].id)}');
      print('💾 Dispose streams outside range (${keepRange.first} - ${keepRange.last})');
    }
  }
  
  void _toggleCategoryFilter() {
    HapticFeedback.selectionClick();
    setState(() {
      _showCategoryFilter = !_showCategoryFilter;
    });
  }
  
  void _onCategorySelected(String? category) {
    HapticFeedback.selectionClick();
    setState(() {
      _showCategoryFilter = false;
    });
    
    context.read<LiveFeedBloc>().add(FilterByCategoryEvent(category));
  }
  
  void _onRefresh() {
    final state = context.read<LiveFeedBloc>().state;
    String? currentCategory;
    
    if (state is LiveFeedLoaded) {
      currentCategory = state.selectedCategory;
    }
    
    context.read<LiveFeedBloc>().add(RefreshLiveFeedEvent(
      category: currentCategory,
    ));
  }
  
  void _exitFeed() async {
    HapticFeedback.selectionClick();
    
    // Pop only; let the previous screen restore System UI to avoid flicker
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          // Use same smooth exit as X button
          _exitFeed();
        }
      },
      child: BlocBuilder<LiveFeedBloc, LiveFeedState>(
        builder: (context, state) {
          print('🔄 LiveFeedScreen build - State: ${state.runtimeType}');
          
        if (state is LiveFeedLoading) {
          print('   ⏳ Showing loading screen');
          return _buildLoadingScreen();
        }
        
        if (state is LiveFeedError) {
          print('   ❌ Showing error: ${state.message}');
          return _buildErrorScreen(state.message);
        }
        
        if (state is LiveFeedEmpty) {
          print('   📭 Showing empty screen');
          return _buildEmptyScreen(state.selectedCategory);
        }
        
        if (state is LiveFeedLoaded) {
          print('   ✅ Showing feed with ${state.streams.length} streams');
          print('   ✅ Current index: ${state.currentIndex}');
          return _buildFeedScreen(state);
        }
        
        print('   ⚠️ Unknown state, showing loading');
        return _buildLoadingScreen();
      },
      ),
    );
  }
  
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading live streams...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _exitFeed,
                    icon: const Icon(Icons.close),
                    label: const Text('Exit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyScreen(String? category) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.live_tv_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                category != null
                    ? 'No live streams in $category'
                    : 'No live streams available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later or explore other categories',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (category != null)
                    ElevatedButton.icon(
                      onPressed: () => _onCategorySelected(null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  if (category != null) const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _exitFeed,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeedScreen(LiveFeedLoaded state) {
    // Initialize PageController with correct initial page
    if (_currentPage != state.currentIndex && _pageController.hasClients) {
      _pageController.jumpToPage(state.currentIndex);
      _currentPage = state.currentIndex;
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: state.streams.length,
        itemBuilder: (context, index) {
          final stream = state.streams[index];
          final isActive = index == _currentPage;
          
          return LiveStreamViewerPage(
            stream: stream,
            isActive: isActive,
            onExit: _exitFeed,
          );
        },
      ),
    );
  }
}

