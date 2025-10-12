import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services/communication_service.dart';
import '../models/communication_item.dart';
import '../widgets/communication_filter_chip.dart';
import '../widgets/communication_item_card.dart';
import 'chat_screen.dart';
import 'video_call_screen.dart';
import 'dialer_screen.dart';

/// World-class unified communication screen (Instagram-inspired)
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
    return Consumer2<ThemeService, CommunicationService>(
      builder: (context, themeService, commService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: _buildAppBar(themeService, commService),
          body: Column(
            children: [
              // Filter chips row
              _buildFilterChips(themeService, commService),
              
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
                child: _buildContent(themeService, commService),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(themeService, commService),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeService themeService, CommunicationService commService) {
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
        
        // More options (hide when searching)
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
            color: themeService.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            switch (value) {
              case 'test_message':
                commService.simulateNewMessage();
                _showSnackBar('Simulated new message');
                break;
              case 'test_call':
                commService.simulateMissedCall();
                _showSnackBar('Simulated missed call');
                break;
              case 'reset':
                commService.resetUnreadCounts();
                _showSnackBar('Reset all badges');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'test_message',
              child: Row(
                children: [
                  Icon(Icons.message_rounded),
                  SizedBox(width: 12),
                  Text('Test New Message'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test_call',
              child: Row(
                children: [
                  Icon(Icons.phone_rounded),
                  SizedBox(width: 12),
                  Text('Test Missed Call'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded),
                  SizedBox(width: 12),
                  Text('Reset Badges'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeService themeService, CommunicationService commService) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CommunicationFilterChip(
            filter: CommunicationFilter.all,
            isActive: commService.activeFilter == CommunicationFilter.all,
            count: commService.getCountForFilter(CommunicationFilter.all),
            themeService: themeService,
            onTap: () => _onFilterTap(commService, CommunicationFilter.all),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.calls,
            isActive: commService.activeFilter == CommunicationFilter.calls,
            count: commService.getCountForFilter(CommunicationFilter.calls),
            themeService: themeService,
            onTap: () => _onFilterTap(commService, CommunicationFilter.calls),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.messages,
            isActive: commService.activeFilter == CommunicationFilter.messages,
            count: commService.getCountForFilter(CommunicationFilter.messages),
            themeService: themeService,
            onTap: () => _onFilterTap(commService, CommunicationFilter.messages),
          ),
          const SizedBox(width: 8),
          CommunicationFilterChip(
            filter: CommunicationFilter.video,
            isActive: commService.activeFilter == CommunicationFilter.video,
            count: commService.getCountForFilter(CommunicationFilter.video),
            themeService: themeService,
            onTap: () => _onFilterTap(commService, CommunicationFilter.video),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeService themeService, CommunicationService commService) {
    var communications = commService.filteredCommunications;
    
    // Apply search filter if searching
    if (_isSearching && _searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      communications = communications.where((item) {
        return item.contactName.toLowerCase().contains(query) ||
               item.preview.toLowerCase().contains(query);
      }).toList();
    }

    if (communications.isEmpty) {
      return _buildEmptyState(themeService, commService);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        key: ValueKey('${commService.activeFilter}_${_searchController.text}'),
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
    );
  }

  Widget _buildEmptyState(ThemeService themeService, CommunicationService commService) {
    String message;
    IconData icon;
    
    // Check if empty due to search
    if (_isSearching && _searchController.text.isNotEmpty) {
      message = 'No results found';
      icon = Icons.search_off_rounded;
    } else {
      switch (commService.activeFilter) {
        case CommunicationFilter.all:
          message = 'No communications yet';
          icon = Icons.forum_rounded;
          break;
        case CommunicationFilter.calls:
          message = 'No calls yet';
          icon = Icons.phone_rounded;
          break;
        case CommunicationFilter.messages:
          message = 'No messages yet';
          icon = Icons.message_rounded;
          break;
        case CommunicationFilter.video:
          message = 'No video calls yet';
          icon = Icons.videocam_rounded;
          break;
      }
    }

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
              icon,
              size: 56,
              color: themeService.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation',
            style: TextStyle(
              color: themeService.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ThemeService themeService, CommunicationService commService) {
    // Different FAB based on active filter
    IconData icon;
    String tooltip;
    VoidCallback onPressed;
    
    switch (commService.activeFilter) {
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

  void _onFilterTap(CommunicationService commService, CommunicationFilter filter) {
    commService.setFilter(filter);
    _fabAnimationController.forward().then((_) => _fabAnimationController.reverse());
  }

  void _onItemTap(CommunicationItem item) {
    final commService = Provider.of<CommunicationService>(context, listen: false);
    
    // Instagram-style behavior:
    // - In "All" filter: Always open chat (user chooses action from there)
    // - In specific filters: Direct action
    
    if (commService.activeFilter == CommunicationFilter.all) {
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

