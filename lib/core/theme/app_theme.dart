import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aura.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Aura.light, Brightness.light);
  static ThemeData get darkTheme => _build(Aura.dark, Brightness.dark);

  /// Older secondary screens hardcode light colours, so they always render
  /// with the light theme until they are redesigned.
  static ThemeData get legacyTheme => lightTheme;

  static ThemeData _build(Aura a, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: a.ink,
      displayColor: a.ink,
    );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: a.accent,
      onPrimary: a.onAccent,
      secondary: a.info,
      onSecondary: a.onAccent,
      tertiary: a.review,
      onTertiary: a.onAccent,
      error: a.danger,
      onError: a.onAccent,
      surface: a.surfaceSolid,
      onSurface: a.ink,
      onSurfaceVariant: a.inkMuted,
      outline: a.hairline,
      outlineVariant: a.hairline,
      surfaceContainerHighest: a.bgTint,
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AuraSpace.radiusS),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: a.bg,
      extensions: [a],
      textTheme: inter.copyWith(
        headlineLarge: AuraType.serif(30, a.ink),
        headlineMedium: AuraType.serif(26, a.ink),
        headlineSmall: AuraType.serif(22, a.ink),
        titleLarge: AuraType.serif(20, a.ink),
        titleMedium: AuraType.sans(16, a.ink, weight: FontWeight.w600),
        titleSmall: AuraType.sans(14, a.ink, weight: FontWeight.w600),
        bodyLarge: AuraType.sans(16, a.ink, height: 1.55),
        bodyMedium: AuraType.sans(14, a.inkMuted, height: 1.5),
        bodySmall: AuraType.sans(12, a.inkFaint),
        labelLarge: AuraType.sans(15, a.ink, weight: FontWeight.w600),
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: a.hairline, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: a.inkMuted, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: a.ink,
        titleTextStyle: AuraType.serif(20, a.ink),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: a.accent,
          foregroundColor: a.onAccent,
          disabledBackgroundColor: a.hairline,
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: AuraType.sans(15, a.onAccent, weight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: a.accent,
          foregroundColor: a.onAccent,
          elevation: 0,
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: AuraType.sans(15, a.onAccent, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: a.ink,
          side: BorderSide(color: a.hairline),
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: AuraType.sans(15, a.ink, weight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: a.accent,
          textStyle: AuraType.sans(14, a.accent, weight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: a.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AuraType.sans(15, a.inkFaint),
        labelStyle: AuraType.sans(15, a.inkMuted),
        prefixIconColor: a.inkFaint,
        suffixIconColor: a.inkFaint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          borderSide: BorderSide(color: a.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          borderSide: BorderSide(color: a.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          borderSide: BorderSide(color: a.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          borderSide: BorderSide(color: a.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radiusS),
          borderSide: BorderSide(color: a.danger, width: 1.4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: a.surfaceSolid,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.35),
        showDragHandle: true,
        dragHandleColor: a.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: a.surfaceSolid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: a.hairline),
        ),
        titleTextStyle: AuraType.serif(22, a.ink),
        contentTextStyle: AuraType.sans(15, a.inkMuted, height: 1.5),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: a.surfaceSolid,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: a.ink,
        contentTextStyle: AuraType.sans(14, a.bg),
        behavior: SnackBarBehavior.floating,
        shape: rounded,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: a.accent,
        linearTrackColor: a.hairline,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: a.inkMuted,
        textColor: a.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: a.accentSoft,
        side: BorderSide(color: a.hairline),
        labelStyle: AuraType.sans(13, a.inkMuted, weight: FontWeight.w500),
        shape: const StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: a.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraSpace.radius),
          side: BorderSide(color: a.hairline, width: 0.8),
        ),
      ),
    );
  }
}
