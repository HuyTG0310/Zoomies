import 'package:flutter/material.dart';

/// Zoomies Brand Color Palette - Harmonized with the Official Zoomies Logo
class AppColors {
  // Brand Primary (Denim Blue / Slate Ocean from the Zoomies logo letters)
  static const Color primary = Color(0xFF356B8D);
  static const Color primaryLight = Color(0xFF5085A8);
  static const Color primaryDark = Color(0xFF1E4663);
  static const Color primarySurface = Color(0xFFF0F6FA);
  static const Color primaryBorder = Color(0xFFD6E4EE);

  // Brand Mascot Secondary (Warm Golden Honey from the Dog Mascot)
  static const Color dogGold = Color(0xFFEABF65);
  static const Color dogGoldDark = Color(0xFFC99B35);
  static const Color dogGoldSurface = Color(0xFFFDF7E7);
  static const Color dogGoldBorder = Color(0xFFF6E2B2);

  // Brand Mascot Secondary (Tabby Kitten Slate Grey)
  static const Color catGrey = Color(0xFF7F8893);
  static const Color catGreyDark = Color(0xFF4B5563);
  static const Color catGreySurface = Color(0xFFF3F4F6);
  static const Color catGreyBorder = Color(0xFFE5E7EB);

  // Splash Energy Sky Blue (From the starburst behind mascots)
  static const Color splashBlue = Color(0xFF8CB8D4);
  static const Color splashBlueLight = Color(0xFFE3F0F8);

  // Neutrals / Typography
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateMedium = Color(0xFF334155);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color slateLight = Color(0xFF94A3B8);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Clinical Triage Urgency Levels
  static const Color triageRed = Color(0xFFEF4444);
  static const Color triageRedSurface = Color(0xFFFEF2F2);
  static const Color triageRedBorder = Color(0xFFFECACA);

  static const Color triageYellow = Color(0xFFF59E0B);
  static const Color triageYellowSurface = Color(0xFFFFFBEB);
  static const Color triageYellowBorder = Color(0xFFFDE68A);

  static const Color triageGreen = Color(0xFF10B981);
  static const Color triageGreenSurface = Color(0xFFECFDF5);
  static const Color triageGreenBorder = Color(0xFFA7F3D0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2B5B7A), Color(0xFF457E9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

