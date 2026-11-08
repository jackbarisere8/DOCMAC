import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accent,
    onPrimaryContainer: AppColors.brandBase,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accent,
    onSecondaryContainer: AppColors.brandBase,
    tertiary: AppColors.accent,
    onTertiary: AppColors.brandBase,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    surfaceContainerLowest: AppColors.lightBackground,
    surfaceContainerLow: Color(0xFFF0F2F5),
    surfaceContainer: Color(0xFFEBEDF0),
    surfaceContainerHigh: Color(0xFFE4E7EB),
    surfaceContainerHighest: Color(0xFFDCE0E5),
    outline: Color(0xFF7A8794),
    outlineVariant: AppColors.lightDivider,
    error: AppColors.danger,
    onError: Colors.white,
  ),
  dividerColor: AppColors.lightDivider,
  textTheme: GoogleFonts.spaceGroteskTextTheme(const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 15, color: AppColors.lightTextPrimary),
    bodyMedium: TextStyle(
      fontSize: 13.5,
      color: AppColors.lightTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
  )),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.lightTextPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.lightSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 12,
    shadowColor: const Color(0x24000000),
    menuPadding: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    iconColor: AppColors.lightTextSecondary,
    iconSize: 20,
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.lightCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: const BorderSide(color: AppColors.lightDivider),
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
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(64, 44),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: AppSpacing.md,
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightCard,
    contentPadding: const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: AppSpacing.sm,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.lightTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.lightTextSecondary,
        size: 21,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.lightDivider,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary.withValues(alpha: 0.4)
          : AppColors.lightDivider.withValues(alpha: 0.6),
    ),
  ),
);
