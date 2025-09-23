import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';

class ServiceRequestNotesWidget extends StatefulWidget {
  final ServiceRequest request;

  const ServiceRequestNotesWidget({super.key, required this.request});

  @override
  State<ServiceRequestNotesWidget> createState() => _ServiceRequestNotesWidgetState();
}

class _ServiceRequestNotesWidgetState extends State<ServiceRequestNotesWidget> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  String? _initialNotes;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.request.notes);
    _initialNotes = widget.request.notes;
  }

  @override
  void didUpdateWidget(ServiceRequestNotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.notes != oldWidget.request.notes) {
      _notesController.text = widget.request.notes ?? '';
      _initialNotes = widget.request.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    if (_notesController.text != _initialNotes) {
      // TODO: Implement save notes functionality
      setState(() {
        _isEditing = false;
        _initialNotes = _notesController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _notesController.text = _initialNotes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes & Observations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _isEditing
              ? Column(
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Add your notes here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textColor)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: (widget.request.notes != null && widget.request.notes!.isNotEmpty)
                        ? Text(
                            widget.request.notes!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textColor.withOpacity(0.8),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Tap to add notes...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textColor.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                ),
        ],
      ),
    );
  }
}















