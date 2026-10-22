import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/pet_type.dart';
import '../models/session_model.dart';
import '../models/triage_level.dart';

/// Service quản lý Sessions và Chat Messages.
/// Hiện tại chạy Mock Stream thời gian thực chuẩn kiến trúc Firestore & Cloud Functions.
/// Khi đã sẵn sàng kết nối Firebase, chỉ cần cập nhật các hàm sang Firestore SDK tương ứng.
class SessionService {
  static final SessionService instance = SessionService._internal();
  SessionService._internal() {
    _initSeedData();
  }

  // Danh sách session trong bộ nhớ
  final List<SessionModel> _sessions = [];
  final StreamController<List<SessionModel>> _sessionsController =
      StreamController<List<SessionModel>>.broadcast();

  // Map stream controller tin nhắn cho từng session
  final Map<String, List<ChatMessage>> _messagesStore = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers = {};

  /// Lắng nghe danh sách sessions của người dùng (tương đương Firestore collection 'sessions')
  Stream<List<SessionModel>> streamUserSessions(String userId) {
    // Gửi ngay danh sách hiện tại
    scheduleMicrotask(() {
      _sessionsController.add(List.unmodifiable(_sessions));
    });
    return _sessionsController.stream;

    /*
    // KHI ĐÃ SET UP FIRESTORE THÀNH CÔNG:
    return FirebaseFirestore.instance
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SessionModel.fromMap(d.data(), id: d.id)).toList());
    */
  }

  /// Lắng nghe tin nhắn theo thời gian thực (tương đương Firestore subcollection 'sessions/{sessionId}/messages')
  Stream<List<ChatMessage>> streamMessages(String sessionId) {
    if (!_messageControllers.containsKey(sessionId)) {
      _messageControllers[sessionId] = StreamController<List<ChatMessage>>.broadcast();
    }
    final messages = _messagesStore[sessionId] ?? [];
    scheduleMicrotask(() {
      _messageControllers[sessionId]?.add(List.unmodifiable(messages));
    });
    return _messageControllers[sessionId]!.stream;

    /*
    // KHI ĐÃ SET UP FIRESTORE THÀNH CÔNG:
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.data(), id: d.id)).toList());
    */
  }

  /// Gửi tin nhắn qua Cloud Function 'sendChatMessage'
  Future<void> sendChatMessage({
    required String sessionId,
    required String text,
    String? imageUrl,
  }) async {
    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      status: MessageStatus.sent,
    );

    // Lưu vào store cục bộ và broadcast
    _messagesStore.putIfAbsent(sessionId, () => []).add(userMessage);
    _messageControllers[sessionId]?.add(List.unmodifiable(_messagesStore[sessionId]!));

    // Cập nhật lastMessage của Session
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        lastMessage: text,
      );
      _sessionsController.add(List.unmodifiable(_sessions));
    }

    /*
    // KHI ĐÃ SET UP CLOUD FUNCTION:
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendChatMessage');
      await callable.call({
        'sessionId': sessionId,
        'message': text,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint('Cloud Function error: $e');
    }
    */

    // Giả lập AI phản hồi sau 1.5 giây để kiểm tra trải nghiệm chat thời gian thực
    _simulateAiResponse(sessionId, text);
  }

  void _simulateAiResponse(String sessionId, String userQuestion) {
    Timer(const Duration(milliseconds: 1400), () {
      final session = _sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => _sessions.first,
      );

      String reply;
      final q = userQuestion.toLowerCase();
      if (q.contains('sốt') || q.contains('nhiệt độ')) {
        reply =
            'Nhiệt độ bình thường của ${session.petType.displayName} dao động từ 38.0°C đến 39.2°C. Bạn có thể dùng nhiệt kế đo ở hậu môn hoặc kiểm tra xem mũi bé có khô, tai có nóng ran hay không nhé.';
      } else if (q.contains('bôi') || q.contains('thuốc')) {
        reply =
            'Tuyệt đối không tự ý dùng cồn đỏ Povidone nồng độ cao hoặc thuốc bôi chứa Corticoid vì thú cưng có thể liếm phải gây nhiễm độc ruột. Hãy chỉ rửa nhẹ bằng nước muối sinh lý 0.9% trong lúc chờ khám bác sĩ.';
      } else if (q.contains('ăn') || q.contains('uống')) {
        reply =
            'Nếu bé bỏ ăn hơn 24 giờ kèm nôn mửa hoặc lờ đờ, mức độ ưu tiên sẽ chuyển sang Khẩn cấp. Hãy giữ bé ở nơi thoáng mát và cung cấp nước sạch từng chút một.';
      } else {
        reply =
            'Bác sĩ AI Zoomies đã ghi nhận thông tin: "$userQuestion". Hãy quan sát kỹ vị trí tổn thương của bé trong 4-6 giờ tới. Nếu thấy sưng to, chảy mủ hoặc bé kêu rên đau đớn, hãy đưa bé đến bệnh viện thú y ngay!';
      }

      final aiMessage = ChatMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      _messagesStore[sessionId]?.add(aiMessage);
      _messageControllers[sessionId]?.add(List.unmodifiable(_messagesStore[sessionId]!));

      // Cập nhật session
      final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
          lastMessage: reply,
        );
        _sessionsController.add(List.unmodifiable(_sessions));
      }
    });
  }

  /// Tạo một ca khám mới sau khi hoàn thành bước nén và upload ảnh
  Future<SessionModel> createNewSession({
    required PetType petType,
    required String petName,
    Uint8List? imageBytes,
    String? preliminaryNote,
  }) async {
    // Đánh giá sơ bộ và phân loại Triage giả lập
    TriageLevel evaluatedLevel;
    String assessment;
    List<String> actions;

    // Giả định phân loại Triage thông minh dựa trên thông tin nhập
    final note = (preliminaryNote ?? '').toLowerCase();
    if (note.contains('máu') ||
        note.contains('co giật') ||
        note.contains('khó thở') ||
        note.contains('ngất')) {
      evaluatedLevel = TriageLevel.red;
      assessment =
          'Phát hiện dấu hiệu nguy hiểm cấp tính (chảy máu hoặc suy hô hấp/thần kinh). Nguy cơ sốc hoặc suy đa tạng nếu không can thiệp kịp thời.';
      actions = [
        'Giữ thú cưng nằm yên ở nơi thoáng khí, không di chuyển mạnh.',
        'Dùng gạc sạch ấn nhẹ cầm máu nếu có vết thương hở.',
        'Liên hệ ngay hotline cấp cứu thú y 24/7 và đưa đến phòng khám gần nhất.',
        'Không cho thú cưng ăn hoặc uống nước để tránh sặc đường thở.',
      ];
    } else if (note.contains('gãi') ||
        note.contains('rụng lông') ||
        note.contains('nấm') ||
        note.contains('ngứa')) {
      evaluatedLevel = TriageLevel.yellow;
      assessment =
          'Tổn thương da liễu dạng viêm tiếp xúc hoặc nấm bề mặt biểu bì. Vết đỏ có xu hướng lan rộng do thú cưng cào gãi liên tục.';
      actions = [
        'Đeo loa chống liếm (Elizabeth collar) ngay lập tức để hạn chế tổn thương.',
        'Vệ sinh nhẹ bằng gạc tẩm nước muối sinh lý NaCl 0.9%, để khô tự nhiên.',
        'Tránh để thú cưng cọ xát vào thảm hoặc nơi bụi bẩn.',
        'Sắp xếp đưa bé đi làm xét nghiệm cạo da/soi nấm trong 24 giờ tới.',
      ];
    } else {
      evaluatedLevel = TriageLevel.green;
      assessment =
          'Triệu chứng nhẹ tại chỗ, thể trạng toàn thân tương đối ổn định. Chưa phát hiện dấu hiệu đe dọa sinh mạng tức thì.';
      actions = [
        'Tiếp tục theo dõi nhiệt độ cơ thể và lượng thức ăn tiêu thụ trong 24h.',
        'Giữ môi trường sống sạch sẽ, ấm áp và thoáng gió.',
        'Nếu triệu chứng kéo dài quá 48h hoặc xuất hiện nôn ói, hãy đưa bé đi khám.',
      ];
    }

    final newSession = SessionModel(
      id: 'zm_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_current',
      petName: petName.trim().isEmpty ? (petType == PetType.dog ? 'Bé Cún' : 'Bé Mèo') : petName.trim(),
      petType: petType,
      imageBytes: imageBytes,
      triageLevel: evaluatedLevel,
      preliminaryAssessment: assessment,
      immediateActions: actions,
      disclaimer: SessionModel.defaultDisclaimer,
      createdAt: DateTime.now(),
      lastMessage: 'Đã hoàn tất phân loại Triage ban đầu',
      status: 'active',
    );

    _sessions.insert(0, newSession);
    _sessionsController.add(List.unmodifiable(_sessions));

    // Khởi tạo các tin nhắn mở đầu của phòng khám
    final initialMessages = [
      ChatMessage(
        id: 'msg_init_1',
        text:
            'Xin chào bạn! Bác sĩ thú y AI Zoomies đã nhận được hình ảnh và thông tin của ${newSession.petName}. Ca khám đã được xếp mức: ${evaluatedLevel.label.toUpperCase()}.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
      ),
      ChatMessage(
        id: 'msg_init_2',
        text:
            '📌 Nhận định sơ bộ: ${newSession.preliminaryAssessment}\n\n👉 Bạn hãy làm theo các bước sơ cứu ở bảng Triage phía trên và gửi thêm câu hỏi nếu cần trợ giúp nhé!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];

    _messagesStore[newSession.id] = initialMessages;
    if (!_messageControllers.containsKey(newSession.id)) {
      _messageControllers[newSession.id] = StreamController<List<ChatMessage>>.broadcast();
    }
    _messageControllers[newSession.id]!.add(initialMessages);

    return newSession;
  }

  void _initSeedData() {
    // 3 ca khám mẫu đại diện cho 3 màu Triage: Đỏ, Vàng, Xanh
    final sessionRed = SessionModel(
      id: 'zm_seed_101',
      userId: 'user_current',
      petName: 'Bé Miu',
      petType: PetType.cat,
      triageLevel: TriageLevel.red,
      preliminaryAssessment:
          'Mèo thở dốc há miệng, nhịp thở > 50 lần/phút, niêm mạc nướu nhợt nhạt. Nghi ngờ tràn dịch màng phổi hoặc phù phổi cấp tính.',
      immediateActions: [
        'Đặt bé vào lồng vận chuyển thông thoáng, tránh để bé bị hoảng loạn hoặc căng thẳng.',
        'Không ép ăn hay ép uống nước vì nguy cơ sặc phổi rất cao.',
        'Đưa bé đến phòng cấp cứu thú y 24/7 gần nhất NGAY BÂY GIỜ!',
      ],
      disclaimer: SessionModel.defaultDisclaimer,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      lastMessage: 'Bác sĩ: Hãy đưa bé đến cấp cứu ngay, không chờ đợi!',
      status: 'active',
    );

    final sessionYellow = SessionModel(
      id: 'zm_seed_102',
      userId: 'user_current',
      petName: 'Cún Lu Lu',
      petType: PetType.dog,
      triageLevel: TriageLevel.yellow,
      preliminaryAssessment:
          'Vùng da quanh tai và cổ xuất hiện quầng đỏ tròn, rụng lông viền vảy gàu. Dấu hiệu điển hình của nhiễm nấm da kết hợp viêm da tiết bã nhờn.',
      immediateActions: [
        'Đeo loa chống liếm để ngăn cún cào gãi làm xước sâu.',
        'Vệ sinh nhẹ nhàng bằng bông gạc tẩm nước muối sinh lý, để ráo tự nhiên.',
        'Cách ly khỏi các thú cưng khác để đề phòng lây nhiễm nấm.',
        'Đưa cún đến bác sĩ thú y trong 24 giờ để làm xét nghiệm soi đèn Wood và cạo da.',
      ],
      disclaimer: SessionModel.defaultDisclaimer,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      lastMessage: 'Bé có bị ngứa nhiều vào ban đêm không bạn?',
      status: 'monitoring',
    );

    final sessionGreen = SessionModel(
      id: 'zm_seed_103',
      userId: 'user_current',
      petName: 'Bông Xù',
      petType: PetType.dog,
      triageLevel: TriageLevel.green,
      preliminaryAssessment:
          'Trầy xước da nhẹ vùng đệm chân sau, vết thương nông, không chảy máu liên tục, thú cưng đi lại bình thường.',
      immediateActions: [
        'Rửa sạch bụi bẩn bằng nước muối sinh lý 0.9%.',
        'Giữ chân khô ráo, hạn chế dắt đi dạo ở chỗ bùn ướt trong 2 ngày.',
        'Theo dõi nếu chân sưng tấy hoặc bé đi khập khiễng thì đưa đi kiểm tra.',
      ],
      disclaimer: SessionModel.defaultDisclaimer,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      lastMessage: 'Tình trạng chân bé đã lành hẳn chưa bạn?',
      status: 'resolved',
    );

    _sessions.addAll([sessionRed, sessionYellow, sessionGreen]);

    _messagesStore[sessionRed.id] = [
      ChatMessage(
        id: 'm1_red',
        text: 'Bé Miu nhà em tự nhiên nằm bẹp, há miệng thở dốc và người rất yếu, em lo quá!',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        id: 'm2_red',
        text:
            '⚠️ CẢNH BÁO KHẨN CẤP: Dấu hiệu mèo há miệng thở là tình trạng suy hô hấp nghiêm trọng. Hãy xem ngay các bước ở Triage Card bên trên và mang bé đến phòng cấp cứu thú y gần nhất ngay lập tức!',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 58)),
      ),
    ];

    _messagesStore[sessionYellow.id] = [
      ChatMessage(
        id: 'm1_yel',
        text: 'Cún Lu Lu bị rụng lông tròn xoe ở cổ, hay lấy chân gãi liên tục.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        id: 'm2_yel',
        text:
            'Chào bạn, hình ảnh cho thấy dấu hiệu viêm nấm da. Bạn nhớ đeo loa chống liếm cho bé để tránh làm trầy xước sâu nhé.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 59)),
      ),
      ChatMessage(
        id: 'm3_yel',
        text: 'Bé có bị ngứa nhiều vào ban đêm không bạn?',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 50)),
      ),
    ];

    _messagesStore[sessionGreen.id] = [
      ChatMessage(
        id: 'm1_grn',
        text: 'Chân bé Bông bị trầy một chút do chạy nhảy ngoài sân xi măng.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ChatMessage(
        id: 'm2_grn',
        text: 'Vết thương khá nông và sạch. Bạn chỉ cần lau nước muối sinh lý hàng ngày là sẽ tự khô nhé.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 23)),
      ),
    ];
  }
}

