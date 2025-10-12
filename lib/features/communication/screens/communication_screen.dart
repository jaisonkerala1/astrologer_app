import 'package:flutter/material.dart';
import 'unified_communication_screen.dart';

/// Legacy wrapper for CommunicationScreen - now redirects to UnifiedCommunicationScreen
/// This maintains backward compatibility with existing navigation code
class CommunicationScreen extends StatelessWidget {
  final String? initialTab;
  
  const CommunicationScreen({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    // Simply return the new unified screen
    // The initialTab parameter is no longer needed as we have filters instead
    return const UnifiedCommunicationScreen();
  }
}
