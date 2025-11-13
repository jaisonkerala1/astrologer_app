import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/astrologer_card.dart';
import '../../profile/screens/astrologer_profile_screen.dart';
import '../../clients/widgets/client_search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Premium astrologer discovery screen with world-class UI/UX
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String? _selectedFilter;
  Map<String, dynamic> _activeFilters = {};
  
  final List<Map<String, dynamic>> _filterTabs = [
    {'label': 'Filter', 'value': 'filter', 'icon': Icons.tune_rounded},
    {'label': 'Online Now', 'value': 'online', 'icon': Icons.circle},
    {'label': 'Top Rated', 'value': 'rating', 'icon': Icons.star_rounded},
    {'label': 'Most Experienced', 'value': 'experience', 'icon': Icons.workspace_premium_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with "Online Now" tab (index 1)
    _tabController = TabController(length: _filterTabs.length, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
    _selectedFilter = 'online'; // Set default filter
    
    // Load astrologers with "Online Now" filter on init
    context.read<DiscoveryBloc>().add(const LoadAstrologersEvent(onlineOnly: true));
  }

  void _onTabChanged() {
    // Remove the indexIsChanging check for instant response
    final value = _filterTabs[_tabController.index]['value'];
    
    if (value == 'filter') {
      // Open filter bottom sheet immediately
      _showFilterBottomSheet();
      // Reset tab to previous position without delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final targetIndex = _selectedFilter == 'online' ? 1 : 
                             _selectedFilter == 'rating' ? 2 : 
                             _selectedFilter == 'experience' ? 3 : 1; // Default to online
          _tabController.animateTo(targetIndex, duration: Duration.zero);
        }
      });
    } else if (value != _selectedFilter) {
      // Only update if different to avoid unnecessary rebuilds
      setState(() {
        _selectedFilter = value;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final bloc = context.read<DiscoveryBloc>();
    
    if (_selectedFilter == 'online') {
      bloc.add(const LoadAstrologersEvent(onlineOnly: true));
    } else if (_selectedFilter == 'rating') {
      bloc.add(const LoadAstrologersEvent(sortBy: 'rating'));
    } else if (_selectedFilter == 'experience') {
      bloc.add(const LoadAstrologersEvent(sortBy: 'experience'));
    } else {
      bloc.add(const LoadAstrologersEvent());
    }
  }

  Future<void> _showFilterBottomSheet() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => FilterBottomSheet(
          themeService: themeService,
          currentFilters: _activeFilters,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
      // Apply filters to BLoC
      _applyAdvancedFilters(result);
    }
  }

  void _applyAdvancedFilters(Map<String, dynamic> filters) {
    // This would integrate with your BLoC
    // For now, just show a snackbar
    final count = _getFilterCount(filters);
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count filter${count > 1 ? 's' : ''} applied'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _getFilterCount(Map<String, dynamic> filters) {
    int count = 0;
    if (filters['sortBy'] != null) count++;
    if ((filters['skills'] as List?)?.isNotEmpty ?? false) {
      count += (filters['skills'] as List).length;
    }
    if ((filters['languages'] as List?)?.isNotEmpty ?? false) {
      count += (filters['languages'] as List).length;
    }
    if (filters['gender'] != null) count++;
    if (filters['country'] != null) count++;
    if (filters['offers'] != null) count++;
    return count;
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      context.read<DiscoveryBloc>().add(const ClearFiltersEvent());
    } else {
      context.read<DiscoveryBloc>().add(SearchAstrologersEvent(query));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(themeService),
            
            // Search Bar
            _buildSearchBar(themeService),
            
            // Filter Tabs
            _buildFilterTabs(themeService),
            
            // Astrologers List
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return _buildLoadingState(themeService);
                  } else if (state is DiscoveryLoaded) {
                    if (state.astrologers.isEmpty) {
                      return _buildEmptyState(themeService, state.searchQuery);
                    }
                    return _buildAstrologersList(themeService, state.astrologers);
                  } else if (state is DiscoveryError) {
                    return _buildErrorState(themeService, state.message);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: themeService.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: themeService.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: themeService.textPrimary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Astrologers',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find your perfect guide',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter icon
          Container(
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // Show advanced filters bottom sheet
                _showFiltersBottomSheet(themeService);
              },
              icon: Icon(
                Icons.tune_rounded,
                color: themeService.primaryColor,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClientSearchBar(
        hintText: 'Search astrologers...',
        minimal: true,
        onSearch: _onSearch,
        onClear: () {
          context.read<DiscoveryBloc>().add(const ClearFiltersEvent());
        },
      ),
    );
  }

  Widget _buildFilterTabs(ThemeService themeService) {
    final filterCount = _getFilterCount(_activeFilters);
    
    return Container(
      height: 44, // Reduced from 50
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8), // Reduced from 10
        itemBuilder: (context, index) {
          final filter = _filterTabs[index];
          final isFilter = filter['value'] == 'filter';
          final isSelected = !isFilter && _tabController.index == index;
          
          return GestureDetector(
            behavior: HitTestBehavior.opaque, // Makes entire area tappable
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(index, duration: Duration.zero); // Instant switch
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100), // Even faster animation
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Reduced padding
              decoration: BoxDecoration(
                color: isSelected 
                    ? themeService.primaryColor 
                    : (isFilter && filterCount > 0)
                        ? themeService.primaryColor.withOpacity(0.1)
                        : themeService.cardColor,
                borderRadius: BorderRadius.circular(100), // Pill shape
                border: Border.all(
                  color: isSelected
                      ? themeService.primaryColor
                      : (isFilter && filterCount > 0)
                          ? themeService.primaryColor
                          : themeService.borderColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: themeService.primaryColor.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  if (filter['icon'] != null) ...[
                    Icon(
                      filter['icon'],
                      size: filter['value'] == 'online' ? 9 : 15, // Slightly smaller
                      color: isSelected 
                          ? Colors.white 
                          : (isFilter && filterCount > 0)
                              ? themeService.primaryColor
                              : themeService.textSecondary,
                    ),
                    const SizedBox(width: 5), // Reduced from 6
                  ],
                  // Label
                  Text(
                    filter['label'],
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white
                          : (isFilter && filterCount > 0)
                              ? themeService.primaryColor
                              : themeService.textPrimary,
                      fontSize: 13, // Reduced from 14
                      fontWeight: (isSelected || (isFilter && filterCount > 0))
                          ? FontWeight.w600 
                          : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // Filter count badge
                  if (isFilter && filterCount > 0) ...[
                    const SizedBox(width: 5), // Reduced from 6
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), // Smaller badge
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10, // Reduced from 11
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAstrologersList(ThemeService themeService, List astrologers) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DiscoveryBloc>().add(const RefreshAstrologersEvent());
      },
      color: themeService.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: astrologers.length,
        itemBuilder: (context, index) {
          final astrologer = astrologers[index];
          return AstrologerCard(
            astrologer: astrologer,
            themeService: themeService,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AstrologerProfileScreen(),
                ),
              );
            },
            onChatTap: () {
              _showChatSnackbar(themeService, astrologer.name);
            },
          );
        },
      ),
    );
  }

  void _showChatSnackbar(ThemeService themeService, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with $name...'),
        backgroundColor: themeService.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildSkeletonCard(themeService);
      },
    );
  }

  Widget _buildSkeletonCard(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: themeService.borderColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: themeService.borderColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: themeService.borderColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeService themeService, String? query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query != null ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 80,
              color: themeService.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              query != null 
                  ? 'No astrologers found' 
                  : 'No astrologers available',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query != null
                  ? 'Try searching with different keywords'
                  : 'Please check back later',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeService themeService, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: themeService.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<DiscoveryBloc>().add(const RefreshAstrologersEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersBottomSheet(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeService.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Advanced Filters',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Coming soon!',
                style: TextStyle(
                  color: themeService.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

