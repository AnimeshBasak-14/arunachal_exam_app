import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Legacy palette, kept for older screens. New UI reads tokens from aura.dart.
  static const Color atmosphere = Color(0xFFF6F5F0); // Main canvas background
  static const Color void_ = atmosphere; // Compatibility alias
  static const Color voidMid = Color(0xFFEFEEE7); // Card / subtle secondary bg

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF14201A); // Slate 900
  static const Color textSecondary = Color(0xFF56625B); // Slate 600
  static const Color textHint = Color(0xFF8A948E); // Slate 400
  static const Color textDisabled = Color(0xFFC9CEC9); // Slate 300
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Interactive Accents ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E6B52); // Forest Emerald
  static const Color primaryDark = Color(0xFF154D3B);
  static const Color primaryLight = Color(0xFF5E9E85); // Light emerald
  static const Color secondary = Color(0xFF3A5F8A); // Secondary Teal
  static const Color secondaryLight = Color(0xFF93B5DA);
  static const Color accent = Color(0xFFB07A26); // Warning Amber
  static const Color accentLight = Color(0xFFE2C48F);
  static const Color coral = Color(0xFFB4473A);
  static const Color blue = Color(0xFF3A5F8A);
  static const Color neon = Color(0xFF1E6B52);

  // ── Floating Background Orbs ─────────────────────────────────────────────
  static const Color orbMint = Color(0xFFEAF1EC); // Mint tint
  static const Color orbSky = Color(0xFFEDF1F5); // Sky tint
  static const Color orbAmber = Color(0xFFF5EFE3); // Amber tint

  // ── Glassmorphism Variables ──────────────────────────────────────────────
  static const Color glassSurface = Color(0xBFFFFFFF); // rgba(255, 255, 255, 0.75)
  static const Color glassBorder = Color(0x1A14201A); // rgba(255, 255, 255, 1.0)
  static const Color glassShadowColor = Color(0x0A14201A); // rgba(46, 139, 87, 0.08)
  static const Color glassBase = glassSurface;
  static const Color glassHighlight = glassBorder;
  static const Color glassHover = Color(0xE6FFFFFF); // rgba(255, 255, 255, 0.90)

  // ── Semantic Structure ────────────────────────────────────────────────────
  static const Color background = atmosphere;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = glassSurface;
  static const Color divider = Color(0xFFE5E3DB);
  static const Color border = Color(0xFFD6D3C8);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1E6B52);
  static const Color warning = Color(0xFFB07A26);
  static const Color error = Color(0xFFB4473A);
  static const Color info = Color(0xFF3A5F8A);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient atmosphereGradient = LinearGradient(
    colors: [Color(0xFFF6F5F0), Color(0xFFEFEEE7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient voidGradient = atmosphereGradient;

  static const LinearGradient appscGradient = LinearGradient(
    colors: [Color(0xFF1E6B52), Color(0xFF154D3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient apssbGradient = LinearGradient(
    colors: [Color(0xFF2F4F6B), Color(0xFF223A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    colors: [Color(0xFF1E6B52), Color(0xFF2C7D62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealBlueGradient = LinearGradient(
    colors: [Color(0xFF2F4F6B), Color(0xFF223A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glass & Glow Shadows ─────────────────────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0A14201A),
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> glassHoverShadow = [
    BoxShadow(
      color: Color(0x1414201A),
      blurRadius: 50,
      offset: Offset(0, 30),
    ),
  ];

  static List<BoxShadow> emeraldGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(30, 107, 82, 0.18 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> redGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(180, 71, 58, 0.18 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> amberGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(176, 122, 38, 0.18 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  // ── Compatibility Aliases ────────────────────────────────────────────────
  static const Color textOnOrange = textWhite;
  static const Color darkWarning = warning;
  static const Color darkGreen = success;
  static const Color darkRed = error;
}
