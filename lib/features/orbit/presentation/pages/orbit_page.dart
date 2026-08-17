import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../me/presentation/profile_media_store.dart';

class OrbitPage extends StatefulWidget {
  const OrbitPage({super.key});

  @override
  State<OrbitPage> createState() => _OrbitPageState();
}

class _OrbitPageState extends State<OrbitPage> {
  String _query = '';

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
                      onChanged: (value) => setState(() => _query = value)),
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
                    onTap: () => context.push('/people'),
                  ),
                  const SizedBox(height: 12),
                  _InnerOrbit(onTap: () => context.push('/people')),
                  const SizedBox(height: 30),
                  const _RowHeading(title: 'Moments', action: 'See archive'),
                  const SizedBox(height: 12),
                  const SizedBox(height: 136, child: _MomentStrip()),
                  const SizedBox(height: 30),
                  const _RowHeading(title: 'Forge', action: 'Explore ideas'),
                  const SizedBox(height: 12),
                  _ForgeEntry(onTap: () => context.push('/forge')),
                  const SizedBox(height: 30),
                  const _RowHeading(title: 'Recent Drops', action: 'View Relays'),
                  const SizedBox(height: 12),
                  _RelayEntry(onTap: () => context.push('/relays')),
                  const SizedBox(height: 30),
                  const _RowHeading(title: 'Active now', action: 'View all'),
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
    final photoUrl = ref.watch(currentUserProvider)?.photoUrl;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Jack',
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
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(DocmacIconlyLight.notification,
                    color: Theme.of(context).colorScheme.primary),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
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
              onTap: () => context.go('/me'),
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
                      ? const Text('J',
                          style: TextStyle(fontWeight: FontWeight.w800))
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          const Positioned(right: -16, top: -8, child: _SignalArtwork()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SUNDAY · 06:37',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Your circle is here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.9,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Three people shared a moment with you today.',
                style: TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalArtwork extends StatelessWidget {
  const _SignalArtwork();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .85,
      child: SizedBox(
        width: 134,
        height: 126,
        child: Stack(
          children: [
            for (final item in const [
              (16.0, 52.0, 26.0, AppColors.darkTextPrimary),
              (52.0, 18.0, 48.0, AppColors.primary),
              (88.0, 54.0, 22.0, AppColors.darkTextSecondary),
              (50.0, 78.0, 34.0, AppColors.darkTextPrimary),
            ])
              Positioned(
                left: item.$1,
                top: item.$2,
                child: Transform.rotate(
                  angle: .785,
                  child: Container(
                    width: item.$3,
                    height: item.$3,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: .68),
                      borderRadius: BorderRadius.circular(5),
                    ),
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
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      onTap: () => context.push('/search'),
      readOnly: true,
      decoration: const InputDecoration(
        hintText: 'Search people, talks and moments',
        prefixIcon: Icon(DocmacIconlyLight.search),
        suffixIcon: Icon(DocmacIconlyLight.filter, size: 19),
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

class _PulseGrid extends StatelessWidget {
  const _PulseGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _PulseCard(
            value: '05',
            label: 'new moments',
            icon: DocmacIconlyLight.star,
            tint: AppColors.lightCard,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _PulseCard(
            value: '03',
            label: 'people nearby',
            icon: DocmacIconlyLight.activity,
            tint: AppColors.lightDivider,
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
  });

  final String value;
  final String label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
    );
  }
}

class _RowHeading extends StatelessWidget {
  const _RowHeading({required this.title, required this.action, this.onTap});

  final String title;
  final String action;
  final VoidCallback? onTap;

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
        InkWell(
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
                const SizedBox(width: 4),
                Icon(DocmacIconlyLight.arrowRight,
                    size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InnerOrbit extends StatelessWidget {
  const _InnerOrbit({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const people = [
      ('Emma', 'E'),
      ('David', 'D'),
      ('Amara', 'A'),
      ('Nora', 'N'),
      ('Tobi', 'T')
    ];
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              for (final person in people)
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(person.$2,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 7),
                      Text(person.$1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: scheme.secondaryContainer, shape: BoxShape.circle),
                child: Icon(DocmacIconlyLight.arrowRight,
                    size: 15, color: scheme.onSecondaryContainer),
              ),
            ],
          ),
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
              Icon(DocmacIconlyLight.arrowRight, color: colors.onPrimary),
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
        child: Padding(
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
                child: Icon(DocmacIconlyLight.discovery,
                    color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Docmac Relay',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('A calmer way to share, talk and stay close is taking shape.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(DocmacIconlyLight.arrowRight, color: colors.primary),
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
          onTap: () => context.push('/moments'),
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

class _ActivePeople extends StatelessWidget {
  const _ActivePeople({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final people = const [
      ('Jack', 'Listening to your update', 'J', true),
      ('Emma', 'Last active 2m ago', 'E', true),
      ('David', 'Typing in Weekend plans', 'D', false),
    ]
        .where(
            (person) => person.$1.toLowerCase().contains(query.toLowerCase()))
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
            _PersonRow(
                name: people[index].$1,
                detail: people[index].$2,
                initial: people[index].$3,
                active: people[index].$4),
            if (index != people.length - 1)
              const Divider(height: 1, indent: 66),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.detail,
    required this.initial,
    required this.active,
  });

  final String name;
  final String detail;
  final String initial;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/person/${name.toLowerCase()}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.darkTextPrimary : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(initial,
                  style: TextStyle(
                      color: AppColors.brandBase,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(detail,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(DocmacIconlyLight.chat,
                  size: 16, color: Theme.of(context).colorScheme.primary),
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
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SpaceCard(label: 'Weekend\nplans', icon: DocmacIconlyLight.discovery),
        _SpaceCard(label: 'Design\nclub', icon: DocmacIconlyLight.category),
        _SpaceCard(label: 'Music\nroom', icon: DocmacIconlyLight.activity),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
    );
  }
}
