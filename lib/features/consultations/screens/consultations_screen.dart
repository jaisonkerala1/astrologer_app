import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../bloc/consultations_state.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_card_widget.dart';
import '../widgets/consultation_stats_widget.dart';
import '../widgets/consultation_filter_widget.dart';
import '../widgets/add_consultation_form.dart';
// Removed inline search bar in favor of AppBar-integrated search
import '../widgets/consultation_list_skeleton.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _refreshAnimationController;
  bool _isRefreshing = false;
  // AppBar search state
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    context.read<ConsultationsBloc>().add(const LoadConsultationsEvent());
  }

  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch

  @override
  void dispose() {
    _refreshAnimationController.dispose();
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
        context.read<ConsultationsBloc>().add(const ClearSearchEvent());
      }
    });
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
                          'Consultations',
                          style: TextStyle(
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
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search consultations...',
                                    hintStyle: TextStyle(
                                      color: Colors.black45,
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
                                        color: Colors.black45,
                                        size: 20,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    context.read<ConsultationsBloc>().add(
                                      SearchConsultationsEvent(query: value),
                                    );
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
                IconButton(
                  icon: AnimatedBuilder(
                    animation: _refreshAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshAnimationController.value * 2 * 3.14159,
                      child: const Icon(Icons.refresh, color: Colors.white),
                      );
                    },
                  ),
                  onPressed: _isRefreshing ? null : () {
                    _handleRefresh();
                  },
                ),
            ],
          ),
      body: BlocConsumer<ConsultationsBloc, ConsultationsState>(
        listener: (context, state) {
          if (state is ConsultationsError) {
            _stopRefreshAnimation();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ConsultationUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Consultation updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ConsultationsLoaded) {
            _stopRefreshAnimation();
          }
        },
        builder: (context, state) {
          // Always show the UI structure, only data loading changes
          final isLoading = state is ConsultationsLoading;
          final isError = state is ConsultationsError;
          final loadedState = state is ConsultationsLoaded ? state : null;

          if (isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: themeService.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load consultations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeService.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeService.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ConsultationsBloc>().add(const LoadConsultationsEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
                },
                child: Column(
                  children: [
                    // Removed inline search bar; using AppBar-integrated search
                    
                    // Stats section (only show when not searching) - shows loading state
                    if (loadedState == null || !loadedState.isSearching) ...[
                      ConsultationStatsWidget(
                        todayCount: loadedState?.todayCount ?? 0,
                        todayEarnings: loadedState?.todayEarnings ?? 0.0,
                        nextConsultation: loadedState?.nextConsultation,
                        isLoading: isLoading,
                      ),
                  
                  // Filter section - always visible
                  ConsultationFilterWidget(
                    selectedStatus: loadedState?.activeFilter,
                    onStatusChanged: (status) {
                      context.read<ConsultationsBloc>().add(
                        FilterConsultationsEvent(statusFilter: status),
                      );
                    },
                    onClearFilters: () {
                      context.read<ConsultationsBloc>().add(
                        const FilterConsultationsEvent(),
                      );
                    },
                  ),
                ],
                
                // Consultations list - shows skeleton when loading
                Expanded(
                  child: isLoading
                      ? const ConsultationListSkeleton()
                      : (loadedState?.consultations.isEmpty ?? true)
                          ? (loadedState?.isSearching == true && (loadedState?.searchQuery.isNotEmpty ?? false)
                              ? _buildSearchEmptyState(context, loadedState!.searchQuery)
                              : _buildEmptyState(context))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: loadedState!.consultations.length,
                              itemBuilder: (context, index) {
                                final consultation = loadedState.consultations[index];
                                return ConsultationCardWidget(
                                  key: ValueKey(consultation.id),
                                  consultation: consultation,
                                  onStart: () => _startConsultation(context, consultation.id),
                                  onComplete: () => _completeConsultation(context, consultation),
                                  onCancel: () => _cancelConsultation(context, consultation.id),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
              
              // Subtle refresh indicator at top (Instagram/WhatsApp-style)
              if (loadedState?.isRefreshing == true)
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
        },
      ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddConsultationDialog(context),
            backgroundColor: themeService.primaryColor,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildSearchEmptyState(BuildContext context, String query) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: themeService.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results for "$query"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeService.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different keyword or clear the search.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeService.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<ConsultationsBloc>().add(const ClearSearchEvent());
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Clear search'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeService.textPrimary,
                    side: BorderSide(color: themeService.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _handleRefresh() {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshAnimationController.repeat();
    context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
  }

  void _stopRefreshAnimation() {
    if (_isRefreshing) {
      setState(() {
        _isRefreshing = false;
      });
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 64,
                color: themeService.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'No consultations found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeService.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first consultation to get started',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeService.textHint,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConsultationDetails(BuildContext context, ConsultationModel consultation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConsultationDetailsSheet(consultation),
    );
  }

  Widget _buildConsultationDetailsSheet(ConsultationModel consultation) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            border: Border.all(color: themeService.borderColor),
            boxShadow: [themeService.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        consultation.clientName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: themeService.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Phone', consultation.clientPhone, themeService),
                _buildDetailRow('Type', consultation.type.displayName, themeService),
                _buildDetailRow('Duration', '${consultation.duration} minutes', themeService),
                _buildDetailRow('Amount', '₹${consultation.amount.toStringAsFixed(0)}', themeService),
                _buildDetailRow('Status', consultation.status.displayName, themeService),
                if (consultation.notes != null && consultation.notes!.isNotEmpty)
                  _buildDetailRow('Notes', consultation.notes!, themeService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: themeService.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: themeService.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startConsultation(BuildContext context, String consultationId) {
    context.read<ConsultationsBloc>().add(
      StartConsultationEvent(consultationId: consultationId),
    );
  }

  void _completeConsultation(BuildContext context, ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => _buildCompleteConsultationDialog(consultation),
    );
  }

  Widget _buildCompleteConsultationDialog(ConsultationModel consultation) {
    final notesController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Complete Consultation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete consultation with ${consultation.clientName}?'),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ConsultationsBloc>().add(
              CompleteConsultationEvent(
                consultationId: consultation.id,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  void _cancelConsultation(BuildContext context, String consultationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text('Are you sure you want to cancel this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ConsultationsBloc>().add(
                CancelConsultationEvent(consultationId: consultationId),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddConsultationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddConsultationForm(
        onSubmit: (consultation) {
          Navigator.pop(context);
          context.read<ConsultationsBloc>().add(
            AddConsultationEvent(consultation: consultation),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
