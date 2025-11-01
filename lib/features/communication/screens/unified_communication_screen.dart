import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/communication_item.dart';
import '../widgets/communication_filter_chip.dart';
import '../widgets/communication_item_card.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';
import 'chat_screen.dart';
import 'video_call_screen.dart';
import 'dialer_screen.dart';
import '../../../shared/widgets/empty_states/empty_state_widget.dart';
import '../../../shared/widgets/empty_states/illustrations/communication_empty_illustration.dart';
import '../../../shared/widgets/empty_states/illustrations/calls_empty_illustration.dart';
import '../../../shared/widgets/empty_states/illustrations/video_call_empty_illustration.dart';

/// World-class unified communication screen (Instagram-inspired)
/// 
/// ✨ FEATURES:
/// - BLoC architecture for state management
/// - Pull-to-refresh
/// - Real-time search
/// - Filter chips (All, Calls, Messages, Video)
/// - Graceful fallback to dummy data
/// - Professional loading states
class UnifiedCommunicationScreen extends StatefulWidget {
  const UnifiedCommunicationScreen({super.key});

  @override
  State<UnifiedCommunicationScreen> createState() => _UnifiedCommunicationScreenState();
}

class _UnifiedCommunicationScreenState extends State<UnifiedCommunicationScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Load communications via BLoC
    context.read<CommunicationBloc>().add(const LoadCommunicationsEvent());
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _toggleSearch() {
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
    final themeService = Provider.of<ThemeService>(context);
    
    return BlocConsumer<CommunicationBloc, CommunicationState>(
      listener: (context, state) {
        // Show success messages
        if (state is CommunicationLoadedState && state.successMessage != null) {
          _showSnackBar(state.successMessage!);
        }
        
        // Show error messages
        if (state is CommunicationErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: _buildAppBar(themeService, state),
          body: Column(
            children: [
              // Filter chips row
              _buildFilterChips(themeService, state),
              
              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeService.borderColor.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: _buildContent(themeService, state),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(themeService, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeService themeService, CommunicationState state) {
    return AppBar(
      backgroundColor: themeService.backgroundColor,
      elevation: 0,
      titleSpacing: 16, // WhatsApp-style left spacing
      title: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Row(
            children: [
              // Title (fades out when searching)
              if (!_isSearching)
                Opacity(
                  opacity: 1.0 - _searchAnimation.value,
                  child: Text(
                    'Communication',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              
              // Search bar (expands when searching)
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
                            color: themeService.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: themeService.borderColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: themeService.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search conversations...',
                              hintStyle: TextStyle(
                                color: themeService.textHint,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 6),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: themeService.textHint,
                                  size: 20,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
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
        // Search button (becomes close when searching)
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              key: ValueKey<bool>(_isSearching),
              color: themeService.textPrimary,
              size: 24,
            ),
          ),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeService themeService, CommunicationState state) {
    if (state is! CommunicationLoadedState) {
      return const SizedBox(height: 60);
    }
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CommunicationFilterChip(
            filter: CommunicationFilter.all,
            isActive: state.activeFilter == CommunicationFilter.all,
            count: state.getCountForFilter(CommunicationFilter.all),
            themeService: themeService,
            onTap: () => _onFilterTap(CommunicationFilter.all),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.calls,
            isActive: state.activeFilter == CommunicationFilter.calls,
            count: state.getCountForFilter(CommunicationFilter.calls),
            themeService: themeService,
            onTap: () => _onFilterTap(CommunicationFilter.calls),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.messages,
            isActive: state.activeFilter == CommunicationFilter.messages,
            count: state.getCountForFilter(CommunicationFilter.messages),
            themeService: themeService,
            onTap: () => _onFilterTap(CommunicationFilter.messages),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.video,
            isActive: state.activeFilter == CommunicationFilter.video,
            count: state.getCountForFilter(CommunicationFilter.video),
            themeService: themeService,
            onTap: () => _onFilterTap(CommunicationFilter.video),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeService themeService, CommunicationState state) {
    // Loading state
    if (state is CommunicationLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading communications...',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (state is CommunicationErrorState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: themeService.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load communications',
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CommunicationBloc>().add(const RefreshCommunicationsEvent());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loaded state
    if (state is CommunicationLoadedState) {
      var communications = state.filteredCommunications;
      
      // Apply search filter if searching
      if (_isSearching && _searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        communications = communications.where((item) {
          return item.contactName.toLowerCase().contains(query) ||
                 item.preview.toLowerCase().contains(query);
        }).toList();
      }

      if (communications.isEmpty) {
        return _buildEmptyState(themeService, state);
      }

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<CommunicationBloc>().add(const RefreshCommunicationsEvent());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: themeService.primaryColor,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey('${state.activeFilter}_${_searchController.text}'),
                padding: const EdgeInsets.all(16),
                itemCount: communications.length,
                itemBuilder: (context, index) {
                  final item = communications[index];
                  return CommunicationItemCard(
                    item: item,
                    themeService: themeService,
                    onTap: () => _onItemTap(item),
                  );
                },
              ),
            ),
          ),
          
          // Subtle refresh indicator at top (Instagram/WhatsApp-style)
          if (state.isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeService.primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Default state
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(ThemeService themeService, CommunicationLoadedState state) {
    String title;
    String message;
    Widget illustration;
    
    // Check if empty due to search
    if (_isSearching && _searchController.text.isNotEmpty) {
      title = 'No Results Found';
      message = 'Try a different search term or filter.';
      illustration = CommunicationEmptyIllustration(themeService: themeService);
    } else {
      // Filter-specific messages AND illustrations
      switch (state.activeFilter) {
        case CommunicationFilter.all:
          title = 'No Conversations';
          message = 'Your inbox is quiet for now!\nMessages and calls will appear here.';
          illustration = CommunicationEmptyIllustration(themeService: themeService);
          break;
        case CommunicationFilter.calls:
          title = 'No Voice Calls';
          message = 'Ready to connect!\nYour call history will show up here.';
          illustration = CallsEmptyIllustration(themeService: themeService);
          break;
        case CommunicationFilter.messages:
          title = 'No Messages';
          message = 'Start a conversation!\nYour messages will appear here.';
          illustration = CommunicationEmptyIllustration(themeService: themeService);
          break;
        case CommunicationFilter.video:
          title = 'No Video Calls';
          message = 'Face-to-face consultations!\nVideo call history will display here.';
          illustration = VideoCallEmptyIllustration(themeService: themeService);
          break;
      }
    }

    return EmptyStateWidget(
      illustration: illustration,
      title: title,
      message: message,
      themeService: themeService,
    );
  }

  Widget _buildFAB(ThemeService themeService, CommunicationState state) {
    if (state is! CommunicationLoadedState) {
      return const SizedBox.shrink();
    }
    
    // Different FAB based on active filter
    IconData icon;
    String tooltip;
    VoidCallback onPressed;
    
    switch (state.activeFilter) {
      case CommunicationFilter.all:
        // Speed dial for all options
        return _buildSpeedDial(themeService);
      case CommunicationFilter.calls:
        icon = Icons.dialpad_rounded;
        tooltip = 'Make a call';
        onPressed = _showDialer;
        break;
      case CommunicationFilter.messages:
        icon = Icons.message_rounded;
        tooltip = 'New message';
        onPressed = _showNewMessage;
        break;
      case CommunicationFilter.video:
        icon = Icons.videocam_rounded;
        tooltip = 'Video call';
        onPressed = _showVideoCallPicker;
        break;
    }

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: themeService.primaryColor,
        tooltip: tooltip,
        elevation: 4,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSpeedDial(ThemeService themeService) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'New Communication',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildActionTile(
                  icon: Icons.phone_rounded,
                  label: 'Voice Call',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    _showDialer();
                  },
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.videocam_rounded,
                  label: 'Video Call',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    _showVideoCallPicker();
                  },
                  themeService: themeService,
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.message_rounded,
                  label: 'Message',
                  color: themeService.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    _showNewMessage();
                  },
                  themeService: themeService,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      backgroundColor: themeService.primaryColor,
      elevation: 4,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return Material(
      color: themeService.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeService.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFilterTap(CommunicationFilter filter) {
    context.read<CommunicationBloc>().add(FilterCommunicationsEvent(filter));
    _fabAnimationController.forward().then((_) => _fabAnimationController.reverse());
  }

  void _onItemTap(CommunicationItem item) {
    final state = context.read<CommunicationBloc>().state;
    
    if (state is! CommunicationLoadedState) return;
    
    // Instagram-style behavior:
    // - In "All" filter: Always open chat (user chooses action from there)
    // - In specific filters: Direct action
    
    if (state.activeFilter == CommunicationFilter.all) {
      // Always go to chat in unified "All" view
      _openChat(item.contactName);
    } else {
      // In filtered view, do specific action based on type
      switch (item.type) {
        case CommunicationType.message:
          _openChat(item.contactName);
          break;
        case CommunicationType.voiceCall:
          _makeCall(item.contactName);
          break;
        case CommunicationType.videoCall:
          _startVideoCall(item.contactName);
          break;
      }
    }
  }
  
  void _openChat(String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactName: contactName),
      ),
    );
  }
  
  void _makeCall(String contactName) {
    _showSnackBar('Calling $contactName...');
    // TODO: Implement actual voice call
  }
  
  void _startVideoCall(String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          contactName: contactName,
          isIncoming: false,
        ),
      ),
    );
  }

  void _showDialer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DialerScreen(),
    );
  }

  void _showNewMessage() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeService.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'New Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a contact to start messaging',
              style: TextStyle(color: themeService.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Show contact picker
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Choose Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showVideoCallPicker() {
    _showSnackBar('Video call picker coming soon');
  }

  void _showSnackBar(String message) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

