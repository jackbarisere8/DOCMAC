import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/docmac_iconly.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/orbit/presentation/pages/orbit_page.dart';
import '../../features/me/presentation/pages/me_page.dart';
import '../../features/talk/presentation/pages/talk_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    const destinations = ['/orbit', '/talk', '/live', '/me'];
    final selectedIndex = destinations.indexOf(location);

    final page = switch (location) {
      '/talk' => const TalkPage(),
      '/live' => const LivePage(),
      '/me' => const MePage(),
      _ => const OrbitPage(),
    };

    return Scaffold(
      body: page,
      bottomNavigationBar: _AppNavigation(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (index) => context.go(destinations[index]),
      ),
    );
  }
}

class _AppNavigation extends StatelessWidget {
  const _AppNavigation({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                label: 'Orbit',
                icon: DocmacIconlyLight.home,
                selectedIcon: DocmacIconlyBold.home,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _NavItem(
                label: 'Talk',
                icon: DocmacIconlyLight.chat,
                selectedIcon: DocmacIconlyBold.chat,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _NavItem(
                label: 'Live',
                icon: DocmacIconlyLight.voice,
                selectedIcon: DocmacIconlyBold.voice,
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _NavItem(
                label: 'Me',
                icon: DocmacIconlyLight.profile,
                selectedIcon: DocmacIconlyBold.profile,
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 21),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
