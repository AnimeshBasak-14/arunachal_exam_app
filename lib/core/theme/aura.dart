import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Donyi Prep design tokens.
///
/// Palette rationale (education / long study sessions):
/// - Warm ivory paper instead of pure white cuts glare on cheap LCD panels.
/// - Deep forest jade is the single accent: green reads as calm, focus and
///   progress, and is easy on the eyes for hours of reading.
/// - Muted ochre marks "review later" without the alarm of red.
/// - Muted brick is reserved for wrong answers and the last minutes of a test.
/// - Dark mode is green-black with a soft jade accent, never neon.
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
    required this.shadow,
    required this.elevatedShadow,
  });

  static const light = Aura(
    bg: Color(0xFFF6F5F0),
    bgTint: Color(0xFFEAF1EC),
    surface: Color(0xC7FFFFFF),
    surfaceSolid: Color(0xFFFFFFFF),
    hairline: Color(0x1A14201A),
    ink: Color(0xFF14201A),
    inkMuted: Color(0xFF56625B),
    inkFaint: Color(0xFF8A948E),
    accent: Color(0xFF1E6B52),
    accentSoft: Color(0x141E6B52),
    onAccent: Color(0xFFFFFFFF),
    review: Color(0xFFB07A26),
    danger: Color(0xFFB4473A),
    info: Color(0xFF3A5F8A),
    shadow: [
      BoxShadow(color: Color(0x0A14201A), blurRadius: 24, offset: Offset(0, 8)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x1414201A), blurRadius: 40, offset: Offset(0, 16)),
    ],
  );

  static const dark = Aura(
    bg: Color(0xFF0C110F),
    bgTint: Color(0xFF12201A),
    surface: Color(0x0FFFFFFF),
    surfaceSolid: Color(0xFF151C18),
    hairline: Color(0x1AFFFFFF),
    ink: Color(0xFFE8EDE9),
    inkMuted: Color(0xFF9BA6A0),
    inkFaint: Color(0xFF66716B),
    accent: Color(0xFF72C4A1),
    accentSoft: Color(0x1F72C4A1),
    onAccent: Color(0xFF08160F),
    review: Color(0xFFD8A65A),
    danger: Color(0xFFE07B6D),
    info: Color(0xFF93B5DA),
    shadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 16)),
    ],
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
