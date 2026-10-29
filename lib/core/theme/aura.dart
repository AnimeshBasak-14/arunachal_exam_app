import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App design tokens, built on the ZAP palette:
///
///   Child of Light  #F0F4F8   page background (light)
///   Aruba Aqua      #D2DDD4   tint, selected states, accent in dark mode
///   Portsmouth Bay  #A1ACAC   hairlines and borders (too light for text)
///   Blackish Green  #5E6161   secondary text
///   Atlantic Waves  #233E42   the single accent: buttons, links, progress
///   Vantablack      #010101   headings and body text, dark-mode background
///
/// Two derived steps keep small text readable: [inkFaint] sits between Bay
/// and Blackish Green so it clears 4.5:1, and the dark sheet colour mixes
/// Atlantic Waves into Vantablack. Answer states (correct / review / wrong)
/// keep muted functional hues because a monochrome palette alone can't
/// tell them apart.
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
    bg: Color(0xFFF0F4F8),
    bgTint: Color(0xFFD2DDD4),
    surface: Color(0xCCFFFFFF),
    surfaceSolid: Color(0xFFFFFFFF),
    hairline: Color(0x73A1ACAC),
    ink: Color(0xFF010101),
    inkMuted: Color(0xFF5E6161),
    inkFaint: Color(0xFF687070),
    accent: Color(0xFF233E42),
    accentSoft: Color(0x14233E42),
    onAccent: Color(0xFFF0F4F8),
    review: Color(0xFF8A6A2E),
    danger: Color(0xFFA5483C),
    info: Color(0xFF3F6B70),
    shadow: [
      BoxShadow(color: Color(0x0F233E42), blurRadius: 24, offset: Offset(0, 8)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x1A233E42), blurRadius: 40, offset: Offset(0, 16)),
    ],
  );

  static const dark = Aura(
    bg: Color(0xFF010101),
    bgTint: Color(0xFF14272A),
    surface: Color(0x0DF0F4F8),
    surfaceSolid: Color(0xFF0E1A1C),
    hairline: Color(0x2EA1ACAC),
    ink: Color(0xFFF0F4F8),
    inkMuted: Color(0xFFA1ACAC),
    inkFaint: Color(0xFF8A9494),
    accent: Color(0xFFD2DDD4),
    accentSoft: Color(0x1FD2DDD4),
    onAccent: Color(0xFF010101),
    review: Color(0xFFD4B072),
    danger: Color(0xFFE0897D),
    info: Color(0xFFA9C4C8),
    shadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 16)),
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
