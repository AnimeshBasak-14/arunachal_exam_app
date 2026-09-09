import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── The Atmosphere (Light Antigravity) ───────────────────────────────────
  static const Color atmosphere = Color(0xFFF8FAFC); // Main canvas background
  static const Color void_ = atmosphere; // Compatibility alias
  static const Color voidMid = Color(0xFFF1F5F9); // Card / subtle secondary bg

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textDisabled = Color(0xFFCBD5E1); // Slate 300
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Interactive Accents ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2E8B57); // Forest Emerald
  static const Color primaryDark = Color(0xFF1F6F4A);
  static const Color primaryLight = Color(0xFF34D399); // Light emerald
  static const Color secondary = Color(0xFF14B8A6); // Secondary Teal
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color accent = Color(0xFFF59E0B); // Warning Amber
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color coral = Color(0xFFF97316);
  static const Color blue = Color(0xFF3B82F6);
  static const Color neon = Color(0xFF00FF88);

  // ── Floating Background Orbs ─────────────────────────────────────────────
  static const Color orbMint = Color(0xFFD1FAE5); // Mint tint
  static const Color orbSky = Color(0xFFE0F2FE); // Sky tint
  static const Color orbAmber = Color(0xFFFEF3C7); // Amber tint

  // ── Glassmorphism Variables ──────────────────────────────────────────────
  static const Color glassSurface = Color(0xBFFFFFFF); // rgba(255, 255, 255, 0.75)
  static const Color glassBorder = Color(0xFFFFFFFF); // rgba(255, 255, 255, 1.0)
  static const Color glassShadowColor = Color(0x142E8B57); // rgba(46, 139, 87, 0.08)
  static const Color glassBase = glassSurface;
  static const Color glassHighlight = glassBorder;
  static const Color glassHover = Color(0xE6FFFFFF); // rgba(255, 255, 255, 0.90)

  // ── Semantic Structure ────────────────────────────────────────────────────
  static const Color background = atmosphere;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = glassSurface;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient atmosphereGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient voidGradient = atmosphereGradient;

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

  // ── Glass & Glow Shadows ─────────────────────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x142E8B57), // rgba(46, 139, 87, 0.08)
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> glassHoverShadow = [
    BoxShadow(
      color: Color(0x1F2E8B57), // rgba(46, 139, 87, 0.12)
      blurRadius: 50,
      offset: Offset(0, 30),
    ),
  ];

  static List<BoxShadow> emeraldGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(46, 139, 87, 0.25 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> redGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(239, 68, 68, 0.25 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> amberGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(245, 158, 11, 0.25 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}
