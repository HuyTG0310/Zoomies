import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_type.dart';
import '../services/image_compression_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/step_loading_overlay.dart';
import 'hybrid_triage_chat_screen.dart';

class NewCheckupScreen extends StatefulWidget {
  const NewCheckupScreen({super.key});

  @override
  State<NewCheckupScreen> createState() => _NewCheckupScreenState();
}

class _NewCheckupScreenState extends State<NewCheckupScreen> {
  PetType _selectedPetType = PetType.dog;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symptomController = TextEditingController();

  final List<CompressedImageResult> _compressedImages = [];
  bool _isCompressing = false;
  bool _isSubmitting = false;

  final List<String> _quickSymptomTags = const [
    '🩹 Vết thương hở / chảy máu',
    '🤮 Nôn mửa / bỏ ăn',
    '🫁 Thở gấp / há mồm',
    '🦟 Ngứa gãi / rụng lông',
    '🐾 Khập khiễng / đau chân',
    '💩 Tiêu chảy / phân lỏng',
    '🔥 Người nóng / sốt',
    '💤 Lờ đờ / mệt mỏi',
  ];

  @override
  void initState() {
    super.initState();
    _symptomController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  void _toggleSymptomTag(String tag) {
    // Lấy nội dung chữ từ tag (bỏ emoji phía trước để văn bản tự nhiên hơn)
    final cleanText = tag.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '').trim();
    final currentText = _symptomController.text;

    if (currentText.contains(cleanText)) {
      // Bỏ tag nếu đã có
      String updated = currentText.replaceAll(cleanText, '').trim();
      updated = updated.replaceAll(RegExp(r',\s*,'), ',').replaceAll(RegExp(r'^,\s*|,\s*$'), '');
      _symptomController.text = updated;
    } else {
      // Thêm tag vào
      if (currentText.trim().isEmpty) {
        _symptomController.text = cleanText;
      } else {
        _symptomController.text = '$currentText, $cleanText';
      }
    }
    _symptomController.selection = TextSelection.fromPosition(
      TextPosition(offset: _symptomController.text.length),
    );
  }

  // Mở modal chọn Camera hoặc Thư viện ảnh
  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Tải ảnh biểu hiện / tổn thương',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chụp rõ vết thương hoặc tư thế bất thường của bé giúp Gemini AI phân loại Triage chuẩn xác nhất.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickAndCompressImage(ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Chụp ảnh ngay',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickAndCompressImage(ImageSource.gallery);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 36,
                                color: Color(0xFF475569),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Chọn từ thư viện',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Chụp/chọn ảnh và nén qua flutter_image_compress (hỗ trợ tối đa 3 ảnh)
  Future<void> _pickAndCompressImage(ImageSource source) async {
    if (_compressedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã chọn tối đa 3 ảnh.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCompressing = true;
    });

    try {
      if (source == ImageSource.camera) {
        final xfile = await ImageCompressionService.pickImage(source);
        if (xfile != null) {
          final result = await ImageCompressionService.compressToTargetSize(
            xfile,
            targetKb: 300,
          );

          if (mounted && _compressedImages.length < 3) {
            setState(() {
              _compressedImages.add(result);
              _isCompressing = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isCompressing = false;
            });
          }
        }
      } else {
        final int remaining = 3 - _compressedImages.length;
        final pickedFiles = await ImageCompressionService.pickMultiImage(limit: remaining);
        if (pickedFiles.isNotEmpty) {
          for (final xfile in pickedFiles.take(remaining)) {
            final result = await ImageCompressionService.compressToTargetSize(
              xfile,
              targetKb: 300,
            );
            if (_compressedImages.length < 3) {
              _compressedImages.add(result);
            }
          }
          if (mounted) {
            setState(() {
              _isCompressing = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isCompressing = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bắt đầu tạo ca khám + Hiển thị Loading từng bước 3-5s
  void _startCheckup() {
    if (_isSubmitting) return;

    final symptoms = _symptomController.text.trim();
    if (symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả triệu chứng của thú cưng để AI đánh giá tình trạng.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_compressedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp hoặc tải ít nhất 1 ảnh (tối đa 3 ảnh) biểu hiện của bé.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final petName = _nameController.text.trim().isEmpty
        ? (_selectedPetType == PetType.dog ? 'Bé Cún' : 'Bé Mèo')
        : _nameController.text.trim();

    // Khởi chạy đồng thời yêu cầu phân tích Triage từ Gemini trong lúc giao diện hiển thị 4 bước loading
    final sessionFuture = SessionService.instance.createNewSession(
      petType: _selectedPetType,
      petName: petName,
      imageBytes: _compressedImages.first.bytes,
      imagesBytes: _compressedImages.map((e) => e.bytes).toList(),
      preliminaryNote: symptoms,
    );

    // Mở StepLoadingOverlay modal duy trì 3–5 giây
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StepLoadingOverlay(
          petName: petName,
          onFinished: () async {
            try {
              // Đợi kết quả hoàn thành từ Gemini
              final newSession = await sessionFuture;

              // Đóng dialog loading
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }

              // Xóa sạch dữ liệu form cũ sau khi khám thành công để không bị trùng lặp
              _symptomController.clear();
              _nameController.clear();
              _compressedImages.clear();
              if (mounted) {
                setState(() {
                  _isSubmitting = false;
                });
              }

              // Điều hướng sang Màn hình Hybrid (Triage & Chat)
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HybridTriageChatScreen(session: newSession),
                  ),
                );
              }
            } catch (e) {
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
              if (mounted) {
                setState(() {
                  _isSubmitting = false;
                });
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primary;
    const slateMedium = Color(0xFF334155);

    final hasSymptoms = _symptomController.text.trim().isNotEmpty;
    final hasImages = _compressedImages.isNotEmpty;
    final canSubmit = hasSymptoms && hasImages && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo_full.png',
          height: 34,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.splashBlueLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.splashBlue.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3.5, backgroundColor: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'AI 24/7',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 HERO BANNER: THÂN THIỆN & CHUYÊN NGHIỆP
            _buildHeroBanner(),

            const SizedBox(height: 20),

            // 🐾 PHẦN 1: THÔNG TIN THÚ CƯNG
            _buildSectionCard(
              title: '1. Thú cưng cần kiểm tra',
              subtitle: 'Chọn loài và nhập tên bé',
              icon: Icons.pets_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPetTypeOption(PetType.dog),
                      const SizedBox(width: 12),
                      _buildPetTypeOption(PetType.cat),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF64748B), size: 20),
                      hintText: _selectedPetType == PetType.dog
                          ? 'Tên cún (ví dụ: Lu Lu, Milo...)'
                          : 'Tên mèo (ví dụ: Miu, Bơ...)',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📸 PHẦN 2: ẢNH BIỂU HIỆN / TỔN THƯƠNG
            _buildSectionCard(
              title: '2. Ảnh chụp biểu hiện / tổn thương',
              subtitle: 'Tải 1–3 ảnh rõ nét để AI phân tích chuẩn xác',
              icon: Icons.camera_alt_rounded,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_compressedImages.length}/3 ảnh',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
              child: _buildImagePickerBox(),
            ),

            const SizedBox(height: 16),

            // 🩺 PHẦN 3: TRIỆU CHỨNG LÂM SÀNG
            _buildSectionCard(
              title: '3. Triệu chứng nhận thấy',
              subtitle: 'Chọn nhanh từ khóa hoặc gõ mô tả cụ thể',
              icon: Icons.medical_services_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Tag Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickSymptomTags.map((tag) {
                      final cleanText = tag.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '').trim();
                      final isSelected = _symptomController.text.contains(cleanText);

                      return InkWell(
                        onTap: () => _toggleSymptomTag(tag),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? primaryColor : slateMedium,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _symptomController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Mô tả thêm: Bé bị từ khi nào, ăn uống ra sao, có nôn mửa hoặc co giật không...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🚀 NÚT BẮT ĐẦU ĐÁNH GIÁ (GRADIENT CALL TO ACTION)
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: canSubmit ? AppColors.primaryGradient : null,
                boxShadow: canSubmit
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: _startCheckup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit ? Colors.transparent : const Color(0xFFCBD5E1),
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canSubmit ? Icons.bolt_rounded : Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canSubmit
                          ? 'Bắt Đầu Phân Loại Triage Ngay'
                          : (!hasImages
                              ? 'Chụp hoặc tải ít nhất 1 ảnh'
                              : 'Vui lòng nhập triệu chứng'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🛡️ BẢO MẬT & MIỄN TRỪ TRUY CẬP
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Được phân tích bảo mật bởi Gemini AI • Chuẩn cấp cứu Triage quốc tế',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ Lý Bác Sĩ AI Zoomies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Đánh giá mức độ khẩn cấp (Xanh - Vàng - Đỏ) & hướng dẫn sơ cứu tức thì cho cún và mèo.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFE0F2FE),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPetTypeOption(PetType type) {
    final isSelected = _selectedPetType == type;
    final isDog = type == PetType.dog;
    final activeBorderColor = isDog ? AppColors.dogGold : AppColors.primary;
    final activeBgColor = isDog ? AppColors.dogGoldSurface : AppColors.primarySurface;
    final activeTextColor = isDog ? AppColors.dogGoldDark : AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPetType = type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeBorderColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.emoji,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 10),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? activeTextColor : const Color(0xFF334155),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  color: activeBorderColor,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox() {
    const primaryColor = AppColors.primary;

    if (_isCompressing) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Đang nén & tối ưu hình ảnh...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_compressedImages.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _compressedImages.length; i++)
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _compressedImages[i].bytes,
                          width: 95,
                          height: 95,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _compressedImages.removeAt(i);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _compressedImages[i].compressedFormatted,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_compressedImages.length < 3)
                InkWell(
                  onTap: _showImageSourcePicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: primaryColor,
                          size: 26,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✓ Đã tối ưu dung lượng cho AI Gemini Vision',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _compressedImages.clear();
                  });
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Trạng thái chưa chọn ảnh
    return InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 28,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chạm để chụp hoặc chọn ảnh (Tối đa 3 ảnh)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ảnh chụp cận cảnh vết thương hoặc mắt, mũi, da của thú cưng',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
