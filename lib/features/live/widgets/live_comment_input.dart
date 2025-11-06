import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/live_stream_service.dart';

class LiveCommentInput extends StatefulWidget {
  const LiveCommentInput({super.key});

  @override
  State<LiveCommentInput> createState() => _LiveCommentInputState();
}

class _LiveCommentInputState extends State<LiveCommentInput> {
  final TextEditingController _controller = TextEditingController();
  final LiveStreamService _liveService = LiveStreamService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // User avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Text(
              'Y',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Comment input - properly rounded
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22), // Fully rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.7),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 1,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Send button - perfectly round
        GestureDetector(
          onTap: _sendComment,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle, // Perfect circle
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _sendComment() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    HapticFeedback.selectionClick();

    final streamId = _liveService.currentStream?.id;
    if (streamId == null) {
      _controller.clear();
      return;
    }

    _liveService.sendComment(streamId, message);

    _controller.clear();
  }
}
