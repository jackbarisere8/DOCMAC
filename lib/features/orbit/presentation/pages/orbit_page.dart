import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_community_icons.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../me/presentation/profile_media_store.dart';
import '../../../people/data/models/person_profile.dart';
import '../../../people/presentation/providers/people_providers.dart';

class OrbitPage extends ConsumerStatefulWidget {
  const OrbitPage({super.key});

  @override
  ConsumerState<OrbitPage> createState() => _OrbitPageState();
}

class _OrbitPageState extends ConsumerState<OrbitPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedCategoryIndex = 0;

  static const _categories = [
    'All',
    'Pulse',
    'Orbit',
    'Moments',
    'Forge',
    'Relays',
    'Spaces',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const _TopBar(),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 22),
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
                      title: 'Recent Drops',
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
                      title: 'Small spaces, real connection',
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
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photoUrl = user?.photoUrl;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName = user?.displayName?.trim();
    final firstName = (displayName?.isNotEmpty == true)
        ? displayName!.split(' ').first
        : null;
    final initial = firstName?.substring(0, 1).toUpperCase() ?? 'D';
    final name = displayName?.isNotEmpty == true ? displayName! : 'Docmac Pioneer';
    final email = user?.email;
    final handle = (email != null && email.isNotEmpty)
        ? '@${email.split('@').first}'
        : 'Your people are close.';

    return Row(
      children: [
        // Avatar on the left matching reference video layout
        ValueListenableBuilder<Uint8List?>(
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
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/me');
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  foregroundColor:
                      isDark ? Colors.white : const Color(0xFF0F172A),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(initial,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16))
                      : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 14),

        // User Identity Text Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                handle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Action Buttons on Right (Search & Notification)
        _HeaderActionButton(
          icon: DocmacIconlyLight.search,
          semanticLabel: 'Search',
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/search');
          },
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          icon: DocmacCommunityIcons.notification,
          isCommunityIcon: true,
          hasBadge: true,
          semanticLabel: 'Arrivals',
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/notifications');
          },
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
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
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 21,
                semanticLabel: semanticLabel,
              )
            else
              Icon(
                icon as IconData,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search people, talks, relays and moments...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: const Icon(DocmacIconlyLight.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : IconButton(
                  icon: const Icon(DocmacIconlyLight.filter, size: 19),
                  onPressed: () => context.push('/search'),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

class _CategoryFilterStrip extends StatelessWidget {
  const _CategoryFilterStrip({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Orbit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${categories.length} hubs',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    required this.accentColor,
    required this.previewIcon,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final String tag;
  final String route;
  final Color accentColor;
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
      title: 'Orbit Pulse',
      subtitle:
          'Keep your inner circle close, track live status and sync vibes.',
      badgeText: 'PULSE 2.0',
      tag: 'FEATURED',
      route: '/people/all',
      accentColor: Color(0xFF0284C7),
      previewIcon: DocmacIconlyLight.discovery,
    ),
    _ShowcaseItem(
      title: 'Moments Feed',
      subtitle:
          'Ephemeral audio clips, visual daydrops and candid snippets.',
      badgeText: 'AUDIO FIRST',
      tag: 'NEW',
      route: '/moments',
      accentColor: Color(0xFF8B5CF6),
      previewIcon: DocmacIconlyLight.video,
    ),
    _ShowcaseItem(
      title: 'Forge Lab',
      subtitle:
          'Private collaborative ideation spaces with whiteboard thoughts.',
      badgeText: 'COLLAB',
      tag: 'HOT',
      route: '/forge',
      accentColor: Color(0xFF10B981),
      previewIcon: DocmacIconlyLight.work,
    ),
    _ShowcaseItem(
      title: 'Relay Drops',
      subtitle:
          'Broadcast live audio waves directly to your verified circles.',
      badgeText: 'BROADCAST',
      tag: 'LIVE',
      route: '/relays',
      accentColor: Color(0xFFF59E0B),
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
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
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
          // Header Row: Tag & Stacked Depth Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      item.accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: item.accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // 3-layers stacked depth icon from reference video (00:13-00:19)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.layers_rounded,
                  size: 17,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Subtitle
          Text(
            item.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const Spacer(),

          // Preview graphic box with gradient
          Container(
            height: 72,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.accentColor.withValues(alpha: isDark ? 0.20 : 0.10),
                  item.accentColor.withValues(alpha: isDark ? 0.06 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: item.previewIcon is String
                        ? DocmacCommunityIcon(
                            asset: item.previewIcon as String,
                            color: item.accentColor,
                            size: 20,
                            semanticLabel: item.title,
                          )
                        : Icon(
                            item.previewIcon as IconData,
                            color: item.accentColor,
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
                          color: item.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap below to open hub',
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Black pill button matching video [ Explore Hub -> ]
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push(item.route);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white : const Color(0xFF0F172A),
                foregroundColor:
                    isDark ? const Color(0xFF0F172A) : Colors.white,
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
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
    final momentsStr = pulse.momentsCount.toString().padLeft(2, '0');
    final nearbyStr = pulse.nearbyCount.toString().padLeft(2, '0');

    return Row(
      children: [
        Expanded(
          child: _PulseCard(
            value: momentsStr,
            label: 'new moments',
            icon: DocmacIconlyLight.star,
            tint: AppColors.lightCard,
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
            tint: AppColors.lightDivider,
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
          height: 105,
          padding: const EdgeInsets.all(14),
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
                    color: Theme.of(context).colorScheme.primary, size: 17),
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
                    color: Theme.of(context).colorScheme.primary,
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
                    color: scheme.secondaryContainer, shape: BoxShape.circle),
                child: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.seeMore,
                  color: scheme.onSecondaryContainer,
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
                    Text('Perspectives worth exploring',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('Enter Forge to share and sharpen ideas.',
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
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.relay,
                  color: colors.onPrimaryContainer,
                  size: 23,
                  semanticLabel: 'Docmac Relay',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Docmac Relay',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        'A calmer way to share, talk and stay close is taking shape.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              DocmacCommunityIcon(
                asset: DocmacCommunityIcons.seeMore,
                color: colors.primary,
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
    const moments = [
      ('Add', 'Create\na moment', DocmacIconlyLight.plus, AppColors.primary),
      ('Nora', 'Sunday\nnotes', DocmacIconlyLight.edit, AppColors.lightCard),
      ('David', 'Little\nwins', DocmacIconlyLight.star, AppColors.lightDivider),
      (
        'Emma',
        'A good\nread',
        DocmacIconlyLight.document,
        AppColors.darkTextSecondary
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

    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text('No one in your Orbit matches “$query”.',
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
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(person.initials,
                  style: const TextStyle(
                      color: AppColors.brandBase, fontWeight: FontWeight.w800)),
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
                    size: 16, color: Theme.of(context).colorScheme.primary),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SpaceCard(
          label: 'Weekend\nplans',
          icon: DocmacIconlyLight.discovery,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/spaces');
          },
        ),
        _SpaceCard(
          label: 'Design\nclub',
          icon: DocmacIconlyLight.category,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/spaces');
          },
        ),
        _SpaceCard(
          label: 'Music\nroom',
          icon: DocmacIconlyLight.activity,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/spaces');
          },
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
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
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
