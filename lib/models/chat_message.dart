class ChatMessage {
  final String id;
  final String role; // "user" | "model"
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isModel => role == 'model';

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return ChatMessage(
      id: id,
      role: (map['role'] as String?) ?? 'model',
      text: (map['text'] as String?) ?? '',
      createdAt: parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

