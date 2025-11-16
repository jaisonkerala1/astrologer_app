import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/services/theme_service.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../models/discovery_astrologer.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../clients/widgets/client_search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';

/// World-class Top Astrologers screen with premium design
class TopAstrologersScreen extends StatefulWidget {
  const TopAstrologersScreen({super.key});

  @override
  State<TopAstrologersScreen> createState() => _TopAstrologersScreenState();
}

class _TopAstrologersScreenState extends State<TopAstrologersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSort = 'rating';
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};

  final List<Map<String, dynamic>> _sortOptions = [
    {'label': 'Filter', 'value': 'filter', 'icon': Icons.tune_rounded},
    {'label': 'Top Rated', 'value': 'rating', 'icon': Icons.star_rounded},
    {'label': 'Most Experienced', 'value': 'experience', 'icon': Icons.workspace_premium_rounded},
    {'label': 'Most Popular', 'value': 'popularity', 'icon': Icons.trending_up_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sortOptions.length, vsync: this, initialIndex: 1); // Start at Top Rated
    _tabController.addListener(_onTabChanged);
    context.read<DiscoveryBloc>().add(const LoadAstrologersEvent(sortBy: 'rating'));
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final value = _sortOptions[_tabController.index]['value'];
      
      if (value == 'filter') {
        // Open filter bottom sheet
        _showFilterBottomSheet();
        // Reset tab to previous position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final targetIndex = _selectedSort == 'rating' ? 1 : 
                               _selectedSort == 'experience' ? 2 : 
                               _selectedSort == 'popularity' ? 3 : 1;
            _tabController.animateTo(targetIndex, duration: Duration.zero);
          }
        });
      } else if (value != _selectedSort) {
        setState(() {
          _selectedSort = value;
        });
        _applySort();
      }
    }
  }

  Future<void> _showFilterBottomSheet() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => FilterBottomSheet(
        themeService: themeService,
        currentFilters: _activeFilters,
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
      _applyAdvancedFilters(result);
    }
  }

  void _applyAdvancedFilters(Map<String, dynamic> filters) {
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

  void _applySort() {
    final bloc = context.read<DiscoveryBloc>();
    bloc.add(LoadAstrologersEvent(sortBy: _selectedSort));
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applySort();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            _buildHeader(themeService),
            _buildSearchBar(themeService),
            _buildSortTabs(themeService),
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return _buildLoadingState(themeService);
                  } else if (state is DiscoveryLoaded) {
                    if (state.astrologers.isEmpty) {
                      return _buildEmptyState(themeService);
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

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
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
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: themeService.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top Astrologers',
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Elite experts ranked by excellence',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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

  Widget _buildSortTabs(ThemeService themeService) {
    final filterCount = _getFilterCount(_activeFilters);
    
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sortOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _sortOptions[index];
          final isFilter = option['value'] == 'filter';
          final isSelected = !isFilter && _tabController.index == index;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(index, duration: Duration.zero);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeService.primaryColor
                    : themeService.surfaceColor,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? themeService.primaryColor
                      : themeService.borderColor.withOpacity(0.15),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  // Elevated shadow for selected chips
                  if (isSelected)
                    BoxShadow(
                      color: themeService.primaryColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  // Subtle depth shadow for unselected chips
                  if (!isSelected) ...[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFilter && filterCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    option['icon'],
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : themeService.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option['label'],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : themeService.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAstrologersList(ThemeService themeService, List<DiscoveryAstrologer> astrologers) {
    // Split astrologers into sections
    final first6 = astrologers.take(6).toList();
    final horizontal = astrologers.skip(6).take(6).toList();
    final remaining = astrologers.skip(12).toList();

    return RefreshIndicator(
      color: themeService.primaryColor,
      onRefresh: () async {
        context.read<DiscoveryBloc>().add(const RefreshAstrologersEvent());
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // First 6 cards (full-width list cards)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final astrologer = first6[index];
                  final rank = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PremiumRowCard(
                      astrologer: astrologer,
                      rank: rank,
                      themeService: themeService,
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                      onChatTap: () {
                        HapticFeedback.mediumImpact();
                        _showChatSnackbar(themeService, astrologer.name);
                      },
                      formatNumber: _formatNumber,
                    ),
                  );
                },
                childCount: first6.length,
              ),
            ),
          ),

          // Horizontal scrollable section
          if (horizontal.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildHorizontalSection(themeService, horizontal),
            ),

          // Remaining cards (full-width list cards)
          if (remaining.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final astrologer = remaining[index];
                    final rank = 12 + index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PremiumRowCard(
                        astrologer: astrologer,
                        rank: rank,
                        themeService: themeService,
                        onTap: () {
                          HapticFeedback.selectionClick();
                        },
                        onChatTap: () {
                          HapticFeedback.mediumImpact();
                          _showChatSnackbar(themeService, astrologer.name);
                        },
                        formatNumber: _formatNumber,
                      ),
                    );
                  },
                  childCount: remaining.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(ThemeService themeService, List<DiscoveryAstrologer> astrologers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeService.primaryColor,
                      themeService.primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Elite Experts',
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeService.textSecondary,
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Horizontal scrollable cards
        SizedBox(
          height: 270,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: astrologers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final astrologer = astrologers[index];
              return _CompactGridCard(
                astrologer: astrologer,
                themeService: themeService,
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Navigate to profile
                },
                onChatTap: () {
                  HapticFeedback.mediumImpact();
                  _showChatSnackbar(themeService, astrologer.name);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
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

  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars_rounded,
              size: 80,
              color: themeService.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No top astrologers yet',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for elite experts',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
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

/// Compact grid card for horizontal scrolling - EXACT copy from Discovery page
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
      width: 160,
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

/// Minimal astrologer card - exact V1 style
class _PremiumRowCard extends StatelessWidget {
  final DiscoveryAstrologer astrologer;
  final int rank;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onChatTap;
  final String Function(int) formatNumber;

  const _PremiumRowCard({
    required this.astrologer,
    required this.rank,
    required this.themeService,
    required this.onTap,
    required this.onChatTap,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.borderColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    ProfileAvatarWidget(
                      imagePath: astrologer.profilePicture,
                      radius: 32,
                      fallbackText: astrologer.name.substring(0, 1).toUpperCase(),
                    ),
                    if (astrologer.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeService.cardColor,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Verification
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              astrologer.name,
                              style: TextStyle(
                                color: themeService.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (astrologer.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: themeService.primaryColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Stats in one line - compact format
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: themeService.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${astrologer.rating} • ${astrologer.experience}y • ${formatNumber(astrologer.totalConsultations)}',
                            style: TextStyle(
                              color: themeService.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Top specializations (max 3)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: astrologer.specializations.take(3).map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeService.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                color: themeService.primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Message button - pill shaped like profile page
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeService.primaryColor,
                        themeService.primaryColor.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100), // Pill shape
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onChatTap();
                      },
                      borderRadius: BorderRadius.circular(100), // Pill shape
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline, // Same icon as profile page
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Message',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

