import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/di/service_locator.dart';
import '../screens/service_management_screen.dart';
import '../screens/service_requests_screen.dart';
import '../bloc/heal_bloc.dart';
import '../bloc/heal_event.dart';

class HealScreen extends StatefulWidget {
  const HealScreen({super.key});

  @override
  State<HealScreen> createState() => _HealScreenState();
}

class _HealScreenState extends State<HealScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch(ThemeService themeService) {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    
    return BlocProvider(
      create: (context) => getIt<HealBloc>()..add(const LoadServicesEvent()),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Scaffold(
            backgroundColor: themeService.backgroundColor,
            appBar: AppBar(
            backgroundColor: themeService.primaryColor,
            elevation: 0,
            titleSpacing: 16,
            title: AnimatedBuilder(
              animation: _searchAnimation,
              builder: (context, child) {
                return Row(
                  children: [
                    if (!_isSearching)
                      Opacity(
                        opacity: 1.0 - _searchAnimation.value,
                        child: Text(
                          l10n.heal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    if (_isSearching)
                      Expanded(
                        child: FadeTransition(
                          opacity: _searchAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.0),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Search services...',
                                    hintStyle: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: 8, right: 6),
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.black45,
                                        size: 20,
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    key: ValueKey<bool>(_isSearching),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => _toggleSearch(themeService),
              ),
              if (!_isSearching)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'manage_services') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceManagementScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'manage_services',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: themeService.primaryColor),
                          const SizedBox(width: 8),
                          Text(l10n.manageServices),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ServiceRequestsScreen(searchQuery: _searchController.text),
        );
      },
    ),
    );
  }
}
