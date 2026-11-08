import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';
import '../../data/models/person_profile.dart';
import '../providers/people_providers.dart';

/// Docmac relationship surface: Talk, Live, and shared moments unified.
class PersonSpacePage extends ConsumerWidget {
  const PersonSpacePage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final repoPerson = ref.watch(personByIdProvider(personId));

    if (repoPerson == null && !AppFeatureFlags.localPreviews) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'This person is not available in this build. Start a private '
              'talk with an exact @username from New talk.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Fallback for local preview contacts in debug builds.
    final current = repoPerson ??
        PersonProfile(
          id: personId,
          name: personId.length > 1
              ? personId[0].toUpperCase() + personId.substring(1)
              : personId.toUpperCase(),
          initials: personId.substring(0, 1).toUpperCase(),
          status: 'Local preview contact',
          bio: 'Sample contact shown only in debug builds.',
          isOnline: false,
        );

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(current.name),
          actions: [
            IconButton(
              tooltip: 'Start a voice call',
              onPressed: () => context.push('/live/call/$personId'),
              icon: const Icon(Icons.call_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Person options',
              icon: const Icon(Icons.more_vert_rounded, size: 21),
              onSelected: (value) => _handleOption(context, value),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'share',
                  child: DocmacMenuItem(
                    icon: DocmacIconlyLight.send,
                    label: 'Share profile',
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: DocmacMenuItem(
                    icon: DocmacIconlyLight.closeSquare,
                    label: 'Block person',
                    destructive: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: DocmacMenuItem(
                    icon: DocmacIconlyLight.danger,
                    label: 'Report person',
                    destructive: true,
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Talk'),
              Tab(text: 'Live'),
              Tab(text: 'Moments'),
              Tab(text: 'Media'),
              Tab(text: 'Files'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TalkTab(
              person: current,
              onTalk: () => context.push('/talk/person/$personId'),
              onLive: () => context.push('/live/call/$personId'),
            ),
            _LiveTab(
              person: current,
              onCall: () => context.push('/live/call/$personId'),
            ),
            _MomentsTab(person: current),
            const _MediaTab(),
            const _FilesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/live/call/$personId'),
          icon: const Icon(Icons.call_rounded),
          label: const Text('Voice call'),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
    );
  }

  void _handleOption(BuildContext context, String option) {
    final message = switch (option) {
      'share' => 'Profile sharing is not available yet.',
      'block' => 'Blocking is not available yet.',
      _ => 'Reporting is not available yet.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab({required this.person, required this.onCall});

  final PersonProfile person;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.graphic_eq_rounded,
                size: 46, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Try a simulated call',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Calls in this build are simulated on this device. No audio is '
              'sent and ${person.shortName} is not dialled.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded),
              label: const Text('Open call screen'),
            ),
          ]),
        ),
      );
}

class _TalkTab extends StatelessWidget {
  const _TalkTab(
      {required this.person, required this.onTalk, required this.onLive});

  final PersonProfile person;
  final VoidCallback onTalk;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        _PersonHero(person: person),
        const SizedBox(height: 24),
        Text('Between you', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _RelationshipAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Talk',
                  detail: 'Continue your private conversation',
                  onTap: onTalk),
              Divider(color: Theme.of(context).dividerColor),
              _RelationshipAction(
                  icon: Icons.call_outlined,
                  title: 'Live',
                  detail: 'Start a voice call',
                  onTap: onLive),
              Divider(color: Theme.of(context).dividerColor),
              _RelationshipAction(
                  icon: Icons.add_reaction_outlined,
                  title: 'Share a moment',
                  detail:
                      'Let ${person.shortName} see a day-in-the-life update',
                  onTap: () => context.push(
                      '/moments?shareWith=${Uri.encodeComponent(person.shortName)}')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(person.bio,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45)),
      ],
    );
  }
}

class _PersonHero extends StatelessWidget {
  const _PersonHero({required this.person});
  final PersonProfile person;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: person.tint.withValues(alpha: 0.2),
          foregroundColor: colors.onSurface,
          child: Text(person.initials,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Row(children: [
                Icon(person.isOnline ? Icons.circle : Icons.bedtime_outlined,
                    size: 12,
                    color: person.isOnline
                        ? colors.primary
                        : colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(person.status,
                    style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelationshipAction extends StatelessWidget {
  const _RelationshipAction(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      );
}

class _MomentsTab extends StatelessWidget {
  const _MomentsTab({required this.person});
  final PersonProfile person;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_outline_rounded, size: 42),
            const SizedBox(height: 14),
            Text('No shared moments with ${person.shortName} yet.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(
                  '/moments?shareWith=${Uri.encodeComponent(person.shortName)}'),
              child: const Text('Post a moment'),
            ),
          ]),
        ),
      );
}

class _MediaTab extends StatelessWidget {
  const _MediaTab();
  @override
  Widget build(BuildContext context) => const _EmptyRelationshipTab(
      icon: Icons.photo_library_outlined,
      title: 'Photos and videos shared in this talk will appear here.');
}

class _FilesTab extends StatelessWidget {
  const _FilesTab();
  @override
  Widget build(BuildContext context) => const _EmptyRelationshipTab(
      icon: Icons.attach_file_rounded,
      title: 'Files shared here will live together.');
}

class _EmptyRelationshipTab extends StatelessWidget {
  const _EmptyRelationshipTab({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center)
          ])));
}
