import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StepItem {
  final String title;
  final String description;
  final IconData icon;

  const StepItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class StepLoadingOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final String petName;

  const StepLoadingOverlay({
    super.key,
    required this.onFinished,
    this.petName = 'thú cưng',
  });

  @override
  State<StepLoadingOverlay> createState() => _StepLoadingOverlayState();
}

class _StepLoadingOverlayState extends State<StepLoadingOverlay>
    with SingleTickerProviderStateMixin {
  final List<StepItem> _steps = const [
    StepItem(
      title: 'Tối ưu hóa hình ảnh',
      description: 'Nén thông minh thuật toán giữ nguyên độ sắc nét',
      icon: Icons.compress_rounded,
    ),
    StepItem(
      title: 'Truyền tải mã hóa',
      description: 'Gửi dữ liệu qua kênh bảo mật SSL/TLS Cloud',
      icon: Icons.cloud_upload_rounded,
    ),
    StepItem(
      title: 'Gemini AI Vision phân tích',
      description: 'Nhận diện tổn thương bề mặt & bệnh lý lâm sàng',
      icon: Icons.psychology_rounded,
    ),
    StepItem(
      title: 'Phân loại Triage cấp tốc',
      description: 'Xác định mức khẩn cấp: Xanh / Vàng / Đỏ',
      icon: Icons.health_and_safety_rounded,
    ),
    StepItem(
      title: 'Khởi tạo phòng khám',
      description: 'Kết nối phòng tư vấn AI trực tuyến thời gian thực',
      icon: Icons.forum_rounded,
    ),
  ];

  int _currentStepIndex = 0;
  double _progress = 0.0;
  Timer? _stepTimer;
  Timer? _progressTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startSequentialProgress();
  }

  void _startSequentialProgress() {
    const totalDurationMs = 4000;
    const intervalMs = 50;
    final increment = intervalMs / totalDurationMs;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      setState(() {
        _progress = (_progress + increment).clamp(0.0, 1.0);
      });
      if (_progress >= 1.0) {
        timer.cancel();
      }
    });

    const stepDuration = Duration(milliseconds: 750);
    _stepTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _steps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            widget.onFinished();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stepTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot pulsing ở giữa
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.splashBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            const Text(
              'Đang Phân Tích Ca Khám...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI Zoomies đang chẩn đoán hình ảnh và triệu chứng của ${widget.petName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 18),

            // Thanh tiến trình
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ xử lý',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Danh sách các bước dạng checklist động
            Column(
              children: List.generate(_steps.length, (index) {
                final step = _steps[index];
                final isDone = index < _currentStepIndex;
                final isCurrent = index == _currentStepIndex;

                Color iconColor;
                Widget trailingIcon;

                if (isDone) {
                  iconColor = const Color(0xFF10B981);
                  trailingIcon = const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  );
                } else if (isCurrent) {
                  iconColor = primaryColor;
                  trailingIcon = const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );
                } else {
                  iconColor = const Color(0xFF94A3B8);
                  trailingIcon = const Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 19,
                  );
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? primaryColor.withValues(alpha: 0.08)
                        : (isDone ? const Color(0xFFF8FAFC) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? primaryColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? primaryColor.withValues(alpha: 0.15)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(step.icon, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isCurrent ? FontWeight.w700 : FontWeight.w600,
                                color: isCurrent
                                    ? const Color(0xFF0F172A)
                                    : (isDone
                                        ? const Color(0xFF334155)
                                        : const Color(0xFF94A3B8)),
                              ),
                            ),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isCurrent
                                    ? primaryColor
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailingIcon,
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 6),
            const Text(
              '⏱️ Quá trình phân tích mất khoảng 3–5 giây',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
