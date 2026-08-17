import 'dark_theme.dart';
import 'light_theme.dart';

export 'app_colors.dart';
export 'theme_provider.dart';

/// Single import point for the application's Material themes.
class AppTheme {
  AppTheme._();

  static final light = lightTheme;
  static final dark = darkTheme;
}
