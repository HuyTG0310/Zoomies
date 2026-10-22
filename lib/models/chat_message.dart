enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.status = MessageStatus.sent,
  });

  // Getter hỗ trợ định dạng role trên Firestore ("user" | "model")
  String get role => isUser ? 'user' : 'model';
  bool get isModel => !isUser;
  DateTime get createdAt => timestamp;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? imageUrl,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'isUser': isUser,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status.name,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    final rawIsUser = map['isUser'];
    final bool resolvedIsUser = rawIsUser is bool
        ? rawIsUser
        : (map['role'] == 'user');

    return ChatMessage(
      id: id ?? (map['id'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      isUser: resolvedIsUser,
      timestamp: parseTime(map['createdAt'] ?? map['timestamp']),
      imageUrl: map['imageUrl'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }
}
