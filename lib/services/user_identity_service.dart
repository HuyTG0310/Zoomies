import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý định danh người dùng / thiết bị (Device & Account Identity)
/// Giúp phân quyền lịch sử khám và cuộc trò chuyện theo từng thiết bị hoặc tài khoản riêng biệt.
class UserIdentityService {
  static const String _deviceIdKey = 'zoomies_persistent_device_id';
  static String? _cachedUserId;

  /// Lấy hoặc tạo mới Device ID duy nhất được lưu cố định trên thiết bị này
  static Future<String> getOrCreateDeviceId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString(_deviceIdKey);

      if (savedId == null || savedId.trim().isEmpty) {
        // Tạo chuỗi định danh duy nhất cho thiết bị (vd: zm_dev_1710123456_a8b9)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomPart = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
        savedId = 'zm_dev_${timestamp}_$randomPart';
        await prefs.setString(_deviceIdKey, savedId);
        debugPrint('🔑 [UserIdentityService] Tạo mới DeviceId cố định: $savedId');
      } else {
        debugPrint('🔑 [UserIdentityService] Đã tải DeviceId đã lưu: $savedId');
      }

      _cachedUserId = savedId;
      return savedId;
    } catch (e) {
      debugPrint('[UserIdentityService] Lỗi khi truy cập SharedPreferences: $e');
      _cachedUserId ??= 'zm_dev_fallback_${DateTime.now().millisecondsSinceEpoch}';
      return _cachedUserId!;
    }
  }

  /// Trả về ID người dùng hiện tại (nếu chưa tải từ storage thì dùng ID mặc định trong ram)
  static String get currentUserId {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }
    return 'user_current';
  }

  /// Cho phép cập nhật UserId (vd: khi người dùng đăng nhập tài khoản Firebase Auth)
  static void setUserId(String userId) {
    _cachedUserId = userId;
  }
}
