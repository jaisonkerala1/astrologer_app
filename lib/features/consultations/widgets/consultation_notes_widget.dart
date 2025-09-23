import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/consultation_model.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notes & Observations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
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
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
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
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
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
                        color: const Color(0xFF3B82F6),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notes added yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap edit to add your observations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _cancelEdit() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = false;
      _notesController.text = widget.consultation.notes ?? '';
    });
  }

  void _saveNotes() {
    HapticFeedback.lightImpact();
    // TODO: Save notes to backend
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}









