import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_level.dart';
import 'triage_badge.dart';

class TriageHeaderCard extends StatefulWidget {
  final SessionModel session;
  final bool initialExpanded;
  final VoidCallback? onEmergencyCall;

  const TriageHeaderCard({
    super.key,
    required this.session,
    this.initialExpanded = true,
    this.onEmergencyCall,
  });

  @override
  State<TriageHeaderCard> createState() => _TriageHeaderCardState();
}

class _TriageHeaderCardState extends State<TriageHeaderCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.session.triageLevel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: level.borderColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: level.primaryColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Top Bar (luôn hiển thị, nhấn vào để mở/thu gọn)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: level.backgroundColor,
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(18))
                    : BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  TriageBadge(level: level, isCompact: !_isExpanded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded
                          ? 'Bảng Đánh Giá Triage Lâm Sàng'
                          : widget.session.preliminaryAssessment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: level.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Thu gọn' : 'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: level.textColor,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: level.textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung chi tiết có thể thu gọn (Collapsible Content)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Nhận định sơ bộ (Preliminary Assessment)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E8388).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 16,
                          color: Color(0xFF0E8388),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nhận định sơ bộ (Preliminary Assessment)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      widget.session.preliminaryAssessment,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Việc cần làm ngay (Immediate Actions / First Aid)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: level.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.checklist_rounded,
                          size: 16,
                          color: level.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Việc cần làm ngay (Sơ cứu & Chăm sóc):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: level.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.session.immediateActions.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final actionText = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: level.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              actionText,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Nút gọi cấp cứu khẩn cấp nếu là Mức Đỏ
                  if (level == TriageLevel.red) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: widget.onEmergencyCall ??
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang kết nối trung tâm cấp cứu thú y 24/7 gần nhất...'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'GỌI CẤP CỨU THÚ Y NGAY (24/7)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // 3. Dòng chữ Disclaimer (Miễn trừ trách nhiệm y tế)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.session.disclaimer,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF475569),
                              height: 1.35,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
