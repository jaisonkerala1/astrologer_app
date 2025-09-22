import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/service_request_model.dart';

class ServiceRequestInfoWidget extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestInfoWidget({super.key, required this.request});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.customerName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(context, request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.customerPhone,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textColor.withOpacity(0.7),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          
          _buildInfoRow(
            icon: Icons.spa_outlined,
            label: 'Service',
            value: request.serviceName,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: request.serviceCategory,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Requested Date',
            value: DateFormat('MMM dd, yyyy').format(request.requestedDate),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Requested Time',
            value: request.requestedTime,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.attach_money_outlined,
            label: 'Price',
            value: '₹${request.price.toStringAsFixed(0)}',
          ),
          
          if (request.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text(
              'Special Instructions:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.specialInstructions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, RequestStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case RequestStatus.pending:
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        statusText = 'Pending';
        break;
      case RequestStatus.confirmed:
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        statusText = 'Confirmed';
        break;
      case RequestStatus.inProgress:
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        statusText = 'In Progress';
        break;
      case RequestStatus.completed:
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        statusText = 'Completed';
        break;
      case RequestStatus.cancelled:
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
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





