import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_level.dart';
import 'triage_badge.dart';

/// Thanh hiển thị cấp độ Triage tinh gọn (Compact Triage Bar)
/// Chỉ hiển thị cấp độ khẩn cấp (Level) và nút cấp cứu (nếu ĐỎ),
/// không chiếm diện tích màn hình để nhường toàn bộ không gian cho cuộc trò chuyện.
class TriageHeaderCard extends StatelessWidget {
  final SessionModel session;
  final bool initialExpanded;
  final VoidCallback? onEmergencyCall;

  const TriageHeaderCard({
    super.key,
    required this.session,
    this.initialExpanded = false,
    this.onEmergencyCall,
  });

  void _showDetailSheet(BuildContext context) {
    final level = session.triageLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TriageBadge(level: level, isCompact: false),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (session.isIrrelevantImage) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ảnh tải lên có vẻ không chứa thú cưng hoặc tổn thương thú cưng. Kết quả dựa trên mô tả văn bản.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Text(
                    '📌 Nhận định sơ bộ:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      session.preliminaryAssessment,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (session.immediateActions.isNotEmpty) ...[
                    const Text(
                      '🚨 Các bước xử lý ngay tại nhà:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < session.immediateActions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: level.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.immediateActions[i],
                                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.disclaimer,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = session.triageLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: level.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: level.primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge hiển thị Cấp độ Triage tinh gọn
          TriageBadge(level: level, isCompact: true),
          const SizedBox(width: 8),

          // Cảnh báo nếu ảnh không liên quan
          if (session.isIrrelevantImage)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Ảnh không liên quan',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
              ),
            ),

          Expanded(
            child: Text(
              level == TriageLevel.red
                  ? 'Cần cấp cứu khẩn cấp!'
                  : (level == TriageLevel.yellow ? 'Theo dõi sát' : 'Ổn định tại nhà'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: level.textColor,
              ),
            ),
          ),

          // Nút gọi cấp cứu khẩn cấp nếu là Mức ĐỎ
          if (level == TriageLevel.red) ...[
            InkWell(
              onTap: () {
                if (onEmergencyCall != null) {
                  onEmergencyCall!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang kết nối tổng đài cấp cứu thú y: 1900 6868...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Cấp cứu',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Nút xem chi tiết Triage dạng Modal Sheet
          InkWell(
            onTap: () => _showDetailSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: level.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
