import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:flutter/services.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    
    // Màu sắc cho user bubble và AI text
    final Color userBubbleColor = isDarkMode 
        ? theme.colorScheme.primary.withOpacity(0.8)
        : theme.colorScheme.primary;
    
    final Color userTextColor = Colors.white;
    final Color aiTextColor = isDarkMode
        ? theme.colorScheme.onSurface
        : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Expanded(
              child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép văn bản'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: aiTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          if (message.isUser)
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: userBubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: userTextColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 