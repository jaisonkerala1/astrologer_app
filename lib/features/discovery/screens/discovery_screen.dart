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
import 'top_astrologers_screen.dart';
import 'all_astrologers_screen.dart';

/// World-class Astrologer Discovery Screen
/// Features:
/// - Immersive hero carousel with gradient overlays and live meta
/// - Clean minimal grid cards with professional design
/// - Smart filter system with bottom sheet
/// - Top Astrologers ranking screen
/// - Real-time online status and verification badges
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late final PageController _heroController;
  late TabController _tabController;
  double _currentHeroPage = 0;
  String? _selectedFilter;
  Map<String, dynamic> _activeFilters = {};
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filterTabs = [
    {'label': 'Filter', 'value': 'filter', 'icon': Icons.tune_rounded},
    {'label': 'Online Now', 'value': 'online', 'icon': Icons.circle},
    {'label': 'Top Rated', 'value': 'rating', 'icon': Icons.star_rounded},
    {'label': 'Most Experienced', 'value': 'experience', 'icon': Icons.workspace_premium_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _heroController = PageController(viewportFraction: 0.80);
    _heroController.addListener(_onHeroScroll);
    
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

  void _onHeroScroll() {
    setState(() {
      _currentHeroPage = _heroController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroController
      ..removeListener(_onHeroScroll)
      ..dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isEmpty) {
      context.read<DiscoveryBloc>().add(const ClearFiltersEvent());
    } else {
      context.read<DiscoveryBloc>().add(SearchAstrologersEvent(query));
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      double result = number / 1000;
      if (result % 1 == 0) {
        return '${result.toInt()}k';
      }
      return '${result.toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(themeService),
            ),
            SliverToBoxAdapter(
              child: _buildSearchBar(themeService),
            ),
            SliverToBoxAdapter(
              child: _buildQuickFilters(themeService),
            ),
            BlocBuilder<DiscoveryBloc, DiscoveryState>(
              builder: (context, state) {
                if (state is DiscoveryLoading) {
                  return SliverFillRemaining(
                    child: _buildLoadingState(themeService),
                  );
                } else if (state is DiscoveryLoaded) {
                  if (state.astrologers.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(themeService, state.searchQuery ?? _searchQuery),
                    );
                  }
                  final featured = state.astrologers.take(4).toList();
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (featured.isNotEmpty) ...[
                        // Top Astrologers heading
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Top Astrologers',
                                style: TextStyle(
                                  color: themeService.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider(
                                          create: (context) => DiscoveryBloc()..add(const LoadAstrologersEvent(sortBy: 'rating')),
                                          child: const TopAstrologersScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'See All',
                                          style: TextStyle(
                                            color: themeService.primaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: themeService.primaryColor,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Carousel
                        _buildHeroCarousel(themeService, featured),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Astrologers for you',
                              style: TextStyle(
                                color: themeService.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (context) => DiscoveryBloc()..add(const LoadAstrologersEvent(onlineOnly: true)),
                                        child: const AllAstrologersScreen(),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'See All',
                                        style: TextStyle(
                                          color: themeService.primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: themeService.primaryColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.astrologers.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemBuilder: (context, index) {
                            final astrologer = state.astrologers[index];
                            return _CompactGridCardV5(
                              astrologer: astrologer,
                              themeService: themeService,
                              onTap: () {
                                HapticFeedback.selectionClick();
                              },
                              onChatTap: () {
                                HapticFeedback.mediumImpact();
                                _showChatSnackbar(themeService, astrologer.name);
                              },
                            );
                          },
                        ),
                      ),
                    ]),
                  );
                } else if (state is DiscoveryError) {
                  return SliverFillRemaining(
                    child: _buildErrorState(themeService, state.message),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeService.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.borderColor.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: themeService.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discovery V5',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Handpicked Vedic specialists',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: themeService.borderColor.withOpacity(0.1)),
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.favorite_border_rounded,
                color: themeService.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClientSearchBar(
        hintText: 'Search name, skill or language',
        minimal: true,
        onSearch: _onSearch,
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildHeroCarousel(ThemeService themeService, List<DiscoveryAstrologer> featured) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _heroController,
            itemCount: featured.length,
            padEnds: false,
            itemBuilder: (context, index) {
              final astrologer = featured[index];
              final scale = (_currentHeroPage - index).abs().clamp(0.0, 1.0);
              final transformValue = 1 - (scale * 0.08);

              return Transform.scale(
                scale: transformValue,
                child: GestureDetector(
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 20 : 6,
                      right: 6,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          themeService.primaryColor.withOpacity(0.9),
                          themeService.primaryColor.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeService.primaryColor.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -20,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Left side: Avatar
                              ProfileAvatarWidget(
                                imagePath: astrologer.profilePicture,
                                radius: 28,
                                fallbackText: astrologer.name.substring(0, 1).toUpperCase(),
                                backgroundColor: Colors.white,
                                textColor: themeService.primaryColor,
                              ),
                              const SizedBox(width: 14),
                              
                              // Right side: Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Name
                                    Text(
                                      astrologer.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    
                                    // Title
                                    Text(
                                      astrologer.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Specializations - compact horizontal list
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: astrologer.specializations.take(3).map((spec) {
                                          return Container(
                                            margin: const EdgeInsets.only(right: 5),
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              spec,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Stats - compact horizontal row
                                    Row(
                                      children: [
                                        // Rating
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Colors.amber,
                                                size: 11,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                astrologer.rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        
                                        // Experience
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${astrologer.experience}y exp',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        
                                        // Sessions
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${_formatNumber(astrologer.totalConsultations)} sessions',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // View Profile button - top right corner
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featured.length, (index) {
            final isActive = (_currentHeroPage.round() == index);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? themeService.primaryColor : themeService.borderColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeService themeService) {
    return Center(
      child: CircularProgressIndicator(
        color: themeService.primaryColor,
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
              query != null ? Icons.search_off_rounded : Icons.explore_outlined,
              size: 80,
              color: themeService.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              query != null ? 'No perfect match yet' : 'No astrologers available',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query != null ? 'Try adjusting keywords or filters.' : 'Please check back later.',
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
              color: themeService.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 20,
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
      ),
    );
  }
}

class _CompactGridCardV5 extends StatelessWidget {
  final DiscoveryAstrologer astrologer;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _CompactGridCardV5({
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


