import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/services/theme_service.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../models/discovery_astrologer.dart';
import '../../clients/widgets/client_search_bar.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Variation 2 - High-end astrologer discovery experience
///
/// Goal: Feel like the best discovery page in the world:
/// - Big, visual hero cards
/// - Featured carousel
/// - Smart match score
/// - List/Grid toggle
class DiscoveryScreenV2 extends StatefulWidget {
  const DiscoveryScreenV2({super.key});

  @override
  State<DiscoveryScreenV2> createState() => _DiscoveryScreenV2State();
}

class _DiscoveryScreenV2State extends State<DiscoveryScreenV2> with SingleTickerProviderStateMixin {
  bool _isGridView = true; // Default to grid view
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      context.read<DiscoveryBloc>().add(const ClearFiltersEvent());
    } else {
      context.read<DiscoveryBloc>().add(SearchAstrologersEvent(query));
    }
  }

  void _toggleViewMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(themeService),
            _buildSearchAndViewToggle(themeService),
            _buildQuickFilters(themeService),
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return _buildLoadingState(themeService);
                  } else if (state is DiscoveryLoaded) {
                    if (state.astrologers.isEmpty) {
                      return _buildEmptyState(themeService, state.searchQuery);
                    }
                    return _buildContent(themeService, state.astrologers);
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

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: themeService.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: themeService.borderColor.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: themeService.textPrimary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Astrologers',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Handpicked experts just for you',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeService.borderColor.withOpacity(0.2),
              ),
            ),
            child: IconButton(
              onPressed: _toggleViewMode,
              icon: Icon(
                _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                color: themeService.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndViewToggle(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: ClientSearchBar(
        hintText: 'Search by name, skill or language',
        minimal: true,
        onSearch: _onSearch,
        onClear: () {
          context.read<DiscoveryBloc>().add(const ClearFiltersEvent());
        },
      ),
    );
  }

  Widget _buildQuickFilters(ThemeService themeService) {
    final filterCount = _getFilterCount(_activeFilters);
    
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterTabs[index];
          final isFilter = filter['value'] == 'filter';
          final isSelected = !isFilter && _tabController.index == index;
          
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(index, duration: Duration.zero);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? themeService.primaryColor 
                    : (isFilter && filterCount > 0)
                        ? themeService.primaryColor.withOpacity(0.1)
                        : themeService.cardColor,
                borderRadius: BorderRadius.circular(100),
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
                      size: filter['value'] == 'online' ? 9 : 15,
                      color: isSelected 
                          ? Colors.white 
                          : (isFilter && filterCount > 0)
                              ? themeService.primaryColor
                              : themeService.textSecondary,
                    ),
                    const SizedBox(width: 5),
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
                      fontSize: 13,
                      fontWeight: (isSelected || (isFilter && filterCount > 0))
                          ? FontWeight.w600 
                          : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // Filter count badge
                  if (isFilter && filterCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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

  Widget _buildContent(ThemeService themeService, List<DiscoveryAstrologer> astrologers) {
    // Build featured list (top 3 by rating + consultations)
    final featured = List<DiscoveryAstrologer>.from(astrologers)
      ..sort(
        (a, b) {
          final ratingDiff = b.rating.compareTo(a.rating);
          if (ratingDiff != 0) return ratingDiff;
          return b.totalConsultations.compareTo(a.totalConsultations);
        },
      );
    final featuredAstrologers = featured.take(3).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildFeaturedCarousel(themeService, featuredAstrologers),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All astrologers',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${astrologers.length} found',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isGridView)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final astrologer = astrologers[index];
                  return _CompactGridCard(
                    astrologer: astrologer,
                    themeService: themeService,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // In production: navigate to astrologer profile
                    },
                    onChatTap: () {
                      HapticFeedback.mediumImpact();
                      _showChatSnackbar(themeService, astrologer.name);
                    },
                  );
                },
                childCount: astrologers.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65, // Taller cards to fit all content
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final astrologer = astrologers[index];
                  return _HeroAstrologerCard(
                    astrologer: astrologer,
                    themeService: themeService,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // In production: navigate to astrologer profile
                    },
                    onChatTap: () {
                      HapticFeedback.mediumImpact();
                      _showChatSnackbar(themeService, astrologer.name);
                    },
                  );
                },
                childCount: astrologers.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCarousel(
    ThemeService themeService,
    List<DiscoveryAstrologer> featured,
  ) {
    if (featured.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final astrologer = featured[index];
          final matchScore = _calculateMatchScore(astrologer);

          return Container(
            width: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  themeService.primaryColor.withOpacity(0.95),
                  themeService.primaryColor.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                // In production: navigate to astrologer profile
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatarWidget(
                          imagePath: astrologer.profilePicture,
                          radius: 22,
                          fallbackText: astrologer.name
                              .substring(0, 1)
                              .toUpperCase(),
                          backgroundColor: Colors.white,
                          textColor: themeService.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                astrologer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                astrologer.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (astrologer.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchScore% match',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${astrologer.rating} • ${astrologer.totalReviews} reviews',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${astrologer.ratePerMinute.toStringAsFixed(0)}/min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${astrologer.experience} yrs exp',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _calculateMatchScore(DiscoveryAstrologer astrologer) {
    final ratingScore = (astrologer.rating / 5.0) * 60;
    final popularityScore =
        (astrologer.totalConsultations / 2000).clamp(0, 1) * 25;
    final loyaltyScore = (astrologer.repeatClients / 100).clamp(0, 1) * 15;
    final total = ratingScore + popularityScore + loyaltyScore;
    return total.clamp(70, 99).round();
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 220,
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
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
              query != null ? 'No perfect match yet' : 'No astrologers available',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query != null
                  ? 'Try adjusting filters or searching with different keywords.'
                  : 'Please check back later.',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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
}

class _HeroAstrologerCard extends StatelessWidget {
  final DiscoveryAstrologer astrologer;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _HeroAstrologerCard({
    required this.astrologer,
    required this.themeService,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeService.borderColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / visual header
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeService.primaryColor.withOpacity(0.1),
                          themeService.primaryColor.withOpacity(0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: (astrologer.profilePicture?.isNotEmpty ?? false)
                        ? Image.network(
                            astrologer.profilePicture!,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: astrologer.isOnline
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            astrologer.isOnline ? 'Online now' : 'Available soon',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ProfileAvatarWidget(
                          imagePath: astrologer.profilePicture,
                          radius: 22,
                          fallbackText: astrologer.name
                              .substring(0, 1)
                              .toUpperCase(),
                          backgroundColor: Colors.white,
                          textColor: themeService.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                astrologer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                astrologer.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                astrologer.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Text(
                    '₹${astrologer.ratePerMinute.toStringAsFixed(0)}/min',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${astrologer.experience} yrs experience',
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Replies in ${astrologer.responseTime}',
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${astrologer.totalConsultations}+ sessions',
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: themeService.borderColor.withOpacity(0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'View profile',
                        style: TextStyle(
                          color: themeService.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onChatTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: themeService.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Start chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CompactGridCard extends StatelessWidget {
  final DiscoveryAstrologer astrologer;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _CompactGridCard({
    required this.astrologer,
    required this.themeService,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeService.borderColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // Avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatarWidget(
                    imagePath: astrologer.profilePicture,
                    radius: 32,
                    fallbackText: astrologer.name.substring(0, 1).toUpperCase(),
                    backgroundColor: themeService.primaryColor.withOpacity(0.1),
                    textColor: themeService.primaryColor,
                  ),
                  if (astrologer.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeService.cardColor,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  if (astrologer.isVerified)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  astrologer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      astrologer.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' (${astrologer.totalReviews})',
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Experience and price
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: themeService.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${astrologer.experience}y',
                      style: TextStyle(
                        color: themeService.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 12,
                      color: themeService.borderColor.withOpacity(0.3),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${astrologer.ratePerMinute.toStringAsFixed(0)}/min',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Specializations (max 2)
              if (astrologer.specializations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: astrologer.specializations.take(2).map((spec) {
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 70),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spec,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeService.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Chat button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onChatTap();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: themeService.primaryColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


