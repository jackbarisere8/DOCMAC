import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

const _people = <_PeopleProfile>[
  _PeopleProfile('Emma Clarke', 'emma', 'E', 'Available now', true),
  _PeopleProfile('David Mensah', 'davidm', 'D', 'Design Circle', false),
  _PeopleProfile('Amara Okafor', 'amara', 'A', 'Active 12m ago', true),
  _PeopleProfile('Nora Williams', 'noraw', 'N', 'Sunday Notes', false),
  _PeopleProfile('Tobi Adeyemi', 'tobi', 'T', 'Available now', true),
];

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = _people
        .where((person) => person.matches(_query))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            tooltip: 'People settings',
            onPressed: () => context.push('/contacts/settings'),
            icon: const Icon(DocmacIconlyLight.setting),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _PeopleSearch(
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 18),
          if (_query.isNotEmpty) ...[
            _SectionHeader(
              title: matches.isEmpty ? 'No people found' : 'People',
              icon: DocmacIconlyLight.search,
            ),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              const _EmptySearch()
            else
              _PeopleCard(
                children: [
                  for (final person in matches)
                    _PersonTile(
                      person: person,
                      trailing: const Icon(DocmacIconlyLight.arrowRight),
                    ),
                ],
              ),
          ] else ...[
            _PeopleAction(
              icon: DocmacIconlyLight.addUser,
              title: 'Link requests',
              detail: '2 people want to link with you',
              badge: '2',
              onTap: () => context.push('/people/requests'),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Your People',
              icon: DocmacIconlyLight.user,
              action: 'See all',
              onAction: () => context.push('/people/all'),
            ),
            const SizedBox(height: 10),
            _PeopleCard(
              children: [
                for (final person in _people.take(3))
                  _PersonTile(
                    person: person,
                    trailing: const Icon(DocmacIconlyLight.chat),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Discover',
              icon: DocmacIconlyLight.discovery,
              action: 'Explore',
              onAction: () => context.push('/people/discover'),
            ),
            const SizedBox(height: 10),
            const _PeopleCard(
              children: [
                _DiscoverTile(
                  icon: DocmacIconlyLight.search,
                  title: 'Find by username',
                  detail: 'Find someone with their @username',
                ),
                _DiscoverTile(
                  icon: DocmacIconlyLight.activity,
                  title: 'Met through Docmac',
                  detail: 'People you encountered in shared spaces',
                ),
              ],
            ),
            const SizedBox(height: 28),
            _ImportContactsCard(onTap: () => context.push('/people/invite')),
          ],
        ],
      ),
    );
  }
}

class PeopleRequestsPage extends StatelessWidget {
  const PeopleRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Requests')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _SectionHeader(
              title: 'Received',
              icon: DocmacIconlyLight.addUser,
            ),
            const SizedBox(height: 10),
            _PeopleCard(
              children: [
                _PersonTile(
                  person: _people[3],
                  detail: 'You met in Sunday Notes',
                  trailing: _RequestActions(
                    onAccept: () => _showNotice(context, 'You are now linked with Nora.'),
                  ),
                ),
                _PersonTile(
                  person: _people[1],
                  detail: '2 mutual Circles',
                  trailing: _RequestActions(
                    onAccept: () => _showNotice(context, 'You are now linked with David.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionHeader(
              title: 'Sent',
              icon: DocmacIconlyLight.send,
            ),
            const SizedBox(height: 10),
            _PeopleCard(
              children: [
                _PersonTile(
                  person: _people[4],
                  detail: 'Link request sent yesterday',
                  trailing: const _StatusPill(label: 'Pending'),
                ),
              ],
            ),
          ],
        ),
      );
}

class YourPeoplePage extends StatefulWidget {
  const YourPeoplePage({super.key});

  @override
  State<YourPeoplePage> createState() => _YourPeoplePageState();
}

class _YourPeoplePageState extends State<YourPeoplePage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final people = switch (_filter) {
      'Favorites' => _people.take(2).toList(growable: false),
      'Available' => _people.where((person) => person.available).toList(growable: false),
      _ => _people,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Your People')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const ['All', 'Favorites', 'Available'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PeopleCard(
            children: [
              for (final person in people)
                _PersonTile(
                  person: person,
                  trailing: const Icon(DocmacIconlyLight.chat),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PeopleDiscoverPage extends StatefulWidget {
  const PeopleDiscoverPage({super.key});

  @override
  State<PeopleDiscoverPage> createState() => _PeopleDiscoverPageState();
}

class _PeopleDiscoverPageState extends State<PeopleDiscoverPage> {
  String _username = '';

  @override
  Widget build(BuildContext context) {
    final result = _people.where((person) => person.matches(_username)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          TextField(
            onChanged: (value) => setState(() => _username = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search username',
              prefixText: '@ ',
              prefixIcon: Icon(DocmacIconlyLight.search),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Met through Docmac',
            icon: DocmacIconlyLight.activity,
          ),
          const SizedBox(height: 10),
          _PeopleCard(
            children: [
              _PersonTile(
                person: _people[3],
                detail: 'Shared Space · Sunday Notes',
                trailing: _LinkButton(
                  onPressed: () => _showNotice(context, 'Link request sent to Nora.'),
                ),
              ),
              _PersonTile(
                person: _people[1],
                detail: '2 mutual Links · Design Circle',
                trailing: _LinkButton(
                  onPressed: () => _showNotice(context, 'Link request sent to David.'),
                ),
              ),
            ],
          ),
          if (_username.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionHeader(
              title: 'Username results',
              icon: DocmacIconlyLight.user,
            ),
            const SizedBox(height: 10),
            _PeopleCard(
              children: result.isEmpty
                  ? const [_NoUsernameResult()]
                  : [
                      for (final person in result)
                        _PersonTile(
                          person: person,
                          trailing: _LinkButton(
                            onPressed: () => _showNotice(context, 'Link request sent to ${person.name}.'),
                          ),
                        ),
                    ],
            ),
          ],
        ],
      ),
    );
  }
}

class PeopleInvitePage extends StatelessWidget {
  const PeopleInvitePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Find people you know')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _ImportContactsCard(
            expanded: true,
            onTap: () => _showNotice(
              context,
              'Contact import will always ask for your permission first.',
            ),
          ),
        ),
      );
}

class _PeopleSearch extends StatelessWidget {
  const _PeopleSearch({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Find people...',
          prefixIcon: Icon(DocmacIconlyLight.search),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.action,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 9),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          if (action != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(DocmacIconlyLight.arrowRight, size: 14),
              label: Text(action!),
              iconAlignment: IconAlignment.end,
            ),
        ],
      );
}

class _PeopleAction extends StatelessWidget {
  const _PeopleAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: scheme.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(detail, style: TextStyle(color: scheme.onPrimary.withValues(alpha: .8), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.onPrimary, shape: BoxShape.circle),
                child: Text(badge, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const Divider(height: 1, indent: 70),
            ],
          ],
        ),
      );
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, required this.trailing, this.detail});

  final _PeopleProfile person;
  final Widget trailing;
  final String? detail;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push('/person/${person.username}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Avatar(person: person),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      detail ?? '@${person.username}  ·  ${person.detail}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      );
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push('/people/discover'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(detail, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(DocmacIconlyLight.arrowRight, size: 17),
            ],
          ),
        ),
      );
}

class _ImportContactsCard extends StatelessWidget {
  const _ImportContactsCard({required this.onTap, this.expanded = false});

  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: expanded ? const BoxConstraints(minHeight: 220) : null,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(15)),
                child: Icon(DocmacIconlyLight.addUser, color: scheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find people you know', style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Import contacts only when you choose to.', style: TextStyle(color: scheme.onSecondaryContainer.withValues(alpha: .76), fontSize: 12)),
                  ],
                ),
              ),
              Icon(DocmacIconlyLight.arrowRight, color: scheme.onSecondaryContainer, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person});

  final _PeopleProfile person;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(person.initial, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          if (person.available)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      );
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onAccept, child: const Text('Accept')),
          IconButton(
            tooltip: 'Ignore request',
            onPressed: () => _showNotice(context, 'Request ignored.'),
            icon: const Icon(DocmacIconlyLight.closeSquare, size: 19),
          ),
        ],
      );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(DocmacIconlyLight.addUser, size: 15),
        label: const Text('Link'),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(DocmacIconlyLight.search, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            const Text('Try a name or @username.'),
          ],
        ),
      );
}

class _NoUsernameResult extends StatelessWidget {
  const _NoUsernameResult();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(18),
        child: Text('No matching username found.'),
      );
}

class _PeopleProfile {
  const _PeopleProfile(this.name, this.username, this.initial, this.detail, this.available);

  final String name;
  final String username;
  final String initial;
  final String detail;
  final bool available;

  bool matches(String query) {
    final normalized = query.toLowerCase().replaceFirst('@', '');
    return name.toLowerCase().contains(normalized) || username.contains(normalized);
  }
}

void _showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
