import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  // ── Tema KETORA — oscuro premium (fiel a logos oficiales) ──
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary:   AppColors.verdeMedio,
      secondary: AppColors.oro,
      surface:   AppColors.surface,
      error:     AppColors.error,
      brightness: Brightness.dark,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.verdeOs,
      foregroundColor: AppColors.blanco,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.blanco,
      ),
    ),

    // Bottom NavBar — se sobreescribe en AppShell
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.verdeOs,
      selectedItemColor: AppColors.verdeMedio,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Elevated Button — premium green pill
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.verde,
        foregroundColor: AppColors.blanco,
        minimumSize: const Size(88, 52),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.pressed)
              ? AppColors.verdeOs.withValues(alpha: 0.15)
              : null,
        ),
      ),
    ),

    // Outlined Button — verde border
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.verde,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppColors.verde, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.verde,
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      surfaceTintColor: Colors.transparent,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fondoGris,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.verde, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 17),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 17),
      floatingLabelStyle: const TextStyle(color: AppColors.verde, fontSize: 15, fontWeight: FontWeight.w600),
    ),

    // Chip — for category filters
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.fondoGris,
      selectedColor: AppColors.verde.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w500),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.blanco,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.blanco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minVerticalPadding: 8,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (s) => s.contains(WidgetState.selected) ? AppColors.verde : null,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (s) => s.contains(WidgetState.selected) ? AppColors.verde.withValues(alpha: 0.4) : null,
      ),
    ),

    // Text — tamaños accesibles para adultos mayores
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleMedium:   TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge:     TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      labelMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textHint),
    ),

    scaffoldBackgroundColor: AppColors.surface,
    dividerColor: AppColors.divider,

  );

  // ── Dark Theme (preparado para futura implementación) ──────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary: AppColors.verde,
      secondary: AppColors.oro,
      surface: AppColors.surfaceDark,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
  );
}
