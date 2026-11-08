import 'package:flutter/material.dart';

/// Raw color and layout tokens used by Docmac's themes.
///
/// Application widgets should read colors and typography from
/// `Theme.of(context)` rather than referring to these values directly.
class AppColors {
  AppColors._();

  // Brand — Docmac blue is used the way WhatsApp uses green: it is the one
  // accent that marks actions, selection, unread state and your own messages.
  // Everything else stays neutral white, grey or black.
  static const brandBase = Color(0xFF0A2F73); // Deep navy blue
  static const primary = Color(0xFF1A4FC4); // Deep Docmac blue
  static const accent = Color(0xFFDCE8FA); // Muted blue
  static const darkPrimary = Color(0xFF2F6BFF); // Clear blue on black
  static const darkOnPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF1F9D72);
  static const danger = Color(0xFFE06B70);

  // Dark theme surfaces — true black, like WhatsApp's dark appearance.
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0A0A0A);
  static const darkCard = Color(0xFF141414);
  static const darkDivider = Color(0xFF2A2A2A);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA6A6A6);

  // Light theme surfaces — a quiet neutral canvas so white cards and blue
  // accents do the work, instead of a blue-tinted page.
  static const lightBackground = Color(0xFFF5F6F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE4E7EB);
  static const lightTextPrimary = Color(0xFF111B21);
  static const lightTextSecondary = Color(0xFF667781);
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
