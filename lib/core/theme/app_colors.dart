import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── The Void ──────────────────────────────────────────────────────────────
  static const Color void_ = Color(0xFF0A0F16); // Deep Obsidian background
  static const Color voidMid = Color(0xFF111827); // Slightly lighter panels

  // ── Glowing Accents ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2E8B57); // Forest Emerald
  static const Color primaryDark = Color(0xFF1F6F4A); // Deep press
  static const Color primaryLight = Color(0xFF34D399); // Neon Emerald glow
  static const Color secondary = Color(0xFF14B8A6); // Neon Teal
  static const Color secondaryLight = Color(0xFF5EEAD4); // Teal glow
  static const Color accent = Color(0xFFF59E0B); // Glowing Amber
  static const Color accentLight = Color(0xFFFCD34D); // Amber glow
  static const Color coral = Color(0xFFF97316); // Coral accent
  static const Color blue = Color(0xFF3B82F6); // Info blue
  static const Color neon = Color(0xFF00FF88); // Neon active dot

  // ── Glass System ─────────────────────────────────────────────────────────
  /// Card/panel background — use with backdrop-filter blur 24
  static const Color glassBase = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  /// Top/left edge highlight to simulate ambient light catch
  static const Color glassHighlight = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  /// Subtle border for glass panels
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  /// Hover/active glass state
  static const Color glassHover = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // ── Semantic (kept for compatibility) ────────────────────────────────────
  static const Color background = void_; // was #F8FAFC
  static const Color surface = Color(0xFF0D1117); // was #FFFFFF
  static const Color card = glassBase;
  static const Color divider = Color(0x1AFFFFFF); // white 10%
  static const Color border = Color(0x26FFFFFF); // white 15%

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white headings
  static const Color textSecondary = Color(0xFF9CA3AF); // Soft lavender-grey
  static const Color textHint = Color(0xFF6B7280); // Muted hint
  static const Color textDisabled = Color(0xFF374151);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // Correct answer green
  static const Color warning = Color(0xFFF59E0B); // Same as accent
  static const Color error = Color(0xFFEF4444); // Wrong answer red
  static const Color info = Color(0xFF3B82F6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voidGradient = LinearGradient(
    colors: [Color(0xFF0A0F16), Color(0xFF0D1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient appscGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFE07A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient apssbGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealBlueGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow Shadows (shared across widgets) ─────────────────────────────────
  static List<BoxShadow> emeraldGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(46, 139, 87, 0.4 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> redGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(239, 68, 68, 0.4 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> amberGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(245, 158, 11, 0.4 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x66000000), // black 40%
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];
}
