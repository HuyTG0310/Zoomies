import 'dart:typed_data';
import 'pet_type.dart';
import 'triage_level.dart';

class SessionModel {
  final String id;
  final String userId;
  final String petName;
  final PetType petType;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final TriageLevel triageLevel;
  final String preliminaryAssessment;
  final List<String> immediateActions;
  final String disclaimer;
  final DateTime createdAt;
  final String? lastMessage;
  final String status; // 'active', 'monitoring', 'resolved'

  const SessionModel({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    this.imageUrl,
    this.imageBytes,
    required this.triageLevel,
    required this.preliminaryAssessment,
    required this.immediateActions,
    required this.disclaimer,
    required this.createdAt,
    this.lastMessage,
    this.status = 'active',
  });

  SessionModel copyWith({
    String? id,
    String? userId,
    String? petName,
    PetType? petType,
    String? imageUrl,
    Uint8List? imageBytes,
    TriageLevel? triageLevel,
    String? preliminaryAssessment,
    List<String>? immediateActions,
    String? disclaimer,
    DateTime? createdAt,
    String? lastMessage,
    String? status,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      triageLevel: triageLevel ?? this.triageLevel,
      preliminaryAssessment: preliminaryAssessment ?? this.preliminaryAssessment,
      immediateActions: immediateActions ?? this.immediateActions,
      disclaimer: disclaimer ?? this.disclaimer,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'petName': petName,
      'petType': petType.displayName,
      'imageUrl': imageUrl,
      'triageLevel': triageLevel.name,
      'preliminaryAssessment': preliminaryAssessment,
      'immediateActions': immediateActions,
      'disclaimer': disclaimer,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'status': status,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
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

    // Nhận diện loài (hỗ trợ cả tiếng Việt "Chó", "Mèo" và tiếng Anh)
    final rawPetType = (map['petType'] as String?)?.toLowerCase() ?? '';
    final petType = (rawPetType.contains('mèo') || rawPetType == 'cat')
        ? PetType.cat
        : PetType.dog;

    // Hỗ trợ cả cấu trúc TriageCard từ Firestore và cấu trúc phẳng của UI
    final triageCard = map['triageCard'] is Map
        ? (map['triageCard'] as Map).cast<String, dynamic>()
        : null;

    final rawLevel = (triageCard?['urgencyLevel'] ?? map['triageLevel'] as String?)?.toUpperCase() ?? '';
    final triageLevel = rawLevel == 'GREEN'
        ? TriageLevel.green
        : (rawLevel == 'RED' ? TriageLevel.red : TriageLevel.yellow);

    final summary = (triageCard?['summary'] ?? map['preliminaryAssessment'] ?? map['initialSymptoms'] ?? '') as String;
    final rawActions = triageCard?['immediateActions'] ?? map['immediateActions'];
    final immediateActions = rawActions is List
        ? rawActions.map((e) => e.toString()).toList()
        : <String>[];

    return SessionModel(
      id: id ?? (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? 'user_default',
      petName: (map['petName'] as String?) ?? (petType == PetType.dog ? 'Bé Cún' : 'Bé Mèo'),
      petType: petType,
      imageUrl: map['imageUrl'] as String?,
      triageLevel: triageLevel,
      preliminaryAssessment: summary,
      immediateActions: immediateActions,
      disclaimer: (map['disclaimer'] as String?) ?? defaultDisclaimer,
      createdAt: parseTime(map['createdAt']),
      lastMessage: map['lastMessage'] as String?,
      status: (map['status'] as String?) ?? 'active',
    );
  }

  static const String defaultDisclaimer =
      '⚠️ LƯU Ý MIỄN TRỪ TRÁCH NHIỆM Y TẾ: Đánh giá phân loại Triage và gợi ý sơ cứu này được cung cấp bởi hệ thống AI Zoomies nhằm mục đích sàng lọc và tham khảo ban đầu. Đây KHÔNG phải là chẩn đoán y khoa chính thức từ bác sĩ thú y. Nếu thú cưng có triệu chứng nguy hiểm hoặc diễn tiến nặng, hãy liên hệ ngay cơ sở y tế thú y gần nhất.';
}
