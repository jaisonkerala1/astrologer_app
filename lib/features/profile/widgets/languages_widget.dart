import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';

class LanguagesWidget extends StatefulWidget {
  final List<String> languages;
  final Function(List<String>) onUpdate;

  const LanguagesWidget({
    super.key,
    required this.languages,
    required this.onUpdate,
  });

  @override
  State<LanguagesWidget> createState() => _LanguagesWidgetState();
}

class _LanguagesWidgetState extends State<LanguagesWidget> {
  late List<String> _selectedLanguages;

  @override
  void initState() {
    super.initState();
    _selectedLanguages = List.from(widget.languages);
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
                'Languages',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _showLanguageDialog,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedLanguages.map((language) {
              return Chip(
                label: Text(language),
                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.secondaryColor,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedLanguages.remove(language);
                  });
                  widget.onUpdate(_selectedLanguages);
                },
              );
            }).toList(),
          ),
          if (_selectedLanguages.isEmpty)
            Text(
              'No languages selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Languages'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: AppConstants.defaultLanguages.map((language) {
                  final isSelected = _selectedLanguages.contains(language);
                  return CheckboxListTile(
                    title: Text(language),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedLanguages.add(language);
                        } else {
                          _selectedLanguages.remove(language);
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
                _selectedLanguages = List.from(_selectedLanguages);
              });
              widget.onUpdate(_selectedLanguages);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
