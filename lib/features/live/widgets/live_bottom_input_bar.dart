import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Persistent bottom input bar for comments with quick gift access
/// Similar to Instagram Live / TikTok Live
class LiveBottomInputBar extends StatefulWidget {
  final TextEditingController? commentController;
  final VoidCallback onSendComment;
  final VoidCallback onGiftTap;
  final VoidCallback? onGiftLongPress;
  final VoidCallback? onEmojiTap;
  final String placeholder;
  final bool showGiftButton;

  const LiveBottomInputBar({
    super.key,
    this.commentController,
    required this.onSendComment,
    required this.onGiftTap,
    this.onGiftLongPress,
    this.onEmojiTap,
    this.placeholder = 'Comment...',
    this.showGiftButton = true,
  });

  @override
  State<LiveBottomInputBar> createState() => _LiveBottomInputBarState();
}

class _LiveBottomInputBarState extends State<LiveBottomInputBar> {
  late TextEditingController _controller;
  bool _hasText = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.commentController ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.commentController == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (_hasText) {
      HapticFeedback.selectionClick();
      widget.onSendComment();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          child: Row(
            children: [
              // Comment input field
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(_focusNode.hasFocus ? 0.45 : 0.35),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withOpacity(_focusNode.hasFocus ? 0.35 : 0.18),
                        width: _focusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            cursorColor: Colors.white,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              hintText: widget.placeholder,
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 15,
                              ),
                            ),
                            maxLines: 1,
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                        
                        // Emoji button
                        if (widget.onEmojiTap != null)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onEmojiTap!();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Text(
                                '😊',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button (shows when text is entered)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _hasText ? 44 : 0,
                child: _hasText
                    ? GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeService.primaryColor,
                                themeService.secondaryColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: themeService.primaryColor.withOpacity(0.4),
                                blurRadius: 8,
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
                      )
                    : null,
              ),

              // Gift button (always visible if enabled)
              if (widget.showGiftButton && !_hasText) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onGiftTap();
                  },
                  onLongPress: widget.onGiftLongPress != null
                      ? () {
                          HapticFeedback.selectionClick();
                          widget.onGiftLongPress!();
                        }
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700), // Gold
                          Color(0xFFFF8C00), // Dark orange
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
