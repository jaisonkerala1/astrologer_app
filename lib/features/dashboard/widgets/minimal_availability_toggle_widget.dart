import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/status_service.dart';

class MinimalAvailabilityToggleWidget extends StatelessWidget {
  const MinimalAvailabilityToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusService>(
      builder: (context, statusService, child) {
        if (statusService == null) {
          return const SizedBox.shrink();
        }

        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status label
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusService.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (statusService.isOnline ? Colors.green : Colors.grey)
                                  .withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusService.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: themeService.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // Minimal toggle switch
                  GestureDetector(
                    onTap: statusService.isUpdating ? null : () {
                      HapticFeedback.lightImpact();
                      try {
                        statusService.setOnlineStatus(!statusService.isOnline);
                      } catch (e) {
                        print('Error toggling status: $e');
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: statusService.isOnline 
                            ? themeService.primaryColor
                            : themeService.borderColor,
                        boxShadow: [
                          BoxShadow(
                            color: themeService.isVedicMode() 
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: statusService.isOnline 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: statusService.isUpdating
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      statusService.isOnline 
                                          ? themeService.primaryColor
                                          : themeService.textSecondary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  statusService.isOnline ? Icons.check : Icons.close,
                                  size: 14,
                                  color: statusService.isOnline 
                                      ? themeService.primaryColor
                                      : themeService.textSecondary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
