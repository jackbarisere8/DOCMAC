import 'package:flutter/material.dart';

/// Raw color and layout tokens used by Docmac's themes.
///
/// Application widgets should read colors and typography from
/// `Theme.of(context)` rather than referring to these values directly.
class AppColors {
  AppColors._();

  // Brand — sampled from the primary Docmac mark. Blue is reserved for
  // actions and selected controls; surfaces stay neutral so they stand out.
  static const brandBase = Color(0xFF0A3D91); // Deep royal blue
  static const primary = Color(0xFF2677F9); // Sampled Docmac blue
  static const accent = Color(0xFFE7F0FF); // Pale blue
  static const success = Color(0xFF1F9D72);
  static const danger = Color(0xFFE06B70);

  // Dark theme surfaces.
  static const darkBackground = Color(0xFF0E1116);
  static const darkSurface = Color(0xFF151A21);
  static const darkCard = Color(0xFF1D242D);
  static const darkDivider = Color(0xFF313B47);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFAEB8C4);

  // Light theme surfaces.
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE4E7EC);
  static const lightTextPrimary = Color(0xFF16181D);
  static const lightTextSecondary = Color(0xFF667085);
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
