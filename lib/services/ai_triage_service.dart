import '../models/triage_card.dart';

/// Service tài liệu & helper gọi Firebase Cloud Functions cho Zoomies AI Triage Flow
///
/// Hướng dẫn cài đặt Flutter packages khi cần:
/// ```bash
/// flutter pub add firebase_core cloud_firestore cloud_functions
/// ```
class AiTriageService {
  AiTriageService();

  /// Hàm 1: Chuẩn bị payload gọi Cloud Function `analyzeInitialSymptom`
  ///
  /// Flutter Client gửi:
  /// - [petType]: "Chó" | "Mèo"
  /// - [symptoms]: Mô tả triệu chứng ban đầu
  /// - [imageUrl]: Link ảnh trên Firebase Storage (nếu có)
  /// - [imageBase64]: Chuỗi base64 của ảnh (nếu gửi trực tiếp)
  ///
  /// Output trả về:
  /// - `sessionId`: ID của ca bệnh mới tạo
  /// - `triageCard`: Thẻ phân loại ban đầu (urgencyLevel, summary, possibleCauses, immediateActions, vetQuestions)
  static Map<String, dynamic> buildAnalyzeInitialSymptomPayload({
    required String petType,
    required String symptoms,
    String? imageUrl,
    String? imageBase64,
    String? imageMimeType,
    String? userId,
  }) {
    return {
      'petType': petType,
      'symptoms': symptoms,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (imageBase64 != null && imageBase64.isNotEmpty) 'imageBase64': imageBase64,
      'imageMimeType': ?imageMimeType,
      'userId': ?userId,
    };
  }

  /// Hàm 2: Chuẩn bị payload gọi Cloud Function `sendChatMessage`
  ///
  /// Flutter Client gửi:
  /// - [sessionId]: ID ca bệnh
  /// - [userMessage]: Câu hỏi tiếp theo của chủ nuôi
  ///
  /// Output trả về:
  /// - `reply`: Câu trả lời của AI
  static Map<String, dynamic> buildSendChatMessagePayload({
    required String sessionId,
    required String userMessage,
  }) {
    return {
      'sessionId': sessionId,
      'userMessage': userMessage,
    };
  }

  /// Parse kết quả từ `analyzeInitialSymptom`
  static ({String sessionId, TriageCard triageCard}) parseAnalyzeResponse(Map<dynamic, dynamic> responseData) {
    final sessionId = responseData['sessionId'] as String;
    final cardMap = (responseData['triageCard'] as Map<dynamic, dynamic>).cast<String, dynamic>();
    final triageCard = TriageCard.fromMap(cardMap);
    return (sessionId: sessionId, triageCard: triageCard);
  }

  /// Parse phản hồi từ `sendChatMessage`
  static String parseChatResponse(Map<dynamic, dynamic> responseData) {
    return (responseData['reply'] as String?) ?? '';
  }
}
