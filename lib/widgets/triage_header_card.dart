import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_level.dart';
import '../theme/app_colors.dart';
import 'triage_badge.dart';

/// Thanh hiển thị cấp độ Triage y tế (Medical Triage Bar)
/// Cung cấp thông tin trực quan về mức độ khẩn cấp, nút cấp cứu nhanh và xem chi tiết phác đồ.
class TriageHeaderCard extends StatelessWidget {
  final SessionModel session;
  final bool initialExpanded;
  final VoidCallback? onEmergencyCall;
  final ValueChanged<String>? onQuestionSelected;

  const TriageHeaderCard({
    super.key,
    required this.session,
    this.initialExpanded = false,
    this.onEmergencyCall,
    this.onQuestionSelected,
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
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
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
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Cảnh báo nếu Mức Đỏ (Cấp cứu)
                  if (level == TriageLevel.red) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CẦN ĐƯA ĐI CẤP CỨU NGAY',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tình trạng đe dọa sinh mạng. Đưa bé đến bệnh viện thú y gần nhất!',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (onEmergencyCall != null) {
                                onEmergencyCall!();
                              }
                            },
                            icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                            label: const Text('Gọi 115', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (session.isIrrelevantImage) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ảnh tải lên chưa rõ tổn thương thú cưng. Kết quả Triage dựa chủ yếu vào mô tả triệu chứng.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Nhận định sơ bộ
                  _buildSectionHeader(Icons.summarize_rounded, 'Nhận định sơ bộ từ AI:'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      session.preliminaryAssessment,
                      style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Các bước xử lý ngay tại nhà
                  if (session.immediateActions.isNotEmpty) ...[
                    _buildSectionHeader(Icons.healing_rounded, 'Các bước xử lý ngay tại nhà:'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < session.immediateActions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: level.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                session.immediateActions[i],
                                style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Miễn trừ trách nhiệm y tế
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.disclaimer,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = session.triageLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level.borderColor,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: level.primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge cấp độ
          TriageBadge(level: level, isCompact: true),
          const SizedBox(width: 10),

          // Tóm tắt tình trạng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level == TriageLevel.red
                      ? 'CẤP CỨU KHẨN CẤP!'
                      : (level == TriageLevel.yellow ? 'Cần theo dõi sát sao' : 'Thể trạng ổn định'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: level.textColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Chạm để xem các bước sơ cứu chi tiết',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: level.textColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                      content: Text('Đang kết nối hotline cấp cứu thú y 24/7...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
            const SizedBox(width: 8),
          ],

          // Nút mở BottomSheet chi tiết
          InkWell(
            onTap: () => _showDetailSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: level.borderColor),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: level.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
