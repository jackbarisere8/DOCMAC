import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the user's Light, Dark, or System appearance choice.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'docmac_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Loads the saved preference before the first application frame.
  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode =
        _fromString(preferences.getString(_prefsKey)) ?? ThemeMode.system;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_prefsKey, _toString(mode));
  }

  String _toString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  ThemeMode? _fromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }
}
