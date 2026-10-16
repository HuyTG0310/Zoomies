import 'triage_card.dart';

class Session {
  final String id;
  final String userId;
  final String petType; // "Chó" | "Mèo"
  final String imageUrl;
  final String initialSymptoms;
  final TriageCard triageCard;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Session({
    required this.id,
    required this.userId,
    required this.petType,
    required this.imageUrl,
    required this.initialSymptoms,
    required this.triageCard,
    this.createdAt,
    this.updatedAt,
  });

  factory Session.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      // Tránh crash nếu chưa import cloud_firestore hoặc nhận string/millis
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return Session(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      petType: (map['petType'] as String?) ?? 'Chó',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      initialSymptoms: (map['initialSymptoms'] as String?) ?? '',
      triageCard: TriageCard.fromMap(
        (map['triageCard'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {},
      ),
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petType': petType,
      'imageUrl': imageUrl,
      'initialSymptoms': initialSymptoms,
      'triageCard': triageCard.toMap(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

