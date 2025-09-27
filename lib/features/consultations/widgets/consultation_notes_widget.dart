import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/consultation_model.dart';
import '../services/consultations_service.dart';
import '../../../shared/theme/services/theme_service.dart';

class ConsultationNotesWidget extends StatefulWidget {
  final ConsultationModel consultation;

  const ConsultationNotesWidget({
    super.key,
    required this.consultation,
  });

  @override
  State<ConsultationNotesWidget> createState() => _ConsultationNotesWidgetState();
}

class _ConsultationNotesWidgetState extends State<ConsultationNotesWidget> {
  late TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.consultation.notes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeService.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notes & Observations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: themeService.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: themeService.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notes content
          if (_isEditing) ...[
            TextField(
              controller: _notesController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Add your notes and observations...',
                hintStyle: TextStyle(
                  color: themeService.textSecondary.withOpacity(0.6),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeService.borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeService.borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeService.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(
                fontSize: 14,
                color: themeService.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _cancelEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: themeService.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeService.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _saveNotes,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (widget.consultation.notes != null && widget.consultation.notes!.isNotEmpty)
              Text(
                widget.consultation.notes!,
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textSecondary,
                  height: 1.5,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeService.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeService.borderColor,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 32,
                      color: themeService.textSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notes added yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap edit to add your observations',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
      },
    );
  }

  void _cancelEdit() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = false;
      _notesController.text = widget.consultation.notes ?? '';
    });
  }

  void _saveNotes() async {
    HapticFeedback.lightImpact();
    
    try {
      // Show loading indicator
      setState(() {
        _isEditing = false;
      });
      
      // Import the consultations service
      final consultationsService = ConsultationsService();
      
      // Save notes to backend
      await consultationsService.addConsultationNotes(
        widget.consultation.id,
        _notesController.text.trim(),
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      
      // Refresh the consultation data
      if (mounted) {
        // Trigger a refresh of the consultation data
        // The parent widget should listen to this and update accordingly
        // Note: The BlocConsumer in the parent will automatically update when the state changes
      }
      
    } catch (e) {
      print('Error saving notes: $e');
      
      // Revert editing state on error
      setState(() {
        _isEditing = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}















