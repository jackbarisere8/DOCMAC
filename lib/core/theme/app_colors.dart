import 'package:flutter/material.dart';

/// Raw color and layout tokens used by Docmac's themes.
///
/// Application widgets should read colors and typography from
/// `Theme.of(context)` rather than referring to these values directly.
class AppColors {
  AppColors._();

  // Brand — kept identical in both themes so Docmac remains recognizable.
  // Rose is reserved for actions and selected controls; Black Cherry anchors
  // small brand moments without recolouring the app's neutral surfaces.
  static const brandBase = Color(0xFF2A0C1B); // Black Cherry
  static const primary = Color(0xFFBE2C55); // Perfect Rose
  static const accent = Color(0xFFFFE0EB); // Carousel Pink
  static const success = Color(0xFFC9657F);
  static const danger = Color(0xFFE06B70);

  // Dark theme surfaces.
  static const darkBackground = Color(0xFF202D41);
  static const darkSurface = Color(0xFF292A2C);
  static const darkCard = Color(0xFF202D41);
  static const darkDivider = Color(0xFF465166);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFE7E9EB);

  // Light theme surfaces.
  static const lightBackground = Color(0xFFEEFEFE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFDCE4E6);
  static const lightTextPrimary = Color(0xFF202D41);
  static const lightTextSecondary = Color(0xFF637083);
}

class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class AppSpacing {
  AppSpacing._();

  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
}
