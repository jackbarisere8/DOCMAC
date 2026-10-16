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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const _TopBar(),
                  const SizedBox(height: 22),
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
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    eyebrow: 'YOUR PULSE',
                    title: 'Keep your people close',
                  ),
                  const SizedBox(height: 12),
                  const _PulseGrid(),
                  const SizedBox(height: 30),
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
                  const _SectionTitle(
                    eyebrow: 'DISCOVER',
                    title: 'Small spaces, real connection',
                  ),
                  const SizedBox(height: 12),
                  const _SpaceGrid(),
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

    final displayName = user?.displayName?.trim();
    final firstName = (displayName?.isNotEmpty == true)
        ? displayName!.split(' ').first
        : null;
    final initial = firstName?.substring(0, 1).toUpperCase() ?? 'D';
    final greeting =
        firstName != null ? 'Welcome back, $firstName' : 'Welcome back';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Your people are close.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/notifications');
          },
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.notification,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                  semanticLabel: 'Arrivals',
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
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
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.darkBackground,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(initial,
                          style: const TextStyle(fontWeight: FontWeight.w800))
                      : null,
                ),
              ),
            );
          },
        ),
      ],
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
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search people, talks and moments',
        prefixIcon: const Icon(DocmacIconlyLight.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: onClear,
              )
            : IconButton(
                icon: const Icon(DocmacIconlyLight.filter, size: 19),
                onPressed: () => context.push('/search'),
              ),
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
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
