import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Legacy names for older screens, mapped onto the same palette as aura.dart.
  static const Color atmosphere = Color(0xFFF0F4F8); // Child of Light
  static const Color void_ = atmosphere; // Compatibility alias
  static const Color voidMid = Color(0xFFE3EAEA); // Child of Light → Aruba Aqua

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF010101); // Vantablack
  static const Color textSecondary = Color(0xFF5E6161); // Blackish Green
  static const Color textHint = Color(0xFF687070);
  static const Color textDisabled = Color(0xFFA1ACAC); // Portsmouth Bay
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Interactive Accents ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF233E42); // Atlantic Waves
  static const Color primaryDark = Color(0xFF16292C);
  static const Color primaryLight = Color(0xFFD2DDD4); // Aruba Aqua
  static const Color secondary = Color(0xFF3F6B70);
  static const Color secondaryLight = Color(0xFFA9C4C8);
  static const Color accent = Color(0xFF8A6A2E); // muted ochre
  static const Color accentLight = Color(0xFFE6D6B4);
  static const Color coral = Color(0xFFA5483C);
  static const Color blue = Color(0xFF3F6B70);
  static const Color neon = Color(0xFF233E42);

  // ── Floating Background Orbs ─────────────────────────────────────────────
  static const Color orbMint = Color(0xFFD2DDD4); // Aruba Aqua
  static const Color orbSky = Color(0xFFE3EAEA);
  static const Color orbAmber = Color(0xFFE9ECEA);

  // ── Glassmorphism Variables ──────────────────────────────────────────────
  static const Color glassSurface =
      Color(0xBFFFFFFF); // rgba(255, 255, 255, 0.75)
  static const Color glassBorder = Color(0x73A1ACAC);
  static const Color glassShadowColor = Color(0x0F233E42);
  static const Color glassBase = glassSurface;
  static const Color glassHighlight = glassBorder;
  static const Color glassHover =
      Color(0xE6FFFFFF); // rgba(255, 255, 255, 0.90)

  // ── Semantic Structure ────────────────────────────────────────────────────
  static const Color background = atmosphere;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = glassSurface;
  static const Color divider = Color(0xFFDCE3E4);
  static const Color border = Color(0xFFA1ACAC);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2F6B55);
  static const Color warning = Color(0xFF8A6A2E);
  static const Color error = Color(0xFFA5483C);
  static const Color info = Color(0xFF3F6B70);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient atmosphereGradient = LinearGradient(
    colors: [Color(0xFFF0F4F8), Color(0xFFE3EAEA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient voidGradient = atmosphereGradient;

  static const LinearGradient appscGradient = LinearGradient(
    colors: [Color(0xFF233E42), Color(0xFF16292C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient apssbGradient = LinearGradient(
    colors: [Color(0xFF3F6B70), Color(0xFF233E42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    colors: [Color(0xFF233E42), Color(0xFF3F6B70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealBlueGradient = LinearGradient(
    colors: [Color(0xFF3F6B70), Color(0xFF233E42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glass & Glow Shadows ─────────────────────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0F233E42),
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> glassHoverShadow = [
    BoxShadow(
      color: Color(0x1A233E42),
      blurRadius: 50,
      offset: Offset(0, 30),
    ),
  ];

  static List<BoxShadow> emeraldGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(35, 62, 66, 0.18 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> redGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(165, 72, 60, 0.18 * intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> amberGlowShadow({double intensity = 1.0}) => [
        BoxShadow(
          color: Color.fromRGBO(138, 106, 46, 0.18 * intensity),
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
