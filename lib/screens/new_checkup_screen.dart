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

  CompressedImageResult? _compressedResult;
  bool _isCompressing = false;

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

  // Chụp/chọn ảnh và nén qua flutter_image_compress xuống ≈ 300KB
  Future<void> _pickAndCompressImage(ImageSource source) async {
    setState(() {
      _isCompressing = true;
    });

    try {
      final xfile = await ImageCompressionService.pickImage(source);
      if (xfile != null) {
        // Nén ảnh xuống xấp xỉ ~300KB theo yêu cầu
        final result = await ImageCompressionService.compressToTargetSize(
          xfile,
          targetKb: 300,
        );

        if (mounted) {
          setState(() {
            _compressedResult = result;
            _isCompressing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0E8388),
              behavior: SnackBarBehavior.floating,
              content: Text(
                '✅ Đã nén ảnh: ${result.originalFormatted} ➔ ${result.compressedFormatted} (giảm ${result.compressionRatio.toStringAsFixed(0)}%)',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isCompressing = false;
          });
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
    if (_compressedResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp hoặc tải ảnh biểu hiện của thú cưng lên trước.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final petName = _nameController.text.trim().isEmpty
        ? (_selectedPetType == PetType.dog ? 'Bé Cún' : 'Bé Mèo')
        : _nameController.text.trim();

    // Mở StepLoadingOverlay modal duy trì 3–5 giây
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StepLoadingOverlay(
          petName: petName,
          onFinished: () async {
            // Đóng dialog loading
            Navigator.of(dialogCtx).pop();

            // Khởi tạo session trong service
            final newSession = await SessionService.instance.createNewSession(
              petType: _selectedPetType,
              petName: petName,
              imageBytes: _compressedResult?.bytes,
              preliminaryNote: _symptomController.text.trim(),
            );

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

            // 2. CHỤP ẢNH / CHỌN ẢNH + NÉN ẢNH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Chụp / Tải ảnh tổn thương',
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
                  child: const Text(
                    'Nén tự động ≈300KB',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E8388),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Khung chọn ảnh & xem trước
            _buildImagePickerBox(),

            const SizedBox(height: 20),

            // 3. MÔ TẢ TRIỆU CHỨNG SƠ BỘ
            const Text(
              '3. Mô tả triệu chứng nhận thấy',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _compressedResult != null ? _startCheckup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E8388),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  elevation: 2,
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
                      _compressedResult == null
                          ? 'Vui lòng chọn ảnh trước'
                          : 'Bắt Đầu Đánh Giá & Phân Loại Triage',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
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
        height: 180,
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
            SizedBox(height: 14),
            Text(
              'Đang chạy thuật toán nén ảnh flutter_image_compress...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E8388),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tối ưu kích thước xuống ≈300KB giữ nguyên độ nét chi tiết',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (_compressedResult != null) {
      final res = _compressedResult!;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0E8388).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                res.bytes,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            // Thống kê nén ảnh
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Ảnh gốc: ${res.originalFormatted}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                      ),
                      const Text(' ➔ ', style: TextStyle(color: Color(0xFF94A3B8))),
                      Text(
                        'Nén: ${res.compressedFormatted}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${res.compressionRatio.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourcePicker,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đổi ảnh khác', style: TextStyle(fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _compressedResult = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Xóa ảnh',
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
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
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
                size: 38,
                color: Color(0xFF0E8388),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chạm để chụp hoặc tải ảnh lên',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bắt buộc nén xuống ≈300KB nhằm tăng tốc độ xử lý AI',
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
