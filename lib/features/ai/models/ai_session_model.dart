import '../models/ai_message.dart';

class AiSession {
  final String id;
  final DateTime createdAt;
  final List<AiMessage> messages;

  AiSession({
    required this.id,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => {
        'id': m.id,
        'text': m.text,
        'isUser': m.isUser,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
    };
  }

  factory AiSession.fromMap(Map<String, dynamic> map) {
    return AiSession(
      id: map['id'],
      createdAt: DateTime.parse(map['createdAt']),
      messages: (map['messages'] as List).map((m) => AiMessage(
        id: m['id'],
        text: m['text'],
        isUser: m['isUser'],
        timestamp: DateTime.parse(m['timestamp']),
      )).toList(),
    );
  }
}
