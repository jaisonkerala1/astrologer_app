import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/chat_screen.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/theme/app_theme.dart';

class FloatingChatButton extends StatelessWidget {
  final AstrologerModel? userProfile;

  const FloatingChatButton({
    super.key,
    this.userProfile,
  });

  void _openChat(BuildContext context) {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ChatScreen(
          userProfile: userProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChat(context),
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.nightlight_round,
        size: 28,
      ),
    );
  }
}
