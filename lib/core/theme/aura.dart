import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App design tokens, built on the ZAP palette.
///
/// Light: white page, black "frame" (header band and tab bar), Atlantic Waves
/// for buttons and links, Aruba Aqua for soft highlight cards, Child of Light
/// for card fills, Blackish Green for secondary text.
///
/// Dark: plain black with neutral grey surfaces and near-white text. No tinted
/// backgrounds, so nothing competes with the content.
///
/// Portsmouth Bay (#A1ACAC) is too light for text on white, so it is only used
/// for borders and for muted text on the black frame. Answer states
/// (correct / review / wrong) keep muted functional hues because a
/// monochrome palette alone can't tell them apart.
@immutable
class Aura extends ThemeExtension<Aura> {
  final Color bg;
  final Color bgTint;
  final Color surface; // frosted glass panel
  final Color surfaceSolid; // elevated / sheets
  final Color hairline;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color review;
  final Color danger;
  final Color info;
  final Color success;
  final Color chrome; // the black frame: header band, tab bar
  final Color onChrome;
  final Color tint; // soft highlight card
  final Color onTint;
  final List<BoxShadow> shadow;
  final List<BoxShadow> elevatedShadow;

  const Aura({
    required this.bg,
    required this.bgTint,
    required this.surface,
    required this.surfaceSolid,
    required this.hairline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.review,
    required this.danger,
    required this.info,
    required this.success,
    required this.chrome,
    required this.onChrome,
    required this.tint,
    required this.onTint,
    required this.shadow,
    required this.elevatedShadow,
  });

  static const light = Aura(
    bg: Color(0xFFFFFFFF),
    bgTint: Color(0xFFF0F4F8),
    surface: Color(0xFFF0F4F8),
    surfaceSolid: Color(0xFFFFFFFF),
    hairline: Color(0x4DA1ACAC),
    ink: Color(0xFF010101),
    inkMuted: Color(0xFF5E6161),
    inkFaint: Color(0xFF687070),
    accent: Color(0xFF233E42),
    accentSoft: Color(0x14233E42),
    onAccent: Color(0xFFF0F4F8),
    review: Color(0xFF8A6A2E),
    danger: Color(0xFFA5483C),
    info: Color(0xFF3F6B70),
    success: Color(0xFF2F6B55),
    chrome: Color(0xFF010101),
    onChrome: Color(0xFFF0F4F8),
    tint: Color(0xFFD2DDD4),
    onTint: Color(0xFF010101),
    shadow: [
      BoxShadow(color: Color(0x0A233E42), blurRadius: 20, offset: Offset(0, 6)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x14233E42), blurRadius: 32, offset: Offset(0, 12)),
    ],
  );

  /// Plain black. Greys are neutral on purpose.
  static const dark = Aura(
    bg: Color(0xFF000000),
    bgTint: Color(0xFF0B0B0B),
    surface: Color(0xFF111111),
    surfaceSolid: Color(0xFF161616),
    hairline: Color(0x1FFFFFFF),
    ink: Color(0xFFF2F2F2),
    inkMuted: Color(0xFFA6A6A6),
    inkFaint: Color(0xFF858585),
    accent: Color(0xFFF0F4F8),
    accentSoft: Color(0x14FFFFFF),
    onAccent: Color(0xFF010101),
    review: Color(0xFFD4B072),
    danger: Color(0xFFE88B80),
    info: Color(0xFFA1ACAC),
    success: Color(0xFF7BC9A0),
    chrome: Color(0xFF141414),
    onChrome: Color(0xFFF2F2F2),
    tint: Color(0xFF1A1A1A),
    onTint: Color(0xFFF2F2F2),
    shadow: [],
    elevatedShadow: [],
  );

  @override
  Aura copyWith() => this;

  @override
  Aura lerp(covariant Aura? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Aura(
      bg: l(bg, other.bg),
      bgTint: l(bgTint, other.bgTint),
      surface: l(surface, other.surface),
      surfaceSolid: l(surfaceSolid, other.surfaceSolid),
      hairline: l(hairline, other.hairline),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      review: l(review, other.review),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      success: l(success, other.success),
      chrome: l(chrome, other.chrome),
      onChrome: l(onChrome, other.onChrome),
      tint: l(tint, other.tint),
      onTint: l(onTint, other.onTint),
      shadow: t < 0.5 ? shadow : other.shadow,
      elevatedShadow: t < 0.5 ? elevatedShadow : other.elevatedShadow,
    );
  }
}

extension AuraContext on BuildContext {
  Aura get aura => Theme.of(this).extension<Aura>() ?? Aura.light;
}

/// Type scale: Playfair Display for headers and exam names, Inter for exam
/// text and numbers.
class AuraType {
  AuraType._();

  static TextStyle serif(double size, Color color,
          {FontWeight weight = FontWeight.w500, double height = 1.2}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: -0.2,
      );

  static TextStyle sans(double size, Color color,
          {FontWeight weight = FontWeight.w400,
          double height = 1.4,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Small uppercase label above titles.
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.4,
      );

  /// Digits that don't jitter while counting down.
  static TextStyle digits(double size, Color color,
          {FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 0.5,
      );
}

class AuraSpace {
  AuraSpace._();
  static const double gutter = 20;
  static const double radius = 20;
  static const double radiusS = 14;
}
