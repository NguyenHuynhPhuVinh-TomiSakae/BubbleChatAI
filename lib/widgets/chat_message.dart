import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import 'dart:io';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.images.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.images.length,
                        itemBuilder: (context, index) {
                          final imagePath = message.images[index];
                          final imageFile = File(imagePath);
                          
                          // Kiểm tra xem tệp có tồn tại không
                          final imageExists = imageFile.existsSync();
                          
                          return GestureDetector(
                            onTap: () {
                              // TODO: Hiển thị ảnh full screen khi nhấn vào
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: imageExists ? DecorationImage(
                                  image: FileImage(imageFile),
                                  fit: BoxFit.cover,
                                ) : null,
                                color: imageExists ? null : Colors.grey[200],
                              ),
                              child: !imageExists
                                  ? const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép văn bản'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: SelectableText(
                        message.text,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: aiTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (message.isUser)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.images.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.images.length,
                        itemBuilder: (context, index) {
                          final imagePath = message.images[index];
                          final imageFile = File(imagePath);
                          
                          // Kiểm tra xem tệp có tồn tại không
                          final imageExists = imageFile.existsSync();
                          
                          return GestureDetector(
                            onTap: () {
                              // TODO: Hiển thị ảnh full screen khi nhấn vào
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: imageExists ? DecorationImage(
                                  image: FileImage(imageFile),
                                  fit: BoxFit.cover,
                                ) : null,
                                color: imageExists ? null : Colors.grey[200],
                              ),
                              child: !imageExists
                                  ? const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Container(
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
                ],
              ),
            ),
        ],
      ),
    );
  }
} 