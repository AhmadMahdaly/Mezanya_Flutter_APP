import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData tactileManuscript() {
    const primary = Color(0xFF1C6D25);
    const primaryDim = Color(0xFF096119);
    const bgWarmPaper = Color(0xFFFBF9F5);
    const surfaceCLow = Color(0xFFF5F4EF);
    const surfaceC = Color(0xFFEFEEE9);
    const surfaceCLowest = Color(0xFFFFFFFF);
    const textDark = Color(0xFF31332F);
    const textSoft = Color(0xFF767873);
    const secContainer = Color(0xFFCBE7F5);
    const terContainer = Color(0xFFFEB64C);

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
        elevation:
            0, // We rely on shadowColor and explicit decoration in UI, or set elevation to 4 with diffused shadow
        shadowColor: textDark.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: textDark.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: textDark.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: textDark,
          side: BorderSide(color: scheme.outlineVariant, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
        backgroundColor:
            surfaceCLow.withValues(alpha: 0.8), // Glassmorphism base
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
      primaryColor: const Color(0xFF1C6D25),

      visualDensity: VisualDensity.adaptivePlatformDensity,

      /// ستايل الزر الرئيسي (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C6D25),
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
          // foregroundColor: AppColors.textGreyColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
          ),
        ),
      ), // Fallback sans-serif mimicking the neutral editorial tone since Plus Jakarta isn't bundled
    );
  }
}
