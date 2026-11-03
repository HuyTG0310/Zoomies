import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
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
    '💊 Có nên bôi thuốc sát trùng không?',
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
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar thú cưng với viền theo màu Triage
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: level.backgroundColor,
                border: Border.all(color: level.borderColor, width: 2),
              ),
              child: Center(
                child: Text(
                  session.petType.emoji,
                  style: const TextStyle(fontSize: 20),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: level.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: level.borderColor),
                        ),
                        child: Text(
                          level.shortTag,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: level.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                      SizedBox(width: 5),
                      Text(
                        'Phòng khám AI trực tuyến 24/7',
                        style: TextStyle(
                          fontSize: 11.5,
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // PHẦN TRÊN: THANH TRIAGE LEVEL Y TẾ
            // ==========================================
            TriageHeaderCard(
              session: session,
              onQuestionSelected: (question) => _handleSendMessage(question),
            ),

            // ==========================================
            // PHẦN DƯỚI: KHUNG CHAT (StreamBuilder từ Firestore)
            // ==========================================
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: SessionService.instance.streamMessages(session.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                    padding: const EdgeInsets.only(top: 10, bottom: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubbleWidget(message: msg);
                    },
                  );
                },
              ),
            ),

            // 💡 Gợi ý câu hỏi nhanh (Quick Question Chips)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: _quickSuggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => _handleSendMessage(suggestion),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ==========================================
            // THANH NHẬP TIN NHẮN DƯỚI CÙNG
            // ==========================================
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    final primaryColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ô nhập văn bản
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
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
                  hintText: 'Hỏi thêm bác sĩ về triệu chứng của bé...',
                  hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                  filled: false,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Nút gửi tin nhắn dạng tròn với gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
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
              tooltip: 'Gửi tin nhắn',
              onPressed: _isSending ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
