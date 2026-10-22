import 'dart:async';
import 'package:flutter/material.dart';

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
      description: 'Nén thuật toán flutter_image_compress xuống ≈300KB',
      icon: Icons.compress_rounded,
    ),
    StepItem(
      title: 'Tải dữ liệu an toàn',
      description: 'Đang upload tệp lên máy chủ Cloud bảo mật',
      icon: Icons.cloud_upload_rounded,
    ),
    StepItem(
      title: 'AI Vision phân tích',
      description: 'Nhận diện tổn thương bề mặt & dấu hiệu bất thường',
      icon: Icons.psychology_rounded,
    ),
    StepItem(
      title: 'Phân loại Triage lâm sàng',
      description: 'Đánh giá mức độ ưu tiên: Xanh / Vàng / Đỏ',
      icon: Icons.health_and_safety_rounded,
    ),
    StepItem(
      title: 'Khởi tạo phòng tư vấn',
      description: 'Kết nối phòng chat trực tuyến thời gian thực',
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
    // Tổng thời gian xấp xỉ 4.2 giây (trong khoảng 3–5 giây theo yêu cầu)
    const totalDurationMs = 4200;
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

    // Chuyển bước từng bước
    const stepDuration = Duration(milliseconds: 800);
    _stepTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _steps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        timer.cancel();
        // Giữ lại 600ms ở bước cuối rồi hoàn tất
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
              color: const Color(0xFF0E8388).withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon pulsing ở giữa
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E8388), Color(0xFF2E4F4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E8388).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            const Text(
              'Đang Khởi Tạo Ca Khám...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hệ thống AI Zoomies đang phân tích tình trạng ${widget.petName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 16),

            // Thanh tiến trình
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến trình xử lý',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E8388),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0E8388)),
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
                  iconColor = const Color(0xFF0E8388);
                  trailingIcon = const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E8388)),
                    ),
                  );
                } else {
                  iconColor = const Color(0xFF94A3B8);
                  trailingIcon = const Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  );
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF0E8388).withValues(alpha: 0.08)
                        : (isDone ? const Color(0xFFF8FAFC) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF0E8388).withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF0E8388).withValues(alpha: 0.15)
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
                                    ? const Color(0xFF0E8388)
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
