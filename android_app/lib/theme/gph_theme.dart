import 'package:flutter/material.dart';

/// Identidade visual central do GP-H Android.
///
/// A intenção é manter as telas funcionais independentes da paleta. Assim,
/// ajustes de cor, tipografia, superfícies e controles podem ser feitos em um
/// único lugar durante o polimento visual.
class GphTheme {
  GphTheme._();

  static const Color background = Color(0xFF07101D);
  static const Color surface = Color(0xFF0B1523);
  static const Color surfaceRaised = Color(0xFF0F1D2F);
  static const Color surfaceSoft = Color(0xFF13233A);
  static const Color border = Color(0xFF20334D);
  static const Color borderStrong = Color(0xFF2B496D);

  static const Color primary = Color(0xFF4EA1FF);
  static const Color primaryStrong = Color(0xFF1784FF);
  static const Color primarySoft = Color(0xFF173253);

  /// Cores semânticas: ajudam a reconhecer o tipo de informação sem depender
  /// apenas do texto. Devem permanecer discretas e consistentes em todo o app.
  static const Color frequency = primary;
  static const Color delay = Color(0xFFFFC857);
  static const Color delaySoft = Color(0xFF332A18);
  static const Color head = Color(0xFFA78BFA);
  static const Color headSoft = Color(0xFF2A2142);

  static const Color textPrimary = Color(0xFFF4F8FD);
  static const Color textSecondary = Color(0xFFABC0D8);
  static const Color textMuted = Color(0xFF7890AA);
  static const Color success = Color(0xFF6EE7A8);
  static const Color warning = Color(0xFFFFD166);
  static const Color danger = Color(0xFFFF7B86);

  static ThemeData get darkBlue {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    ).copyWith(
      primary: primary,
      secondary: const Color(0xFF7DB6FF),
      surface: surface,
      error: danger,
      onSurface: textPrimary,
      outline: border,
      outlineVariant: const Color(0xFF182A40),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: textPrimary,
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: textSecondary,
        height: 1.35,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: textMuted,
        height: 1.3,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: border,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: const Color(0xFF091421),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: states.contains(WidgetState.selected) ? 25 : 23,
            color: states.contains(WidgetState.selected) ? primary : textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected) ? textPrimary : textMuted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceRaised,
        selectedColor: primarySoft,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF14253A),
        contentTextStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceRaised,
        showDragHandle: true,
        dragHandleColor: borderStrong,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFF16263A),
      ),
    );
  }
}
