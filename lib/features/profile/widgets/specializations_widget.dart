import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';

class SpecializationsWidget extends StatefulWidget {
  final List<String> specializations;
  final Function(List<String>) onUpdate;

  const SpecializationsWidget({
    super.key,
    required this.specializations,
    required this.onUpdate,
  });

  @override
  State<SpecializationsWidget> createState() => _SpecializationsWidgetState();
}

class _SpecializationsWidgetState extends State<SpecializationsWidget> {
  late List<String> _selectedSpecializations;

  @override
  void initState() {
    super.initState();
    _selectedSpecializations = List.from(widget.specializations);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Specializations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _showSpecializationDialog,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSpecializations.map((specialization) {
              return Chip(
                label: Text(specialization),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedSpecializations.remove(specialization);
                  });
                  widget.onUpdate(_selectedSpecializations);
                },
              );
            }).toList(),
          ),
          if (_selectedSpecializations.isEmpty)
            Text(
              'No specializations selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _showSpecializationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Specializations'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: AppConstants.defaultSpecializations.map((specialization) {
                  final isSelected = _selectedSpecializations.contains(specialization);
                  return CheckboxListTile(
                    title: Text(specialization),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSpecializations.add(specialization);
                        } else {
                          _selectedSpecializations.remove(specialization);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSpecializations = List.from(_selectedSpecializations);
              });
              widget.onUpdate(_selectedSpecializations);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
