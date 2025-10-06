import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../screens/service_management_screen.dart';
import '../screens/service_requests_screen.dart';

class HealScreen extends StatefulWidget {
  const HealScreen({super.key});

  @override
  State<HealScreen> createState() => _HealScreenState();
}

class _HealScreenState extends State<HealScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state on tab switch

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(l10n.heal),
            backgroundColor: themeService.primaryColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: themeService.textPrimary),
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
                        Icon(Icons.settings, color: themeService.primaryColor),
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
      },
    );
  }
}
