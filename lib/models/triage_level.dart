import 'package:flutter/material.dart';

enum TriageLevel {
  green,
  yellow,
  red;

  String get label {
    switch (this) {
      case TriageLevel.green:
        return 'Mức Xanh: Không khẩn cấp';
      case TriageLevel.yellow:
        return 'Mức Vàng: Cần theo dõi sát';
      case TriageLevel.red:
        return 'Mức Đỏ: CẤP CỨU KHẨN CẤP';
    }
  }

  String get shortTag {
    switch (this) {
      case TriageLevel.green:
        return 'Mức Xanh';
      case TriageLevel.yellow:
        return 'Mức Vàng';
      case TriageLevel.red:
        return 'Cấp Cứu';
    }
  }

  Color get primaryColor {
    switch (this) {
      case TriageLevel.green:
        return const Color(0xFF10B981); // Emerald Green
      case TriageLevel.yellow:
        return const Color(0xFFF59E0B); // Amber Yellow
      case TriageLevel.red:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TriageLevel.green:
        return const Color(0xFFECFDF5);
      case TriageLevel.yellow:
        return const Color(0xFFFFFBEB);
      case TriageLevel.red:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case TriageLevel.green:
        return const Color(0xFFA7F3D0);
      case TriageLevel.yellow:
        return const Color(0xFFFDE68A);
      case TriageLevel.red:
        return const Color(0xFFFECACA);
    }
  }

  Color get textColor {
    switch (this) {
      case TriageLevel.green:
        return const Color(0xFF065F46);
      case TriageLevel.yellow:
        return const Color(0xFF92400E);
      case TriageLevel.red:
        return const Color(0xFF991B1B);
    }
  }

  IconData get icon {
    switch (this) {
      case TriageLevel.green:
        return Icons.check_circle_rounded;
      case TriageLevel.yellow:
        return Icons.warning_amber_rounded;
      case TriageLevel.red:
        return Icons.emergency_rounded;
    }
  }

  String get recommendation {
    switch (this) {
      case TriageLevel.green:
        return 'Tình trạng tương đối ổn định. Có thể theo dõi và chăm sóc hỗ trợ tại nhà.';
      case TriageLevel.yellow:
        return 'Có dấu hiệu bất thường. Cần theo dõi sát và nên sắp xếp đi khám thú y trong 12–24h tới.';
      case TriageLevel.red:
        return 'CẢNH BÁO NGUY HIỂM: Thú cưng cần được đưa tới phòng khám thú y gần nhất NGAY LẬP TỨC!';
    }
  }
}

