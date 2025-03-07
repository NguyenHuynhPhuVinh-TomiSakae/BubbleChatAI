import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 16.0),
                softWrap: true,
              ),
            ),
          if (message.isUser)
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(fontSize: 16.0),
                  softWrap: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 