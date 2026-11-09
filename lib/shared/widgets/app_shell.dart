import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/docmac_iconly.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/orbit/presentation/pages/orbit_page.dart';
import '../../features/me/presentation/pages/me_page.dart';
import '../../features/talk/presentation/pages/talk_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.pages,
    this.navigationShell,
  }) : assert(pages == null || pages.length == 4);

  /// Allows lightweight shell navigation tests without initializing feature
  /// dependencies. Production uses the four standard tab pages.
  final List<Widget>? pages;

  /// Injected by [StatefulShellRoute] so the shell keeps the navigation bar
  /// completely static and stationary while tabs switch cleanly.
  final StatefulNavigationShell? navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = ['/orbit', '/talk', '/live', '/me'];

  late final PageController _pageController;
  var _selectedIndex = 0;
  String? _lastSyncedLocation;

  bool _isBottomNavVisible = true;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.navigationShell != null) return;

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

  int get _currentIndex =>
      widget.navigationShell?.currentIndex ?? _selectedIndex;

  void _selectPage(int index) {
    if (widget.navigationShell != null) {
      if (index == widget.navigationShell!.currentIndex) return;
      // When leaving home page or switching tabs, make sure bottom nav is visible
      _pauseTimer?.cancel();
      if (!_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
      return;
    }

    if (index == _selectedIndex) return;

    _pauseTimer?.cancel();
    if (!_isBottomNavVisible) {
      _isBottomNavVisible = true;
    }

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

  bool _handleScrollNotification(ScrollNotification notification) {
    // The hide/show animation only runs on the home page (Orbit, tab index 0).
    if (_currentIndex != 0) {
      if (!_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
      return false;
    }

    // Only respond to vertical scrolling of the page feed.
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    // When near the top, always show the navigation bar.
    if (notification.metrics.pixels <= 10) {
      _pauseTimer?.cancel();
      if (!_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta != null &&
          notification.scrollDelta!.abs() > 1.2) {
        // While user is actively scrolling, hide bottom navigation.
        if (_isBottomNavVisible) {
          setState(() => _isBottomNavVisible = false);
        }

        // Debounce: once user stops or pauses scrolling, show it back.
        _pauseTimer?.cancel();
        _pauseTimer = Timer(const Duration(milliseconds: 360), () {
          if (mounted && !_isBottomNavVisible) {
            setState(() => _isBottomNavVisible = true);
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _pauseTimer?.cancel();
      if (!_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _pauseTimer?.cancel();
        if (!_isBottomNavVisible) {
          setState(() => _isBottomNavVisible = true);
        }
      }
    }

    return false;
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex;

    final Widget bodyChild = widget.navigationShell ??
        PageView(
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          children: widget.pages ??
              const [
                OrbitPage(),
                TalkPage(),
                LivePage(),
                MePage(),
              ],
        );

    return Scaffold(
      // The bottom navigation bar stays static and stationary outside the
      // pages. Only on the home page does it slide out during active scroll
      // and animate back once scrolling pauses or stops.
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: bodyChild,
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.25),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: _isBottomNavVisible ? 1.0 : 0.0,
          child: _AppNavigation(
            selectedIndex: activeIndex,
            onSelected: _selectPage,
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceContainer : scheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: scheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    // Monochrome theme: dark in light mode, white in dark mode.
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final pillBackground = selected
        ? (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.07))
        : Colors.transparent;

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
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: pillBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
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
