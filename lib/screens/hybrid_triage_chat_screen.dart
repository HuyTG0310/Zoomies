import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/triage_header_card.dart';

class HybridTriageChatScreen extends StatefulWidget {
  final SessionModel session;

  const HybridTriageChatScreen({
    super.key,
    required this.session,
  });

  @override
  State<HybridTriageChatScreen> createState() => _HybridTriageChatScreenState();
}

class _HybridTriageChatScreenState extends State<HybridTriageChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<String> _quickSuggestions = const [
    '🌡️ Bé có bị sốt không bác sĩ?',
    '💊 Có nên bôi cồn hay thuốc mỡ không?',
    '🍖 Nên cho ăn uống thế nào lúc này?',
    '🏥 Dấu hiệu nào phải đưa đi cấp cứu ngay?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Khi người dùng bấm gửi → Gọi Cloud Function sendChatMessage
  Future<void> _handleSendMessage([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      /*
      // ĐOẠN CODE GỌI TRỰC TIẾP CLOUD FUNCTION (KHI BẠN ĐÃ SET UP FIREBASE):
      // final callable = FirebaseFunctions.instance.httpsCallable('sendChatMessage');
      // await callable.call({
      //   'sessionId': widget.session.id,
      //   'text': text,
      // });
      */

      // Gọi thông qua SessionService (chuẩn kiến trúc repository)
      await SessionService.instance.sendChatMessage(
        sessionId: widget.session.id,
        text: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tin nhắn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final level = session.triageLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.8,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar thú cưng với viền theo màu Triage
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: level.backgroundColor,
                border: Border.all(color: level.primaryColor, width: 2),
              ),
              child: Center(
                child: Text(
                  session.petType.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          session.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: level.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level.shortTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: level.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                      SizedBox(width: 4),
                      Text(
                        'Phòng khám AI đang trực tuyến',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF475569)),
            tooltip: 'Chia sẻ ca khám',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết ca khám')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // PHẦN TRÊN: TRIAGE CARD (Ghim cố định & Thu gọn được)
            // ==========================================
            TriageHeaderCard(
              session: session,
              initialExpanded: true,
            ),

            // ==========================================
            // PHẦN DƯỚI: KHUNG CHAT (StreamBuilder từ Firestore)
            // Lắng nghe sessions/{sessionId}/messages
            // ==========================================
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                // Stream lắng nghe trực tiếp từ Firestore subcollection
                stream: SessionService.instance.streamMessages(session.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E8388)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text('Lỗi kết nối Firestore: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có tin nhắn trong ca khám này.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    );
                  }

                  // Tự động cuộn xuống tin nhắn mới nhất
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubbleWidget(message: msg);
                    },
                  );
                },
              ),
            ),

            // Gợi ý câu hỏi nhanh (Quick Question Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: _quickSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ActionChip(
                      label: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E8388),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: const Color(0xFF0E8388).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () => _handleSendMessage(suggestion),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ==========================================
            // THANH NHẬP TIN NHẮN DƯỚI CÙNG
            // Khi bấm gửi → Gọi Cloud Function sendChatMessage
            // ==========================================
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút đính kèm ảnh chụp bổ sung
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            color: const Color(0xFF64748B),
            tooltip: 'Gửi thêm ảnh',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đính kèm thêm ảnh trong chat')),
              );
            },
          ),

          // Ô nhập văn bản
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Hỏi thêm bác sĩ về triệu chứng...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Nút gửi tin nhắn (gọi Cloud Function sendChatMessage)
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E8388), Color(0xFF2E4F4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E8388).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              tooltip: 'Gửi qua Cloud Function sendChatMessage',
              onPressed: _isSending ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
