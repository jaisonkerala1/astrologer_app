import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/clients_bloc.dart';
import '../bloc/clients_event.dart';
import '../bloc/clients_state.dart';
import '../widgets/client_card_widget.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_filter_chips.dart';
import '../widgets/clients_skeleton_loader.dart';

/// My Clients Screen - Beautiful, modern UI for client management
/// Shows all past clients with search and filter capabilities
/// Uses BLoC for state management with two-phase loading pattern
class MyClientsScreen extends StatelessWidget {
  const MyClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClientsBloc>()..add(const LoadClientsEvent()),
      child: const _MyClientsScreenContent(),
    );
  }
}

class _MyClientsScreenContent extends StatefulWidget {
  const _MyClientsScreenContent();

  @override
  State<_MyClientsScreenContent> createState() => _MyClientsScreenContentState();
}

class _MyClientsScreenContentState extends State<_MyClientsScreenContent>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeService.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'My Clients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: () => _showSortOptions(context, themeService),
              ),
            ],
          ),
          body: BlocBuilder<ClientsBloc, ClientsState>(
            builder: (context, state) {
              // Show full loading only on initial load with no cache
              if (state is ClientsLoading) {
                return const ClientsSkeletonLoader();
              }

              // Show error state
              if (state is ClientsError) {
                return _buildErrorState(context, themeService, state.message);
              }

              // Show loaded state
              if (state is ClientsLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ClientsBloc>().add(const RefreshClientsEvent());
                    // Wait for refresh to complete
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: themeService.primaryColor,
                  child: Column(
                    children: [
                      // Search Bar
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: ClientSearchBar(
                            onSearch: (query) {
                              context.read<ClientsBloc>().add(SearchClientsEvent(query));
                            },
                            onClear: () {
                              context.read<ClientsBloc>().add(const SearchClientsEvent(''));
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Filter Chips
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClientFilterChips(
                          selectedFilter: _mapFilterToEnum(state.activeFilter),
                          onFilterChanged: (filter) {
                            context.read<ClientsBloc>().add(
                                  FilterClientsEvent(_mapEnumToFilter(filter)),
                                );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Results count with subtle refresh indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${state.displayedCount} ${state.displayedCount == 1 ? 'Client' : 'Clients'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: themeService.textSecondary,
                              ),
                            ),
                            if (state.hasFilters) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(Filtered)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.textHint,
                                ),
                              ),
                            ],
                            if (state.isRefreshing) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    themeService.primaryColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Clients List
                      Expanded(
                        child: state.displayedClients.isEmpty
                            ? _buildEmptyState(themeService, state.searchQuery)
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.displayedClients.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(
                                          milliseconds: 300 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: ClientCardWidget(
                                              client: state.displayedClients[index],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }

              // Initial state (shouldn't happen but handle it)
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeService themeService, String searchQuery) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                size: 60,
                color: themeService.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isNotEmpty ? 'No clients found' : 'No clients yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Your client list will appear here after consultations',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, ThemeService themeService, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: themeService.errorColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load clients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: themeService.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ClientsBloc>().add(const LoadClientsEvent(forceRefresh: true));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: themeService.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
              ),

              const Divider(height: 1),

              // Sort options
              _buildSortOption(
                context: context,
                modalContext: modalContext,
                icon: Icons.access_time,
                title: 'Last Consultation',
                subtitle: 'Most recent first',
                themeService: themeService,
                sortOption: ClientSortOption.lastConsultation,
              ),
              _buildSortOption(
                context: context,
                modalContext: modalContext,
                icon: Icons.sort_by_alpha,
                title: 'Name (A-Z)',
                subtitle: 'Alphabetical order',
                themeService: themeService,
                sortOption: ClientSortOption.nameAZ,
              ),
              _buildSortOption(
                context: context,
                modalContext: modalContext,
                icon: Icons.event_note,
                title: 'Total Consultations',
                subtitle: 'Most consultations first',
                themeService: themeService,
                sortOption: ClientSortOption.totalConsultations,
              ),
              _buildSortOption(
                context: context,
                modalContext: modalContext,
                icon: Icons.attach_money,
                title: 'Total Spent',
                subtitle: 'Highest amount first',
                themeService: themeService,
                sortOption: ClientSortOption.totalSpent,
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required BuildContext modalContext,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeService themeService,
    required ClientSortOption sortOption,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(modalContext);
          context.read<ClientsBloc>().add(SortClientsEvent(sortOption));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: themeService.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: themeService.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: themeService.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods to convert between enum and string
  ClientFilter _mapFilterToEnum(String filter) {
    switch (filter) {
      case 'recent':
        return ClientFilter.recent;
      case 'frequent':
        return ClientFilter.frequent;
      case 'vip':
        return ClientFilter.vip;
      default:
        return ClientFilter.all;
    }
  }

  String _mapEnumToFilter(ClientFilter filter) {
    switch (filter) {
      case ClientFilter.recent:
        return 'recent';
      case ClientFilter.frequent:
        return 'frequent';
      case ClientFilter.vip:
        return 'vip';
      default:
        return 'all';
    }
  }
}
