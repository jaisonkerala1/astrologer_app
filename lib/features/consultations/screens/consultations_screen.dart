import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../bloc/consultations_state.dart';
import '../models/consultation_model.dart';
import '../widgets/consultation_card_widget.dart';
import '../widgets/consultation_stats_widget.dart';
import '../widgets/consultation_filter_widget.dart';
import '../widgets/add_consultation_form.dart';
import '../widgets/consultation_search_bar.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ConsultationsBloc>().add(const LoadConsultationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Consultations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<ConsultationsBloc, ConsultationsState>(
        listener: (context, state) {
          if (state is ConsultationsError) {
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
          }
        },
        builder: (context, state) {
          if (state is ConsultationsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ConsultationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load consultations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.5),
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
                  ),
                ],
              ),
            );
          }

          if (state is ConsultationsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ConsultationsBloc>().add(const RefreshConsultationsEvent());
              },
              child: Column(
                children: [
                  // Search bar
                  ConsultationSearchBar(
                    searchQuery: state.searchQuery,
                    isSearching: state.isSearching,
                    onSearchChanged: (query) {
                      context.read<ConsultationsBloc>().add(
                        SearchConsultationsEvent(query: query),
                      );
                    },
                    onClearSearch: () {
                      context.read<ConsultationsBloc>().add(
                        const ClearSearchEvent(),
                      );
                    },
                    onSearchSubmitted: () {
                      // Search is handled in real-time, no need for submission
                    },
                  ),
                  
                  // Search results indicator
                  SearchResultsIndicator(
                    resultCount: state.consultations.length,
                    searchQuery: state.searchQuery,
                    isSearching: state.isSearching,
                  ),
                  
                  // Stats section (only show when not searching)
                  if (!state.isSearching) ...[
                    ConsultationStatsWidget(
                      todayCount: state.todayCount,
                      todayEarnings: state.todayEarnings,
                      nextConsultation: state.nextConsultation,
                    ),
                    
                    // Filter section
                    ConsultationFilterWidget(
                      selectedStatus: state.activeFilter,
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
                  
                  // Consultations list
                  Expanded(
                    child: state.consultations.isEmpty
                        ? (state.isSearching && state.searchQuery.isNotEmpty
                            ? SearchEmptyState(
                                searchQuery: state.searchQuery,
                                onClearSearch: () {
                                  context.read<ConsultationsBloc>().add(
                                    const ClearSearchEvent(),
                                  );
                                },
                              )
                            : _buildEmptyState(context))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: state.consultations.length,
                            itemBuilder: (context, index) {
                              final consultation = state.consultations[index];
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
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConsultationDialog(context),
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppTheme.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No consultations found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first consultation to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Phone', consultation.clientPhone),
            _buildDetailRow('Type', consultation.type.displayName),
            _buildDetailRow('Duration', '${consultation.duration} minutes'),
            _buildDetailRow('Amount', '₹${consultation.amount.toStringAsFixed(0)}'),
            _buildDetailRow('Status', consultation.status.displayName),
            if (consultation.notes != null && consultation.notes!.isNotEmpty)
              _buildDetailRow('Notes', consultation.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
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
