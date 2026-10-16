import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/docmac_community_icons.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/orbit/presentation/pages/orbit_page.dart';
import '../../features/me/presentation/pages/me_page.dart';
import '../../features/talk/presentation/pages/talk_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.pages})
      : assert(pages == null || pages.length == 4);

  /// Allows lightweight shell navigation tests without initializing feature
  /// dependencies. Production uses the four standard tab pages.
  final List<Widget>? pages;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = ['/orbit', '/talk', '/live', '/me'];

  late final PageController _pageController;
  var _selectedIndex = 0;
  String? _lastSyncedLocation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final location = GoRouterState.of(context).matchedLocation;
    if (location != _lastSyncedLocation) {
      _lastSyncedLocation = location;
      final routeIndex = _destinations.indexOf(location);
      if (routeIndex >= 0 && routeIndex != _selectedIndex) {
        _selectedIndex = routeIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(routeIndex);
          }
        });
      }
    }
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    _lastSyncedLocation = _destinations[index];
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    context.go(_destinations[index]);
  }

  void _handlePageChanged(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _lastSyncedLocation = _destinations[index];
      context.go(_destinations[index]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The PageView moves only the tab content. Keeping the navigation bar
      // outside it makes the bar remain stationary, like WhatsApp's tabs.
      body: PageView(
        controller: _pageController,
        onPageChanged: _handlePageChanged,
        children: widget.pages ??
            const [
              OrbitPage(),
              TalkPage(),
              LivePage(),
              MePage(),
            ],
      ),
      bottomNavigationBar: _AppNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectPage,
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
                icon: DocmacCommunityIcons.home,
                selectedIcon: DocmacCommunityIcons.home,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _NavItem(
                label: 'Talk',
                icon: DocmacCommunityIcons.talk,
                selectedIcon: DocmacCommunityIcons.talk,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _NavItem(
                label: 'Live',
                icon: DocmacCommunityIcons.live,
                selectedIcon: DocmacCommunityIcons.live,
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _NavItem(
                label: 'Me',
                icon: DocmacCommunityIcons.profile,
                selectedIcon: DocmacCommunityIcons.profile,
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
  final String icon;
  final String selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use a deeper selected blue in light mode and a high-contrast neutral
    // color when inactive. The SVG wrapper applies these colors to every path.
    final color = selected
        ? (Theme.of(context).brightness == Brightness.light
            ? AppColors.brandBase
            : scheme.primary)
        : scheme.onSurface;

    return Expanded(
      child: Semantics(
        key: ValueKey('app-nav-${label.toLowerCase()}'),
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? (Theme.of(context).brightness == Brightness.light
                            ? AppColors.brandBase.withValues(alpha: 0.10)
                            : scheme.primary.withValues(alpha: 0.14))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DocmacCommunityIcon(
                    asset: selected ? selectedIcon : icon,
                    color: color,
                    size: 21,
                    semanticLabel: label,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
