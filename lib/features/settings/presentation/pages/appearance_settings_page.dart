import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/ui/docmac_iconly.dart';

/// Lets a user choose and persist Light, Dark, or System appearance.
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: RadioGroup<ThemeMode>(
        groupValue: themeMode,
        onChanged: (mode) {
          if (mode != null) {
            ref.read(themeProvider.notifier).setThemeMode(mode);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _AppearanceOption(
              label: 'Light',
              icon: DocmacIconlyLight.show,
              mode: ThemeMode.light,
              currentMode: themeMode,
            ),
            _AppearanceOption(
              label: 'Dark',
              icon: DocmacIconlyLight.hide,
              mode: ThemeMode.dark,
              currentMode: themeMode,
            ),
            _AppearanceOption(
              label: 'System default',
              icon: DocmacIconlyLight.setting,
              mode: ThemeMode.system,
              currentMode: themeMode,
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
