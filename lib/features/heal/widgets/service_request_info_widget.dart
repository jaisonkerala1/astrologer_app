import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_request_model.dart';

class ServiceRequestInfoWidget extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestInfoWidget({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.customerName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(context, request.status, themeService),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.customerPhone,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: themeService.textSecondary,
            ),
          ),
          Divider(height: 32, color: themeService.borderColor),
          
          _buildInfoRow(
            icon: Icons.spa_outlined,
            label: 'Service',
            value: request.serviceName,
            themeService: themeService,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: request.serviceCategory,
            themeService: themeService,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Requested Date',
            value: DateFormat('MMM dd, yyyy').format(request.requestedDate),
            themeService: themeService,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Requested Time',
            value: request.requestedTime,
            themeService: themeService,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.attach_money_outlined,
            label: 'Price',
            value: '₹${request.price.toStringAsFixed(0)}',
            themeService: themeService,
          ),
          
          if (request.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: themeService.borderColor),
            const SizedBox(height: 16),
            Text(
              'Special Instructions:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.specialInstructions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeService.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, ThemeService? themeService}) {
    return Row(
      children: [
        Icon(icon, color: themeService?.primaryColor ?? Colors.blue, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: themeService?.textPrimary ?? Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: themeService?.textSecondary ?? Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, RequestStatus status, ThemeService themeService) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case RequestStatus.pending:
        backgroundColor = themeService.warningColor.withOpacity(0.1);
        textColor = themeService.warningColor;
        statusText = 'Pending';
        break;
      case RequestStatus.confirmed:
        backgroundColor = themeService.primaryColor.withOpacity(0.1);
        textColor = themeService.primaryColor;
        statusText = 'Confirmed';
        break;
      case RequestStatus.inProgress:
        backgroundColor = themeService.successColor.withOpacity(0.1);
        textColor = themeService.successColor;
        statusText = 'In Progress';
        break;
      case RequestStatus.completed:
        backgroundColor = themeService.successColor.withOpacity(0.1);
        textColor = themeService.successColor;
        statusText = 'Completed';
        break;
      case RequestStatus.cancelled:
        backgroundColor = themeService.errorColor.withOpacity(0.1);
        textColor = themeService.errorColor;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}















