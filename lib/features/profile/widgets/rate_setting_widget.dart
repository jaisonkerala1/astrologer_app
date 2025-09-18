import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';

class RateSettingWidget extends StatefulWidget {
  final double ratePerMinute;
  final Function(double) onUpdate;

  const RateSettingWidget({
    super.key,
    required this.ratePerMinute,
    required this.onUpdate,
  });

  @override
  State<RateSettingWidget> createState() => _RateSettingWidgetState();
}

class _RateSettingWidgetState extends State<RateSettingWidget> {
  late TextEditingController _rateController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.ratePerMinute.toString());
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
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
                'Rate Setting',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _toggleEditing,
                child: Text(_isEditing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isEditing) ...[
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Rate per minute',
                prefixText: '${AppConstants.currencySymbol} ',
                suffixText: '/min',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a rate';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate <= 0) {
                  return 'Please enter a valid rate';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleEditing,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveRate,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.earningsColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.earningsColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    color: AppTheme.earningsColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${AppConstants.currencySymbol}${widget.ratePerMinute.toStringAsFixed(0)} per minute',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.earningsColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is the rate clients will pay for your consultation time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _rateController.text = widget.ratePerMinute.toString();
      }
    });
  }

  void _saveRate() {
    final rate = double.tryParse(_rateController.text);
    if (rate != null && rate > 0) {
      widget.onUpdate(rate);
      setState(() {
        _isEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid rate'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
