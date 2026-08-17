import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Phase 1's primary relationship surface. A person is not reduced to a
/// message thread: Talk, Live and shared activity all begin here.
class PersonSpacePage extends StatelessWidget {
  const PersonSpacePage({super.key, required this.personId});

  final String personId;

  _Person get _person => _people[personId] ?? _people['emma']!;

  static const _people = <String, _Person>{
    'emma': _Person('Emma Clarke', 'EC', 'Available',
        'Reading, cooking and the occasional long walk.', true),
    'jack': _Person('Jack Wilson', 'JW', 'Available',
        'Taking the scenic route home.', true),
    'david': _Person('David Okafor', 'DO', 'Quiet',
        'Making thoughtful things with good people.', false),
    'tobi': _Person('Tobi Adeyemi', 'TA', 'Last active Monday',
        'Always up for a new idea.', false),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = _person;
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
              onSelected: (value) => _handleOption(context, value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Share profile')),
                PopupMenuItem(value: 'block', child: Text('Block person')),
                PopupMenuItem(value: 'report', child: Text('Report person')),
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
              onTalk: () => context.push('/chat?person=$personId'),
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
      'share' => '${_person.name}’s profile is ready to share.',
      'block' => 'Block controls will keep ${_person.name} out of your Orbit.',
      _ => 'Thanks. Your report will be reviewed privately.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab({required this.person, required this.onCall});

  final _Person person;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.graphic_eq_rounded,
                size: 46, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Meet ${person.name.split(' ').first} live',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              person.isAvailable
                  ? '${person.name.split(' ').first} is available for a voice call.'
                  : 'You can start a voice call when ${person.name.split(' ').first} is ready.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded),
              label: const Text('Start voice call'),
            ),
          ]),
        ),
      );
}

class _TalkTab extends StatelessWidget {
  const _TalkTab(
      {required this.person, required this.onTalk, required this.onLive});

  final _Person person;
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
                      'Let ${person.name.split(' ').first} see a day-in-the-life update',
                  onTap: () => context.push(
                      '/moments?shareWith=${person.name.split(' ').first}')),
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
  final _Person person;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
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
                Icon(person.isAvailable ? Icons.circle : Icons.bedtime_outlined,
                    size: 12,
                    color: person.isAvailable
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
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _MomentsTab extends StatelessWidget {
  const _MomentsTab({required this.person});
  final _Person person;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Moments with ${person.name.split(' ').first}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Shared updates disappear after 24 hours.'),
          const SizedBox(height: 20),
          const _MomentCard(
              icon: Icons.menu_book_outlined,
              title: 'A good read',
              subtitle: 'Emma · 2h left'),
          const SizedBox(height: 12),
          const _MomentCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Slow Sunday',
              subtitle: 'You · 8h left'),
        ],
      );
}

class _MomentCard extends StatelessWidget {
  const _MomentCard(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        height: 118,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const Spacer(),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle),
        ]),
      );
}

class _MediaTab extends StatelessWidget {
  const _MediaTab();
  @override
  Widget build(BuildContext context) => const _EmptyRelationshipTab(
      icon: Icons.photo_library_outlined,
      title: 'Media shared here will live together.');
}

class _FilesTab extends StatelessWidget {
  const _FilesTab();
  @override
  Widget build(BuildContext context) => const _EmptyRelationshipTab(
      icon: Icons.folder_open_outlined,
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

class _Person {
  const _Person(
      this.name, this.initials, this.status, this.bio, this.isAvailable);
  final String name;
  final String initials;
  final String status;
  final String bio;
  final bool isAvailable;
}
