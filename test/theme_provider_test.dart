import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docmac_app/core/theme/theme_provider.dart';
import 'package:docmac_app/features/settings/presentation/pages/appearance_settings_page.dart';

void main() {
  test('loads a saved appearance preference', () async {
    SharedPreferences.setMockInitialValues({
      'docmac_theme_mode': 'dark',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themeProvider.notifier);

    await notifier.init();

    expect(container.read(themeProvider), ThemeMode.dark);
    expect(notifier.isInitialized, isTrue);
  });

  test('persists a newly selected appearance preference', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themeProvider.notifier);
    await notifier.init();

    await notifier.setThemeMode(ThemeMode.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('docmac_theme_mode'), 'light');
    expect(container.read(themeProvider), ThemeMode.light);
  });

  testWidgets('updates the theme when an appearance option is selected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AppearanceSettingsPage()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider), ThemeMode.dark);
  });
}
