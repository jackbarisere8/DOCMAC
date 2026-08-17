import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkSurface,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF5A1731),
    onPrimaryContainer: AppColors.accent,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF5A1731),
    onSecondaryContainer: AppColors.accent,
    tertiary: AppColors.accent,
    onTertiary: AppColors.brandBase,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.danger,
    onError: Colors.white,
  ),
  dividerColor: AppColors.darkDivider,
  textTheme: GoogleFonts.spaceGroteskTextTheme(const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 15, color: AppColors.darkTextPrimary),
    bodyMedium: TextStyle(
      fontSize: 13.5,
      color: AppColors.darkTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
  )),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: false,
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.darkSurface,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: const BorderSide(color: AppColors.darkDivider),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.darkTextPrimary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: AppSpacing.sm,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.selected)
            ? AppColors.darkTextPrimary
            : AppColors.darkTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.darkTextPrimary
            : AppColors.darkTextSecondary,
        size: 21,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.accent
          : AppColors.darkDivider,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.accent.withValues(alpha: 0.4)
          : AppColors.darkDivider.withValues(alpha: 0.6),
    ),
  ),
);
