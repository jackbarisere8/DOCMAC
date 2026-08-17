import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docmac_app/core/theme/theme_provider.dart';
import 'package:docmac_app/features/settings/presentation/pages/appearance_settings_page.dart';

void main() {
  test('loads a saved appearance preference', () async {
    SharedPreferences.setMockInitialValues({
      'docmac_theme_mode': 'dark',
    });
    final provider = ThemeProvider();

    await provider.init();

    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.isInitialized, isTrue);
  });

  test('persists a newly selected appearance preference', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await provider.init();

    await provider.setThemeMode(ThemeMode.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('docmac_theme_mode'), 'light');
  });

  testWidgets('updates the theme when an appearance option is selected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: provider,
        child: const MaterialApp(home: AppearanceSettingsPage()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(provider.themeMode, ThemeMode.dark);
  });
}
