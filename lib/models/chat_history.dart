import 'message.dart';

class ChatHistory {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<Message> messages;

  ChatHistory({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
  });

  factory ChatHistory.create(String title, Message firstMessage) {
    final now = DateTime.now();
    return ChatHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      lastUpdatedAt: now,
      messages: [firstMessage],
    );
  }

  ChatHistory copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<Message>? messages,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messages: messages ?? this.messages,
    );
  }

  ChatHistory addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages)..add(message);
    return copyWith(
      lastUpdatedAt: DateTime.now(),
      messages: updatedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'messages': messages.map((m) => {
        'text': m.text,
        'isUser': m.isUser,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
    };
  }

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt']),
      messages: (json['messages'] as List).map((m) => Message(
        text: m['text'],
        isUser: m['isUser'],
        timestamp: DateTime.parse(m['timestamp']),
      )).toList(),
    );
  }
} 