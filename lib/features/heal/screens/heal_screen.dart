import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../screens/service_management_screen.dart';
import '../screens/service_requests_screen.dart';

class HealScreen extends StatelessWidget {
  const HealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.heal),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'manage_services') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceManagementScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'manage_services',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(l10n.manageServices),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const ServiceRequestsScreen(),
    );
  }
}
