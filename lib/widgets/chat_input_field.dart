import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> with SingleTickerProviderStateMixin {
  bool _isComposing = false;
  late FocusNode _focusNode;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  VoidCallback? onAttachmentPressed;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sendButtonAnimation = CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeOut,
    );

    widget.controller.addListener(_updateComposingState);
  }

  void _updateComposingState() {
    final newComposing = widget.controller.text.isNotEmpty;
    if (newComposing != _isComposing) {
      setState(() {
        _isComposing = newComposing;
      });
      
      if (newComposing) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateComposingState);
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    widget.onSubmitted(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDarkMode 
        ? theme.colorScheme.surface
        : Colors.white;
    
    final borderColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade300;
        
    final hintColor = isDarkMode
        ? Colors.grey.shade500
        : Colors.grey.shade500;
    
    final inputBackgroundColor = isDarkMode
        ? theme.colorScheme.surface
        : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                if (onAttachmentPressed != null) {
                  onAttachmentPressed!();
                }
              },
              iconSize: 20,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: inputBackgroundColor,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: borderColor,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Nhắn tin cho BubbleChatAI',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: hintColor),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _handleSubmitted,
                maxLines: null,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (_isComposing) const SizedBox(width: 8),
          if (_isComposing)
            ScaleTransition(
              scale: _sendButtonAnimation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _handleSubmitted(widget.controller.text),
                  iconSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 