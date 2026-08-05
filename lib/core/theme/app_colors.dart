import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF2E8B57); // Emerald Green
  static const Color primaryDark = Color(0xFF1F6F4A); // Deep Green
  static const Color primaryLight = Color(0xFFDDF6E8); // Mint Green
  static const Color secondary = Color(0xFF14B8A6); // Teal
  static const Color accent = Color(0xFFF59E0B); // Amber / Tertiary

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appscGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFE07A5F)], // Amber to Warm Orange-Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient apssbGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)], // Teal to Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
