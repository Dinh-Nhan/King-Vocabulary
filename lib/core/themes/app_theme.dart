import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens distilled from the HTML prototypes (sky / mint / lav / pink / amber).
abstract final class LexiColors {
  static const sky50 = Color(0xFFEFF8FF);
  static const sky100 = Color(0xFFDBEAFE);
  static const sky200 = Color(0xFFBAE6FD);
  static const sky300 = Color(0xFF7DD3FC);
  static const sky400 = Color(0xFF38BDF8);
  static const sky500 = Color(0xFF0EA5E9);
  static const sky600 = Color(0xFF0284C7);
  static const sky700 = Color(0xFF0369A1);
  static const sky800 = Color(0xFF075985);

  static const mint50 = Color(0xFFF0FDF4);
  static const mint100 = Color(0xFFDCFCE7);
  static const mint200 = Color(0xFFBBF7D0);
  static const mint400 = Color(0xFF4ADE80);
  static const mint600 = Color(0xFF16A34A);
  static const mint800 = Color(0xFF166534);

  static const pink50 = Color(0xFFFFF0F6);
  static const pink100 = Color(0xFFFFD6E7);
  static const pink200 = Color(0xFFFFADD2);
  static const pink600 = Color(0xFFC2185B);

  static const lav50 = Color(0xFFF5F3FF);
  static const lav100 = Color(0xFFEDE9FE);
  static const lav200 = Color(0xFFDDD6FE);
  static const lav400 = Color(0xFFA78BFA);
  static const lav600 = Color(0xFF7C3AED);
  static const lav800 = Color(0xFF4C1D95);

  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber600 = Color(0xFFD97706);
  static const amber800 = Color(0xFF92400E);

  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red200 = Color(0xFFFECACA);
  static const red400 = Color(0xFFEF5350);
  static const red600 = Color(0xFFDC2626);
  static const red800 = Color(0xFF991B1B);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
}

ThemeData buildKingVocabularyTheme() {
  final baseText = GoogleFonts.nunitoTextTheme();
  final colorScheme = ColorScheme.light(
    primary: LexiColors.sky600,
    onPrimary: Colors.white,
    secondary: LexiColors.mint600,
    surface: Colors.white,
    onSurface: LexiColors.slate800,
    surfaceContainerHighest: LexiColors.sky50,
    outline: LexiColors.sky100,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LexiColors.sky50,
    textTheme: baseText.copyWith(
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: LexiColors.slate800,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: LexiColors.slate700,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(color: LexiColors.slate600),
      bodySmall: baseText.bodySmall?.copyWith(color: LexiColors.slate500),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: LexiColors.sky50,
      foregroundColor: LexiColors.slate800,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: LexiColors.slate800,
      ),
      iconTheme: const IconThemeData(color: LexiColors.sky600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LexiColors.sky400,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LexiColors.sky600,
        side: const BorderSide(color: LexiColors.sky200, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: LexiColors.sky100,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LexiColors.sky50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LexiColors.sky200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LexiColors.sky200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LexiColors.sky400, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
