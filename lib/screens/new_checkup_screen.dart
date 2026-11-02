import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_type.dart';
import '../services/image_compression_service.dart';
import '../services/session_service.dart';
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

  // Mở modal chọn Camera hoặc Thư viện ảnh
  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Chọn ảnh vị trí tổn thương / thú cưng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ảnh rõ nét giúp AI Zoomies phân loại mức Triage chính xác hơn',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E8388).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0E8388).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 36,
                                color: Color(0xFF0E8388),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Chụp ảnh ngay',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0E8388),
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
        // Thư viện ảnh: cho phép chọn nhiều ảnh (tối đa còn thiếu)
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
            // Đợi kết quả hoàn thành từ Gemini
            final newSession = await sessionFuture;

            // Đóng dialog loading
            if (dialogCtx.mounted) {
              Navigator.of(dialogCtx).pop();
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tạo Ca Khám Mới',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CHỌN LOẠI THÚ CƯNG (Chó / Mèo)
            const Text(
              '1. Chọn loại thú cưng',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPetTypeOption(PetType.dog),
                const SizedBox(width: 14),
                _buildPetTypeOption(PetType.cat),
              ],
            ),

            const SizedBox(height: 20),

            // Tên thú cưng (tùy chọn)
            const Text(
              'Tên của bé (tùy chọn)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: _selectedPetType == PetType.dog ? 'Ví dụ: Lu Lu, Bông...' : 'Ví dụ: Miu, Bơ...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0E8388), width: 1.6),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. CHỤP ẢNH / CHỌN ẢNH (Tối đa 3 ảnh)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Ảnh biểu hiện / tổn thương',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E8388).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_compressedImages.length}/3 ảnh',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E8388),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Khung chọn ảnh & xem trước (Hỗ trợ tối đa 3 ảnh)
            _buildImagePickerBox(),

            const SizedBox(height: 20),

            // 3. MÔ TẢ TRIỆU CHỨNG (BẮT BUỘC)
            const Row(
              children: [
                Text(
                  '3. Mô tả triệu chứng nhận thấy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '* (Bắt buộc)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _symptomController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Bé gãi tai liên tục, rụng lông thành mảng đỏ, thở nhanh, bỏ ăn từ sáng...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0E8388), width: 1.6),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // NÚT BẮT ĐẦU ĐÁNH GIÁ (TRIGGER 3-5s LOADING OVERLAY)
            Builder(
              builder: (context) {
                final hasSymptoms = _symptomController.text.trim().isNotEmpty;
                final hasImages = _compressedImages.isNotEmpty;
                final canSubmit = hasSymptoms && hasImages;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startCheckup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit ? const Color(0xFF0E8388) : const Color(0xFF94A3B8),
                      elevation: canSubmit ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          canSubmit
                              ? 'Bắt Đầu Đánh Giá & Phân Loại Triage'
                              : (!hasImages
                                  ? 'Vui lòng chọn ảnh (tối đa 3)'
                                  : 'Vui lòng nhập mô tả triệu chứng'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),
            const Center(
              child: Text(
                '🔒 Hình ảnh được nén bảo mật và phân tích riêng tư',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetTypeOption(PetType type) {
    final isSelected = _selectedPetType == type;
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
            color: isSelected ? const Color(0xFF0E8388).withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0E8388) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF0E8388).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF0E8388) : const Color(0xFF334155),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0E8388),
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
    if (_isCompressing) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E8388)),
            ),
            SizedBox(height: 12),
            Text(
              'Đang xử lý và tối ưu hình ảnh...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E8388),
              ),
            ),
          ],
        ),
      );
    }

    if (_compressedImages.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0E8388).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _compressedImages.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _compressedImages[i].bytes,
                          width: 95,
                          height: 95,
                          fit: BoxFit.cover,
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
                              color: Colors.black54,
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
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ảnh ${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E8388).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0E8388).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF0E8388),
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thêm ảnh\n(${_compressedImages.length}/3)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0E8388),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã chọn ${_compressedImages.length}/3 ảnh',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _compressedImages.clear();
                    });
                  },
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Trạng thái chưa chọn ảnh
    return InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E8388).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 34,
                color: Color(0xFF0E8388),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chạm để chụp hoặc tải ảnh lên (Tối đa 3 ảnh)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chụp rõ vị trí tổn thương hoặc biểu hiện của thú cưng',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
