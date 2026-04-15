import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData tactileManuscript() {
    const primary = Color(0xFF059669); // Emerald Green
    const primaryDim = Color(0xFF047857);
    const bgWarmPaper = Color(0xFFF9FAFB); // Modern Light Gray
    const surfaceCLow = Color(0xFFF3F4F6);
    const surfaceC = Color(0xFFE5E7EB);
    const surfaceCLowest = Color(0xFFFFFFFF); // Pure White Cards
    const textDark = Color(0xFF111827);
    const textSoft = Color(0xFF6B7280);
    const secContainer = Color(0xFFD1FAE5); // Mint Green
    const terContainer = Color(0xFFDBEAFE); // Light Blue

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surfaceCLowest,
      primary: primary,
      primaryContainer: primaryDim,
      secondaryContainer: secContainer,
      tertiaryContainer: terContainer,
      onSurface: textDark,
      onSurfaceVariant: textSoft,
      error: const Color(0xFFD32F2F),
      outlineVariant: textDark.withValues(alpha: 0.15),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgWarmPaper,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark, height: 1.6, fontSize: 16),
        bodyMedium: TextStyle(color: textDark, height: 1.5, fontSize: 14),
        labelMedium: TextStyle(color: textSoft, fontSize: 12),
        titleLarge: TextStyle(
            color: textDark, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(
            color: textDark, fontWeight: FontWeight.w600, fontSize: 18),
        displayLarge: TextStyle(
            color: textDark, fontWeight: FontWeight.w800, fontSize: 56),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgWarmPaper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surfaceCLowest,
        elevation: 0,
        shadowColor: textDark.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: textDark.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: textDark.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: textDark,
          side: BorderSide(color: scheme.outlineVariant, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceCLow,
        selectedColor: secContainer,
        disabledColor: surfaceC,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textDark,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgWarmPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceCLow.withValues(alpha: 0.82),
        surfaceTintColor: surfaceC,
        indicatorColor: secContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 28);
          }
          return IconThemeData(
              color: textDark.withValues(alpha: 0.6), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: primary);
          }
          return TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: textDark.withValues(alpha: 0.6));
        }),
      ),
      fontFamily: 'IBM Plex Sans Arabic',
      primaryColor: const Color(0xFF059669),

      visualDensity: VisualDensity.adaptivePlatformDensity,

      /// ستايل الزر الرئيسي (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
          ),
        ),
      ),

      /// ستايل الزر الثانوي (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
          ),
        ),
      ),
    );
  }
}
