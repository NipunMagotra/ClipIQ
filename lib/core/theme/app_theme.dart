import 'package:flutter/material.dart';

/// ClipQ design system — clean, flat, professional dark UI.
///
/// Palette:
///   Primary  — violet   #6C63FF
///   Accent   — teal     #00BFA5
///   Surface  — near-black #111318
///   Error    — red      #E53935
class AppTheme {
  AppTheme._();

  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color accent       = Color(0xFF00BFA5);
  static const Color accentDark   = Color(0xFF00897B);
  static const Color surface      = Color(0xFF111318);
  static const Color surfaceCard  = Color(0xFF1A1D25);
  static const Color surfaceElevated = Color(0xFF20242F);
  static const Color border       = Color(0xFF2C3040);
  static const Color borderStrong = Color(0xFF3D4259);
  static const Color textPrimary  = Color(0xFFE8EAF6);
  static const Color textSecondary= Color(0xFF7B82A0);
  static const Color textMuted    = Color(0xFF4A5070);
  static const Color error        = Color(0xFFE53935);
  static const Color success      = Color(0xFF43A047);
  static const Color warning      = Color(0xFFFFA726);

  // ── Card decorations (flat, no gradients) ─────────────────────────────────

  /// Standard flat card with a left accent bar.
  static BoxDecoration accentCard() => const BoxDecoration(
    color: surfaceCard,
    border: Border(
      left: BorderSide(color: accent, width: 3),
      top: BorderSide(color: border, width: 1),
      right: BorderSide(color: border, width: 1),
      bottom: BorderSide(color: border, width: 1),
    ),
  );

  /// Standard flat card.
  static BoxDecoration flatCard() => const BoxDecoration(
    color: surfaceCard,
    border: Border.fromBorderSide(BorderSide(color: border, width: 1)),
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surfaceCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        outline: border,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      cardTheme: const CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: border),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 12),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentDark;
          return surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),

      iconTheme: const IconThemeData(color: textSecondary, size: 20),
      primaryIconTheme: const IconThemeData(color: primary),
    );
  }
}
