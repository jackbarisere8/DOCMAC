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
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: Colors.transparent,
      destinations: const [
        NavigationDestination(
          icon: Icon(DocmacIconlyLight.home),
          selectedIcon: _SelectedNavIcon(icon: DocmacIconlyBold.home),
          label: 'Orbit',
        ),
        NavigationDestination(
          icon: Icon(DocmacIconlyLight.chat),
          selectedIcon: _SelectedNavIcon(icon: DocmacIconlyBold.chat),
          label: 'Talk',
        ),
        NavigationDestination(
          icon: Icon(DocmacIconlyLight.voice),
          selectedIcon: _SelectedNavIcon(icon: DocmacIconlyBold.voice),
          label: 'Live',
        ),
        NavigationDestination(
          icon: Icon(DocmacIconlyLight.profile),
          selectedIcon: _SelectedNavIcon(icon: DocmacIconlyBold.profile),
          label: 'Me',
        ),
      ],
    );
  }
}

class _SelectedNavIcon extends StatelessWidget {
  const _SelectedNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: scheme.onSurface, size: 19),
    );
  }
}
