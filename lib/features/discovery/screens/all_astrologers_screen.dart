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

/// All Astrologers screen with premium design
class AllAstrologersScreen extends StatefulWidget {
  const AllAstrologersScreen({super.key});

  @override
  State<AllAstrologersScreen> createState() => _AllAstrologersScreenState();
}

class _AllAstrologersScreenState extends State<AllAstrologersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSort = 'online';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _sortOptions = [
    {'label': 'Online Now', 'value': 'online', 'icon': Icons.circle},
    {'label': 'Top Rated', 'value': 'rating', 'icon': Icons.star_rounded},
    {'label': 'Most Experienced', 'value': 'experience', 'icon': Icons.workspace_premium_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sortOptions.length, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    context.read<DiscoveryBloc>().add(const LoadAstrologersEvent(onlineOnly: true));
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final value = _sortOptions[_tabController.index]['value'];
      setState(() {
        _selectedSort = value;
      });
      _applySort();
    }
  }

  void _applySort() {
    final bloc = context.read<DiscoveryBloc>();
    if (_selectedSort == 'online') {
      bloc.add(const LoadAstrologersEvent(onlineOnly: true));
    } else {
      bloc.add(LoadAstrologersEvent(sortBy: _selectedSort));
    }
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
                      Icons.people_rounded,
                      color: themeService.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Astrologers',
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
                  'Find your perfect astrology expert',
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
          final isSelected = _tabController.index == index;

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
                    : themeService.cardColor,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
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
                  Icon(
                    option['icon'],
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : themeService.textSecondary,
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
    return RefreshIndicator(
      color: themeService.primaryColor,
      onRefresh: () async {
        context.read<DiscoveryBloc>().add(const RefreshAstrologersEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: astrologers.length,
        itemBuilder: (context, index) {
          final astrologer = astrologers[index];
          
          return _PremiumRowCard(
            astrologer: astrologer,
            themeService: themeService,
            onTap: () {
              HapticFeedback.selectionClick();
            },
            onChatTap: () {
              HapticFeedback.mediumImpact();
              _showChatSnackbar(themeService, astrologer.name);
            },
            formatNumber: _formatNumber,
          );
        },
      ),
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
              Icons.person_search_rounded,
              size: 80,
              color: themeService.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No astrologers found',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
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

/// Minimal astrologer card - exact V1 style
class _PremiumRowCard extends StatelessWidget {
  final DiscoveryAstrologer astrologer;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onChatTap;
  final String Function(int) formatNumber;

  const _PremiumRowCard({
    required this.astrologer,
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

