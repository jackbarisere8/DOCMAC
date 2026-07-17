import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
