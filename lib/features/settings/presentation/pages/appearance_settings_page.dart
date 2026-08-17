import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/ui/docmac_iconly.dart';

/// Lets a user choose and persist Light, Dark, or System appearance.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: RadioGroup<ThemeMode>(
        groupValue: themeProvider.themeMode,
        onChanged: (mode) {
          if (mode != null) {
            themeProvider.setThemeMode(mode);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _AppearanceOption(
              label: 'Light',
              icon: DocmacIconlyLight.show,
              mode: ThemeMode.light,
              currentMode: themeProvider.themeMode,
            ),
            _AppearanceOption(
              label: 'Dark',
              icon: DocmacIconlyLight.hide,
              mode: ThemeMode.dark,
              currentMode: themeProvider.themeMode,
            ),
            _AppearanceOption(
              label: 'System default',
              icon: DocmacIconlyLight.setting,
              mode: ThemeMode.system,
              currentMode: themeProvider.themeMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.currentMode,
  });

  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    final selected = mode == currentMode;
    final colorScheme = Theme.of(context).colorScheme;

    return RadioListTile<ThemeMode>(
      value: mode,
      activeColor: colorScheme.primary,
      title: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}
