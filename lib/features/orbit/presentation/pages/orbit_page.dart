import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_community_icons.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../me/presentation/profile_media_store.dart';
import '../../../people/data/models/person_profile.dart';
import '../../../people/presentation/providers/people_providers.dart';

/// A single featured-hub destination. Keeping the icon next to the label lets
/// the hub rail read as one deliberate, monochrome system instead of a set of
/// unrelated coloured buttons.
class _HubCategory {
  const _HubCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class OrbitPage extends ConsumerStatefulWidget {
  const OrbitPage({super.key});

  @override
  ConsumerState<OrbitPage> createState() => _OrbitPageState();
}

class _OrbitPageState extends ConsumerState<OrbitPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  int _selectedCategoryIndex = 0;
  bool _isHeaderVisible = true;
  Timer? _pauseTimer;

  static const _categories = [
    _HubCategory('All', Icons.grid_view_rounded),
    _HubCategory('Pulse', DocmacIconlyLight.activity),
    _HubCategory('Orbit', DocmacIconlyLight.discovery),
    _HubCategory('Moments', DocmacIconlyLight.video),
    _HubCategory('Forge', DocmacIconlyLight.work),
    _HubCategory('Relays', Icons.podcasts_rounded),
    _HubCategory('Spaces', Icons.groups_2_outlined),
  ];

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification.metrics.pixels <= 10) {
      _pauseTimer?.cancel();
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible = true);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta != null &&
          notification.scrollDelta!.abs() > 1.2) {
        if (_isHeaderVisible) {
          setState(() => _isHeaderVisible = false);
        }

        _pauseTimer?.cancel();
        _pauseTimer = Timer(const Duration(milliseconds: 360), () {
          if (mounted && !_isHeaderVisible) {
            setState(() => _isHeaderVisible = true);
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _pauseTimer?.cancel();
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible = true);
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _pauseTimer?.cancel();
        if (!_isHeaderVisible) {
          setState(() => _isHeaderVisible = true);
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isHeaderVisible
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TopBar(),
                              SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        context.push('/search?q=${Uri.encodeComponent(query)}');
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          _CategoryFilterStrip(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                            onSelected: (index) =>
                                setState(() => _selectedCategoryIndex = index),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedCategoryIndex == 0) ...[
                            const _FeaturedShowcaseCarousel(),
                            const SizedBox(height: 28),
                          ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 1) ...[
                    const _SectionTitle(
                      eyebrow: 'YOUR PULSE',
                      title: 'Keep your people close',
                    ),
                    const SizedBox(height: 12),
                    const _PulseGrid(),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 2) ...[
                    _RowHeading(
                      title: 'Your Orbit',
                      action: 'People',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/people/all');
                      },
                    ),
                    const SizedBox(height: 12),
                    _InnerOrbit(onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/people/all');
                    }),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 3) ...[
                    _RowHeading(
                      title: 'Moments',
                      action: 'See archive',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/moments');
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 136, child: _MomentStrip()),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 4) ...[
                    _RowHeading(
                      title: 'Forge',
                      action: 'Explore ideas',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/forge');
                      },
                    ),
                    const SizedBox(height: 12),
                    _ForgeEntry(onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/forge');
                    }),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 5) ...[
                    _RowHeading(
                      title: 'Relays',
                      action: 'View Relays',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/relays');
                      },
                    ),
                    const SizedBox(height: 12),
                    _RelayEntry(onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/relays');
                    }),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 2) ...[
                    _RowHeading(
                      title: 'Active now',
                      action: 'View all',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/people/all');
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActivePeople(query: _query),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 6) ...[
                    const _SectionTitle(
                      eyebrow: 'DISCOVER',
                      title: 'Try a Space on this device',
                    ),
                    const SizedBox(height: 12),
                    const _SpaceGrid(),
                  ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photoUrl = user?.photoUrl;
    final displayName = user?.displayName?.trim();
    final firstName = (displayName?.isNotEmpty == true)
        ? displayName!.split(' ').first
        : null;
    final initial = firstName?.substring(0, 1).toUpperCase() ?? 'D';

    return Row(
      children: [
        const _DocmacWordmark(),
        const Spacer(),
        _HeaderActionButton(
          key: const ValueKey('orbit-arrivals'),
          icon: DocmacCommunityIcons.notification,
          isCommunityIcon: true,
          hasBadge: true,
          semanticLabel: 'Arrivals',
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/notifications');
          },
        ),
        const SizedBox(width: 8),
        _HeaderProfileButton(initial: initial, photoUrl: photoUrl),
      ],
    );
  }
}

/// Compact wordmark used at the top of the home surface. Unbounded's wide,
/// geometric letterforms give "DocMac" a distinctive brand voice while the
/// tight tracking keeps it crisp at header size.
class _DocmacWordmark extends StatelessWidget {
  const _DocmacWordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'DocMac',
      semanticsLabel: 'DocMac',
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'DocmacWordmark',
        fontSize: 23,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: scheme.onSurface,
      ),
    );
  }
}

class _HeaderProfileButton extends StatelessWidget {
  const _HeaderProfileButton({required this.initial, this.photoUrl});

  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Your profile',
      child: Tooltip(
        message: 'Your profile',
        child: ValueListenableBuilder<Uint8List?>(
          valueListenable: ProfileMediaStore.avatarBytes,
          builder: (BuildContext context, Uint8List? avatarBytes, Widget? _) {
            final ImageProvider<Object>? avatarImage;
            if (avatarBytes != null) {
              avatarImage = MemoryImage(avatarBytes);
            } else if (photoUrl?.trim().isNotEmpty == true) {
              avatarImage = NetworkImage(photoUrl!);
            } else {
              avatarImage = null;
            }

            return InkWell(
              key: const ValueKey('orbit-profile'),
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/me');
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: scheme.surfaceContainerHigh,
                  foregroundColor: scheme.onSurface,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.isCommunityIcon = false,
    this.hasBadge = false,
  });

  final dynamic icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isCommunityIcon;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCommunityIcon)
                  DocmacCommunityIcon(
                    asset: icon as String,
                    color: scheme.onSurface,
                    size: 21,
                  )
                else
                  Icon(
                    icon as IconData,
                    color: scheme.onSurface,
                    size: 20,
                  ),
                if (hasBadge)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return DocmacSearchBar(
      controller: controller,
      hintText: 'Search...',
      semanticsLabel: 'Search people, talks, relays and moments',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onCleared: onClear,
    );
  }
}

class _CategoryFilterStrip extends StatelessWidget {
  const _CategoryFilterStrip({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_HubCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Featured Orbit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HubCountBadge(count: categories.length),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                _HubChip(
                  category: categories[index],
                  selected: selectedIndex == index,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(index);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HubChip extends StatelessWidget {
  const _HubChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _HubCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.surface : scheme.onSurface;
    final background = selected ? scheme.onSurface : scheme.surface;
    final borderColor = selected ? scheme.onSurface : scheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: '${category.label} hub',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(13, 9, 16, 9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.30 : 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: foreground,
                    letterSpacing: -0.1,
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

class _HubCountBadge extends StatelessWidget {
  const _HubCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: scheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            '$count hubs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseItem {
  const _ShowcaseItem({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.tag,
    required this.route,
    required this.previewIcon,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final String tag;
  final String route;
  final dynamic previewIcon;
}

class _FeaturedShowcaseCarousel extends StatefulWidget {
  const _FeaturedShowcaseCarousel();

  @override
  State<_FeaturedShowcaseCarousel> createState() =>
      _FeaturedShowcaseCarouselState();
}

class _FeaturedShowcaseCarouselState extends State<_FeaturedShowcaseCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  static const _items = [
    _ShowcaseItem(
      title: 'Your People',
      subtitle:
          'Find someone by their exact @username and start a private talk. Broad discovery is not available yet.',
      badgeText: 'TALK',
      tag: 'AVAILABLE',
      route: '/talk/new',
      previewIcon: DocmacIconlyLight.discovery,
    ),
    _ShowcaseItem(
      title: 'Moments',
      subtitle:
          'A local preview. Moments stay on this device and are not shared in this build.',
      badgeText: 'LOCAL PREVIEW',
      tag: 'PREVIEW',
      route: '/moments',
      previewIcon: DocmacIconlyLight.video,
    ),
    _ShowcaseItem(
      title: 'Forge',
      subtitle:
          'A local preview of structured perspectives. Nothing is published to other people.',
      badgeText: 'LOCAL PREVIEW',
      tag: 'PREVIEW',
      route: '/forge',
      previewIcon: DocmacIconlyLight.work,
    ),
    _ShowcaseItem(
      title: 'Relays',
      subtitle:
          'A local preview of one-to-many publishing. Live audio is not available in this build.',
      badgeText: 'LOCAL PREVIEW',
      tag: 'PREVIEW',
      route: '/relays',
      previewIcon: DocmacCommunityIcons.relay,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 275,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ShowcaseCard(item: item, isDark: isDark),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            final active = index == _currentPage;
            final scheme = Theme.of(context).colorScheme;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.item, required this.isDark});

  final _ShowcaseItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final inverseInk = scheme.surface;
    final muted = scheme.onSurfaceVariant;
    final hairline = scheme.outlineVariant;
    final tileColor =
        isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? scheme.outlineVariant : hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: quiet monochrome tag and a stacked-depth marker.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: isDark ? 0.10 : 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hairline),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: isDark ? 0.08 : 0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: hairline),
                ),
                child: Icon(
                  Icons.layers_rounded,
                  size: 17,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            item.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: muted,
            ),
          ),
          const Spacer(),

          // Monochrome preview surface with a fine diagonal texture. The icon
          // tile always inverts against the surrounding theme (black/white â†”
          // white/black) so the hub family reads as one system.
          Container(
            height: 72,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hairline, width: 1),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HubPatternPainter(
                      color: ink.withValues(alpha: isDark ? 0.055 : 0.045),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ink,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: item.previewIcon is String
                              ? DocmacCommunityIcon(
                                  asset: item.previewIcon as String,
                                  color: inverseInk,
                                  size: 20,
                                  semanticLabel: item.title,
                                )
                              : Icon(
                                  item.previewIcon as IconData,
                                  color: inverseInk,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap below to open hub',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Inverted pill action keeps a single strong focal point per card.
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push(item.route);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: inverseInk,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Explore Hub',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    DocmacIconlyLight.arrowRight,
                    size: 15,
                    color: inverseInk,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fine diagonal hatching used on monochrome hub surfaces. It gives the
/// cards a considered, editorial texture without introducing another colour.
class _HubPatternPainter extends CustomPainter {
  const _HubPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 11.0;
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HubPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OrbitNoticeCard extends StatelessWidget {
  const _OrbitNoticeCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            )),
      ],
    );
  }
}

class _PulseGrid extends ConsumerWidget {
  const _PulseGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(orbitPulseProvider);
    final scheme = Theme.of(context).colorScheme;
    final momentsStr = AppFeatureFlags.localPreviews
        ? pulse.momentsCount.toString().padLeft(2, '0')
        : 'â€”';
    final nearbyStr = AppFeatureFlags.localPreviews
        ? pulse.nearbyCount.toString().padLeft(2, '0')
        : 'â€”';

    return Row(
      children: [
        Expanded(
          child: _PulseCard(
            value: momentsStr,
            label: 'new moments',
            icon: DocmacIconlyLight.star,
            tint: scheme.surfaceContainerHigh,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/moments');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PulseCard(
            value: nearbyStr,
            label: 'people nearby',
            icon: DocmacIconlyLight.activity,
            tint: scheme.surfaceContainerHigh,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/people/discover');
            },
          ),
        ),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 118,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: Theme.of(context).colorScheme.onSurface, size: 17),
              ),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowHeading extends StatelessWidget {
  const _RowHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        Semantics(
          button: true,
          label: '$action: $title',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Row(
                children: [
                  Text(action,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(width: 5),
                  DocmacCommunityIcon(
                    asset: DocmacCommunityIcons.seeMore,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 15,
                    semanticLabel: action,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InnerOrbit extends ConsumerWidget {
  const _InnerOrbit({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(innerOrbitPeopleProvider);
    final scheme = Theme.of(context).colorScheme;

    if (people.isEmpty) {
      return const _OrbitNoticeCard(
        icon: DocmacIconlyLight.discovery,
        title: 'People discovery is not available yet',
        detail:
            'Start a private talk with an exact @username from the New talk screen.',
      );
    }

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (final person in people)
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/person/${person.id}');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: person.tint.withValues(alpha: 0.2),
                        foregroundColor: scheme.onSurface,
                        child: Text(
                          person.shortName.substring(0, 1),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        person.shortName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.seeMore,
                  color: scheme.onSurface,
                  size: 15,
                  semanticLabel: 'View people',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgeEntry extends StatelessWidget {
  const _ForgeEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(DocmacIconlyLight.work, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forge local preview',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        'Open Forge to try a perspective on this device. Sharing is not available yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onPrimary.withValues(alpha: .8))),
                  ],
                ),
              ),
              DocmacCommunityIcon(
                asset: DocmacCommunityIcons.seeMore,
                color: colors.onPrimary,
                semanticLabel: 'Open Forge',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelayEntry extends StatelessWidget {
  const _RelayEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.relay,
                  color: colors.onSurface,
                  size: 23,
                  semanticLabel: 'Docmac Relay',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Relays local preview',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        'Draft a Relay and Drops on this device. Nothing is published to other people.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              DocmacCommunityIcon(
                asset: DocmacCommunityIcons.seeMore,
                color: colors.onSurface,
                semanticLabel: 'Open Docmac Relay',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentStrip extends StatelessWidget {
  const _MomentStrip();

  @override
  Widget build(BuildContext context) {
    if (!AppFeatureFlags.localPreviews) {
      return const _OrbitNoticeCard(
        icon: DocmacIconlyLight.video,
        title: 'Moments are not available yet',
        detail:
            'This build cannot create or share moments, so no sample people or viewers are shown.',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final moments = [
      ('Add', 'Create\na moment', DocmacIconlyLight.plus, scheme.primary),
      (
        'Nora',
        'Sunday\nnotes',
        DocmacIconlyLight.edit,
        scheme.surfaceContainerHigh
      ),
      (
        'David',
        'Little\nwins',
        DocmacIconlyLight.star,
        scheme.surfaceContainerHigh
      ),
      (
        'Emma',
        'A good\nread',
        DocmacIconlyLight.document,
        scheme.surfaceContainerHighest
      ),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: moments.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final moment = moments[index];
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/moments');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 118,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: index == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: index == 0
                  ? null
                  : Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.white.withValues(alpha: .16)
                        : moment.$4,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(moment.$3,
                      size: 17,
                      color: index == 0
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary),
                ),
                const Spacer(),
                Text(moment.$1,
                    style: TextStyle(
                      color: index == 0
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    )),
                Text(moment.$2,
                    style: TextStyle(
                      color: index == 0
                          ? AppColors.darkTextPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.15,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivePeople extends ConsumerWidget {
  const _ActivePeople({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(activeNowPeopleProvider);
    final people = all
        .where((person) =>
            person.name.toLowerCase().contains(query.toLowerCase()) ||
            person.status.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (all.isEmpty) {
      return const _OrbitNoticeCard(
        icon: DocmacIconlyLight.activity,
        title: 'People search is not available yet',
        detail:
            'This build cannot show real activity or discover people. Search by exact @username from New talk instead.',
      );
    }

    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text('No one in your Orbit matches â€œ$queryâ€.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < people.length; index++) ...[
            _PersonRow(person: people[index]),
            if (index != people.length - 1)
              Divider(
                height: 1,
                indent: 66,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final PersonProfile person;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/person/${person.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: person.isOnline
                    ? person.tint.withValues(alpha: 0.25)
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(person.initials,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(person.status,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11)),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/talk/person/${person.id}');
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(DocmacIconlyLight.chat,
                    size: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceGrid extends StatelessWidget {
  const _SpaceGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OrbitNoticeCard(
          icon: DocmacIconlyLight.category,
          title: 'Spaces are a local preview',
          detail:
              'A Space you create stays on this device, is not shared with other people, and disappears when the app restarts.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SpaceCard(
              label: 'Create a\nSpace',
              icon: DocmacIconlyLight.plus,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/spaces/new');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 100,
          height: 104,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: Theme.of(context).colorScheme.onSurface, size: 22),
              const Spacer(),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.12)),
            ],
          ),
        ),
      ),
    );
  }
}
