import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/simple_shimmer.dart';
import '../models/help_article.dart';
import '../bloc/help_support_bloc.dart';
import '../bloc/help_support_event.dart';
import '../bloc/help_support_state.dart';
import 'documentation_screen.dart';
import 'faq_screen.dart';
import 'ticket_screen.dart';
import '../../chat/widgets/floating_chat_button.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../core/services/storage_service.dart';
import 'dart:convert';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storageService = StorageService();
  
  String _searchQuery = '';
  AstrologerModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    // Dispatch BLoC event to load all help & support data
    context.read<HelpSupportBloc>().add(const LoadHelpArticlesEvent());
    context.read<HelpSupportBloc>().add(const LoadUserTicketsEvent());
    print('📘 [HelpSupportScreen] Dispatched load events');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        setState(() {
          _currentUser = AstrologerModel.fromJson(userDataMap);
        });
      }
    } catch (e) {
      print('⚠️ [HelpSupportScreen] Error loading user data: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onRefresh() {
    print('📘 [HelpSupportScreen] Refreshing help & support data');
    context.read<HelpSupportBloc>().add(const RefreshHelpSupportEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocBuilder<HelpSupportBloc, HelpSupportState>(
          builder: (context, state) {
            // Extract data from state
            final isLoading = state is HelpSupportLoading;
            final helpArticles = state is HelpSupportLoadedState ? state.helpArticles : <HelpArticle>[];
            final faqItems = state is HelpSupportLoadedState ? state.faqItems : <FAQItem>[];
            final userTickets = state is HelpSupportLoadedState ? state.tickets : <SupportTicket>[];

            print('📘 [HelpSupportScreen] State: ${state.runtimeType}, Articles: ${helpArticles.length}, FAQs: ${faqItems.length}, Tickets: ${userTickets.length}');

            return Scaffold(
              backgroundColor: themeService.backgroundColor,
              appBar: AppBar(
                title: const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: themeService.primaryColor,
                elevation: 0,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Documentation', icon: Icon(Icons.article, size: 20)),
                    Tab(text: 'FAQ', icon: Icon(Icons.help_outline, size: 20)),
                    Tab(text: 'Tickets', icon: Icon(Icons.support_agent, size: 20)),
                  ],
                ),
              ),
              floatingActionButton: FloatingChatButton(userProfile: _currentUser),
              body: TabBarView(
                controller: _tabController,
                children: [
                  DocumentationScreen(
                    helpArticles: helpArticles,
                    isLoading: isLoading,
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                  ),
                  FAQScreen(
                    faqItems: faqItems,
                    isLoading: isLoading,
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                  ),
                  TicketScreen(
                    userTickets: userTickets,
                    isLoading: isLoading,
                    onRefresh: _onRefresh,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Quick help card widget
class QuickHelpCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const QuickHelpCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? themeService.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? themeService.primaryColor,
                    size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeService.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}

/// Search bar widget
class HelpSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const HelpSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton for help content
class HelpContentSkeleton extends StatelessWidget {
  const HelpContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerContainer(
                width: double.infinity,
                height: 20,
                borderRadius: 4,
              ),
              const SizedBox(height: 12),
              ShimmerContainer(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              ShimmerContainer(
                width: 200,
                height: 16,
                borderRadius: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ShimmerContainer(
                    width: 60,
                    height: 24,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 8),
                  ShimmerContainer(
                    width: 80,
                    height: 24,
                    borderRadius: 12,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
