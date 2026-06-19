import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ClipQ Design System v2 — Monochrome zinc palette.
///
/// Inspired by Linear's near-black surfaces and Raycast's density.
/// Purple is dead. Accent blue appears ONLY on active/interactive states.
class AppTheme {
  AppTheme._();

  // ── Accent (used sparingly — active states only) ──────────────────────────
  static const Color accent      = Color(0xFF3B82F6); // blue-500
  static const Color accentMuted = Color(0xFF2563EB); // blue-600
  static const Color accentGlow  = Color(0x0F3B82F6); // ~6% opacity

  // Legacy aliases so providers/services don't break
  static const Color primary      = accent;
  static const Color primaryLight = Color(0xFF60A5FA); // blue-400
  static const Color primaryDark  = accentMuted;
  static const Color primaryGlow  = accentGlow;

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background      = Color(0xFF09090B); // zinc-950
  static const Color surface         = Color(0xFF0F0F12); // slightly lifted
  static const Color surfaceCard     = Color(0xFF18181B); // zinc-900
  static const Color surfaceElevated = Color(0xFF27272A); // zinc-800
  static const Color surfaceHover    = Color(0x08FFFFFF); // rgba(255,255,255,0.03)

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border       = Color(0xFF27272A); // zinc-800 solid
  static const Color borderStrong = Color(0xFF3F3F46); // zinc-700
  static const Color divider      = Color(0xFF27272A); // zinc-800
  static const Color hover        = surfaceHover;
  static const Color surfaceOverlay = Color(0xE609090B); // 90% background

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFAFAFA); // zinc-50
  static const Color textSecondary = Color(0xFFA1A1AA); // zinc-400
  static const Color textMuted     = Color(0xFF52525B); // zinc-500 (was 600)

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);

  // ── Typography ────────────────────────────────────────────────────────────

  // UI font — used for labels, buttons, metadata, navigation
  static TextStyle get uiLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get uiBody => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get uiStrong => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      );

  // Content font — used for clipboard preview text
  static TextStyle get contentMono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get contentUrl => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: accent,
        height: 1.5,
        decoration: TextDecoration.underline,
        decorationColor: accent.withAlpha(80),
      );

  // Headings — sparse use
  static TextStyle get headingPage => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get headingSection => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.6,
        height: 1.4,
      );

  // Legacy compat aliases
  static TextStyle get display        => headingPage;
  static TextStyle get pageTitle      => headingPage;
  static TextStyle get sectionHeading => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, height: 1.4);
  static TextStyle get cardTitle      => uiStrong;
  static TextStyle get body           => uiBody;
  static TextStyle get caption        => uiLabel;
  static TextStyle get metadata       => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: textMuted, height: 1.4);

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;

  // ── Helpers ───────────────────────────────────────────────────────────────

  static BoxDecoration cardDecoration({bool elevated = false}) => BoxDecoration(
        color: elevated ? surfaceElevated : surfaceCard,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  static BoxDecoration glassDecoration() => BoxDecoration(
        color: surfaceOverlay,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: borderStrong, width: 0.5),
      );

  static BoxDecoration accentCard() => const BoxDecoration(
        color: surfaceCard,
        border: Border(left: BorderSide(color: accent, width: 2)),
      );

  static BoxDecoration flatCard() => cardDecoration();

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final inter = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      textTheme: inter,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: primaryLight,
        surface: surfaceCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        outline: border,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textSecondary),
        titleTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 0.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: border, width: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: textMuted,
        textColor: textPrimary,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return success;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return success.withAlpha(60);
          }
          return surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 4,
        surfaceTintColor: Colors.transparent,
      ),

      iconTheme: const IconThemeData(color: textMuted, size: 16),
      primaryIconTheme: const IconThemeData(color: accent),
    );
  }
}
