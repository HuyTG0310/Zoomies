import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class CompressedImageResult {
  final Uint8List bytes;
  final int originalSizeInBytes;
  final int compressedSizeInBytes;
  final String fileName;

  CompressedImageResult({
    required this.bytes,
    required this.originalSizeInBytes,
    required this.compressedSizeInBytes,
    required this.fileName,
  });

  double get originalKb => originalSizeInBytes / 1024;
  double get compressedKb => compressedSizeInBytes / 1024;
  double get compressionRatio =>
      originalSizeInBytes > 0
          ? ((1 - (compressedSizeInBytes / originalSizeInBytes)) * 100).clamp(0, 100)
          : 0;

  String get originalFormatted =>
      originalKb > 1024
          ? '${(originalKb / 1024).toStringAsFixed(2)} MB'
          : '${originalKb.toStringAsFixed(1)} KB';

  String get compressedFormatted =>
      compressedKb > 1024
          ? '${(compressedKb / 1024).toStringAsFixed(2)} MB'
          : '${compressedKb.toStringAsFixed(1)} KB';
}

class ImageCompressionService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from Camera or Gallery
  static Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Nén ảnh bằng `flutter_image_compress` xuống xấp xỉ ~300 KB
  static Future<CompressedImageResult> compressToTargetSize(
    XFile xfile, {
    int targetKb = 300,
  }) async {
    final Uint8List rawBytes = await xfile.readAsBytes();
    final int originalSize = rawBytes.lengthInBytes;
    final int targetBytes = targetKb * 1024;

    // If image is already smaller than target, gentle compression or return
    if (originalSize <= targetBytes) {
      return CompressedImageResult(
        bytes: rawBytes,
        originalSizeInBytes: originalSize,
        compressedSizeInBytes: originalSize,
        fileName: xfile.name,
      );
    }

    try {
      // Bắt đầu với chất lượng tương ứng theo tỷ lệ ước tính
      int quality = 80;
      if (originalSize > 5 * 1024 * 1024) {
        quality = 55;
      } else if (originalSize > 2 * 1024 * 1024) {
        quality = 68;
      }

      Uint8List currentBytes = rawBytes;

      // Nén lần 1 bằng FlutterImageCompress
      final compressed = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      currentBytes = compressed;

      // Nếu vẫn vượt ngưỡng target + 15%, nén tiếp bước 2
      if (currentBytes.lengthInBytes > (targetBytes * 1.15) && quality > 40) {
        final recompressed = await FlutterImageCompress.compressWithList(
          currentBytes,
          minWidth: 1024,
          minHeight: 1024,
          quality: (quality * 0.75).round(),
          format: CompressFormat.jpeg,
        );
        currentBytes = recompressed;
      }

      return CompressedImageResult(
        bytes: currentBytes,
        originalSizeInBytes: originalSize,
        compressedSizeInBytes: currentBytes.lengthInBytes,
        fileName: xfile.name,
      );
    } catch (e) {
      debugPrint('Lỗi nén ảnh với FlutterImageCompress: $e. Sử dụng ảnh gốc.');
      return CompressedImageResult(
        bytes: rawBytes,
        originalSizeInBytes: originalSize,
        compressedSizeInBytes: originalSize,
        fileName: xfile.name,
      );
    }
  }
}
