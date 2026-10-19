import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/docmac_iconly.dart';
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
                icon: DocmacIconlyLight.home,
                selectedIcon: DocmacIconlyBold.home,
                selected: selectedIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(0);
                },
              ),
              _NavItem(
                label: 'Talk',
                icon: DocmacIconlyLight.chat,
                selectedIcon: DocmacIconlyBold.chat,
                selected: selectedIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(1);
                },
              ),
              _NavItem(
                label: 'Live',
                icon: DocmacIconlyLight.voice,
                selectedIcon: DocmacIconlyBold.voice,
                selected: selectedIndex == 2,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(2);
                },
              ),
              _NavItem(
                label: 'Me',
                icon: DocmacIconlyLight.profile,
                selectedIcon: DocmacIconlyBold.profile,
                selected: selectedIndex == 3,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(3);
                },
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final color = selected
        ? (isDark ? scheme.primary : AppColors.brandBase)
        : scheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        key: ValueKey('app-nav-${label.toLowerCase()}'),
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                            ? scheme.primary.withValues(alpha: 0.16)
                            : AppColors.brandBase.withValues(alpha: 0.10))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      key: ValueKey(selected),
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
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
