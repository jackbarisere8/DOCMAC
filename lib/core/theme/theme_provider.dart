import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the user's Light, Dark, or System appearance choice.
class ThemeProvider extends Notifier<ThemeMode> {
  static const _prefsKey = 'docmac_theme_mode';

  SharedPreferences? _preferences;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  ThemeMode get themeMode => state;

  @override
  ThemeMode build() {
    _loadPreferences();
    return ThemeMode.system;
  }

  Future<void> _loadPreferences() async {
    _preferences ??= await SharedPreferences.getInstance();
    final saved = _preferences!.getString(_prefsKey);
    final mode = _fromString(saved) ?? ThemeMode.system;
    _initialized = true;
    if (state != mode) {
      state = mode;
    }
  }

  /// Loads the saved preference before the first application frame or when needed.
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences!.getString(_prefsKey);
    final mode = _fromString(saved) ?? ThemeMode.system;
    _initialized = true;
    state = mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;

    final preferences = _preferences ?? await SharedPreferences.getInstance();
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

final themeProvider =
    NotifierProvider<ThemeProvider, ThemeMode>(ThemeProvider.new);
