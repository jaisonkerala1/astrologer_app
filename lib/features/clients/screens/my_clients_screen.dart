import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/client_model.dart';
import '../widgets/client_card_widget.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_filter_chips.dart';
import '../widgets/client_stats_widget.dart';
import '../widgets/clients_skeleton_loader.dart';

/// My Clients Screen - Beautiful, modern UI for client management
/// Shows all past clients with search and filter capabilities
class MyClientsScreen extends StatefulWidget {
  const MyClientsScreen({super.key});

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data
  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  ClientFilter _selectedFilter = ClientFilter.all;
  String _searchQuery = '';
  bool _isLoading = true;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Load mock data
    _loadClients();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _allClients = MockClientsData.getMockClients();
      _filteredClients = _allClients;
      _isLoading = false;
    });

    _animationController.forward();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void _onFilterChanged(ClientFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<ClientModel> filtered = _allClients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        return client.clientName.toLowerCase().contains(_searchQuery) ||
            client.clientPhone.toLowerCase().contains(_searchQuery) ||
            (client.clientEmail?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case ClientFilter.recent:
        filtered = filtered.where((client) => client.isRecent).toList();
        break;
      case ClientFilter.frequent:
        filtered = filtered.where((client) => client.isFrequent).toList();
        break;
      case ClientFilter.vip:
        filtered = filtered.where((client) => client.isVIP).toList();
        break;
      case ClientFilter.all:
      default:
        break;
    }

    // Sort by last consultation (most recent first)
    filtered.sort((a, b) => b.lastConsultation.compareTo(a.lastConsultation));

    setState(() {
      _filteredClients = filtered;
    });
  }

  Future<void> _onRefresh() async {
    await _loadClients();
  }

  @override
  Widget build(BuildContext context) {
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
              // Sort/Filter button
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: () {
                  _showSortOptions(themeService);
                },
              ),
            ],
          ),
          body: _isLoading
              ? const ClientsSkeletonLoader()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: themeService.primaryColor,
                  child: Column(
                    children: [
                      // Search Bar
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: ClientSearchBar(
                            onSearch: _onSearchChanged,
                            onClear: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Filter Chips
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClientFilterChips(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: _onFilterChanged,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Results count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredClients.length} ${_filteredClients.length == 1 ? 'Client' : 'Clients'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: themeService.textSecondary,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _selectedFilter != ClientFilter.all) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(Filtered)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.textHint,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Clients List
                      Expanded(
                        child: _filteredClients.isEmpty
                            ? _buildEmptyState(themeService)
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredClients.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(
                                          milliseconds: 300 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset:
                                              Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: ClientCardWidget(
                                              client: _filteredClients[index],
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
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeService themeService) {
    return Center(
      child: Column(
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
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 60,
              color: themeService.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No clients found'
                : 'No clients yet',
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
              _searchQuery.isNotEmpty
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
    );
  }

  void _showSortOptions(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                icon: Icons.access_time,
                title: 'Last Consultation',
                subtitle: 'Most recent first',
                themeService: themeService,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredClients.sort((a, b) =>
                        b.lastConsultation.compareTo(a.lastConsultation));
                  });
                },
              ),
              _buildSortOption(
                icon: Icons.sort_by_alpha,
                title: 'Name (A-Z)',
                subtitle: 'Alphabetical order',
                themeService: themeService,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredClients.sort(
                        (a, b) => a.clientName.compareTo(b.clientName));
                  });
                },
              ),
              _buildSortOption(
                icon: Icons.event_note,
                title: 'Total Consultations',
                subtitle: 'Most consultations first',
                themeService: themeService,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredClients.sort((a, b) =>
                        b.totalConsultations.compareTo(a.totalConsultations));
                  });
                },
              ),
              _buildSortOption(
                icon: Icons.attach_money,
                title: 'Total Spent',
                subtitle: 'Highest amount first',
                themeService: themeService,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredClients
                        .sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
                  });
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeService themeService,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
}

