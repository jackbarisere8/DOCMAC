import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';

const _samplePeople = <_PeopleProfile>[
  _PeopleProfile('Emma Clarke', 'emma', 'E', 'Available now', true),
  _PeopleProfile('David Mensah', 'davidm', 'D', 'Design Circle', false),
  _PeopleProfile('Amara Okafor', 'amara', 'A', 'Active 12m ago', true),
  _PeopleProfile('Nora Williams', 'noraw', 'N', 'Sunday Notes', false),
  _PeopleProfile('Tobi Adeyemi', 'tobi', 'T', 'Available now', true),
];

final List<_PeopleProfile> _people =
    AppFeatureFlags.localPreviews ? _samplePeople : const <_PeopleProfile>[];

/// Incoming Link requests surfaced on the People hub.
final List<_PeopleProfile> _receivedLinkRequests = AppFeatureFlags.localPreviews
    ? <_PeopleProfile>[_samplePeople[3], _samplePeople[1]]
    : const <_PeopleProfile>[];

/// Live request queue so accepting or ignoring a request updates the People
/// hub badge as soon as you return to it.
final ValueNotifier<List<_PeopleProfile>> _pendingLinkRequests =
    ValueNotifier(List.of(_receivedLinkRequests));

/// Preview-only outgoing requests. Link requests are not implemented yet, so
/// release builds never add to this set and the UI must not claim anything was
/// sent.
final ValueNotifier<Set<String>> _outgoingLinkRequests = ValueNotifier(
    AppFeatureFlags.localPreviews ? <String>{'tobi'} : <String>{});

/// Suggestions exclude people with an incoming request so Discover never asks
/// you to send a Link request to someone who is already waiting on you.
final List<_PeopleProfile> _discoverPeople = _people
    .where((person) => !_receivedLinkRequests.contains(person))
    .take(2)
    .toList(growable: false);

/// Fresh faces shown in Add people. They are deliberately separate from the
/// existing roster so adding someone visibly grows the circle.
const List<_PeopleProfile> _sampleSuggestedPeople = [
  _PeopleProfile('Maya Chen', 'mayac', 'M', '3 mutual Links', false),
  _PeopleProfile('Liam Brooks', 'liamb', 'L', 'Available now', true),
  _PeopleProfile('Sofia Reyes', 'sofiar', 'S', 'Product Circle', false),
  _PeopleProfile('Noah Kim', 'noahk', 'N', 'Shared Space · Design', false),
];

final List<_PeopleProfile> _suggestedPeople = AppFeatureFlags.localPreviews
    ? _sampleSuggestedPeople
    : const <_PeopleProfile>[];

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _PeopleProfile.normalizeQuery(_query);
    final matches = _people
        .where((person) => person.matches(normalizedQuery))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            tooltip: 'Connections & contacts',
            onPressed: () => context.push('/connections'),
            icon: const Icon(Icons.people_alt_rounded),
          ),
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
            ValueListenableBuilder<List<_PeopleProfile>>(
              valueListenable: _pendingLinkRequests,
              builder: (context, requests, _) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    _PeopleAction(
                      icon: DocmacIconlyLight.addUser,
                      title: 'Link requests',
                      detail:
                          '${requests.length} ${requests.length == 1 ? 'person wants' : 'people want'} to link with you',
                      badge: '${requests.length}',
                      onTap: () => context.push('/people/requests'),
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
            _SectionHeader(
              title: 'Your People',
              icon: DocmacIconlyLight.user,
              action: 'See all',
              onAction: () => context.push('/people/all'),
            ),
            const SizedBox(height: 10),
            if (_people.isEmpty)
              // ignore: prefer_const_constructors
              _PeopleCard(children: const [_PeopleUnavailable()])
            else
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
            _PeopleCard(
              children: [
                _DiscoverTile(
                  icon: DocmacIconlyLight.search,
                  title: 'Find by username',
                  detail: 'Start a talk with an exact @username',
                  onTap: () => context.push('/talk/new'),
                ),
                const _DiscoverTile(
                  icon: DocmacIconlyLight.activity,
                  title: 'Met through Docmac',
                  detail: 'People you encountered in shared spaces',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PeopleCard(
              children: [
                _DiscoverTile(
                  icon: DocmacIconlyLight.addUser,
                  title: 'Add people',
                  detail: 'Search your circles and send a Link request',
                  onTap: () => _showAddPeopleSheet(context),
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

class PeopleRequestsPage extends StatefulWidget {
  const PeopleRequestsPage({super.key});

  @override
  State<PeopleRequestsPage> createState() => _PeopleRequestsPageState();
}

class _PeopleRequestsPageState extends State<PeopleRequestsPage> {
  void _resolve(_PeopleProfile person, String message) {
    _pendingLinkRequests.value = List.unmodifiable(
      _pendingLinkRequests.value.where((request) => request != person),
    );
    _showNotice(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link requests')),
      body: ValueListenableBuilder<List<_PeopleProfile>>(
        valueListenable: _pendingLinkRequests,
        builder: (context, requests, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _SectionHeader(
              title: 'Pending requests',
              icon: DocmacIconlyLight.addUser,
            ),
            const SizedBox(height: 10),
            if (requests.isEmpty)
              const _PeopleCard(
                children: [
                  _NoRequestsRow(),
                ],
              )
            else
              _PeopleCard(
                children: [
                  for (final person in requests)
                    _PersonTile(
                      person: person,
                      detail: person.username == 'noraw'
                          ? 'You met in Sunday Notes'
                          : '2 mutual Circles',
                      trailing: _RequestActions(
                        onAccept: () => _resolve(
                          person,
                          'Preview only: removed from this list on this device. '
                          'Linking is not available yet.',
                        ),
                        onIgnore: () => _resolve(
                          person,
                          'Preview only: request hidden on this device. '
                          'No one was notified.',
                        ),
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
            ValueListenableBuilder<Set<String>>(
              valueListenable: _outgoingLinkRequests,
              builder: (context, outgoing, _) {
                final sent = _suggestedPeople
                    .where((person) => outgoing.contains(person.username))
                    .toList(growable: false);
                return _PeopleCard(
                  children: [
                    if (_people.isEmpty)
                      const _PeopleUnavailable()
                    else ...[
                      _PersonTile(
                        person: _people[4],
                        detail: 'Link request sent yesterday',
                        trailing: const _StatusPill(label: 'Pending'),
                      ),
                      for (final person in sent)
                        _PersonTile(
                          person: person,
                          detail: 'Link request sent just now',
                          trailing: const _StatusPill(label: 'Pending'),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class YourPeoplePage extends StatefulWidget {
  const YourPeoplePage({super.key});

  @override
  State<YourPeoplePage> createState() => _YourPeoplePageState();
}

class _YourPeoplePageState extends State<YourPeoplePage> {
  String _filter = 'All';
  String _query = '';

  void _openAddPeople() => _showAddPeopleSheet(context);

  void _acceptRequest(_PeopleProfile person) {
    _pendingLinkRequests.value = List.unmodifiable(
      _pendingLinkRequests.value.where((request) => request != person),
    );
    _showNotice(
      context,
      'Preview only: removed from this list on this device. '
      'Linking is not available yet.',
    );
  }

  void _ignoreRequest(_PeopleProfile person) {
    _pendingLinkRequests.value = List.unmodifiable(
      _pendingLinkRequests.value.where((request) => request != person),
    );
    _showNotice(
      context,
      'Preview only: request hidden on this device. No one was notified.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _PeopleProfile.normalizeQuery(_query);
    final people = switch (_filter) {
      'Favorites' => _people.take(2).toList(growable: false),
      'Available' =>
        _people.where((person) => person.available).toList(growable: false),
      _ => _people,
    }
        .where((person) => person.matches(normalizedQuery))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your People'),
        actions: [
          IconButton(
            key: const ValueKey('your-people-add'),
            tooltip: 'Add people',
            onPressed: _openAddPeople,
            icon: const Icon(DocmacIconlyLight.addUser),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          DocmacSearchBar(
            hintText: 'Find people...',
            semanticsLabel: 'Find your people',
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<List<_PeopleProfile>>(
            valueListenable: _pendingLinkRequests,
            builder: (context, requests, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (requests.isNotEmpty) ...[
                  _LinkRequestsBanner(
                    count: requests.length,
                    onTap: () => context.push('/people/requests'),
                  ),
                  const SizedBox(height: 14),
                  _PeopleCard(
                    children: [
                      for (final person in requests)
                        _PersonTile(
                          person: person,
                          detail: person.username == 'noraw'
                              ? 'You met in Sunday Notes'
                              : '2 mutual Circles',
                          trailing: _RequestActions(
                            onAccept: () => _acceptRequest(person),
                            onIgnore: () => _ignoreRequest(person),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const ['All', 'Favorites', 'Available'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PeopleFilterChip(
                      label: filter,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Your People',
            icon: DocmacIconlyLight.user,
            action: '${people.length}',
          ),
          const SizedBox(height: 10),
          if (_people.isEmpty)
            const _PeopleCard(children: [_PeopleUnavailable()])
          else if (people.isEmpty)
            const _PeopleCard(
              children: [
                _EmptyPeopleSearch(),
              ],
            )
          else
            _PeopleCard(
              children: [
                for (final person in people)
                  _PersonTile(
                    person: person,
                    trailing: _PersonQuickActions(person: person),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          _AddPeopleCard(onTap: _openAddPeople),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Discover',
            icon: DocmacIconlyLight.discovery,
          ),
          const SizedBox(height: 10),
          _PeopleCard(
            children: [
              const _DiscoverTile(
                icon: DocmacIconlyLight.search,
                title: 'Find by username',
                detail: 'Find someone with their @username',
              ),
              _DiscoverTile(
                icon: DocmacIconlyLight.activity,
                title: 'Met through Docmac',
                detail: 'People you encountered in shared spaces',
                onTap: () => context.push('/people/discover'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ImportContactsCard(onTap: () => context.push('/people/invite')),
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
    if (_people.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discover')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            const _PeopleCard(children: [_PeopleUnavailable()]),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => context.push('/talk/new'),
              icon: const Icon(DocmacIconlyLight.chat),
              label: const Text('Start a talk by @username'),
            ),
          ],
        ),
      );
    }

    final normalizedUsername = _PeopleProfile.normalizeQuery(_username);
    final result =
        _people.where((person) => person.matches(normalizedUsername)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          DocmacSearchBar(
            hintText: 'Search username',
            semanticsLabel: 'Search username',
            onChanged: (value) => setState(() => _username = value.trim()),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Met through Docmac',
            icon: DocmacIconlyLight.activity,
          ),
          const SizedBox(height: 10),
          _PeopleCard(
            children: [
              for (final person in _discoverPeople)
                _PersonTile(
                  person: person,
                  detail: person.username == 'amara'
                      ? '2 mutual Links · Design Circle'
                      : 'Shared Space · Sunday Notes',
                  trailing: _LinkButton(person: person),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'People you may know',
            icon: DocmacIconlyLight.addUser,
          ),
          const SizedBox(height: 10),
          _PeopleCard(
            children: [
              for (final person in _suggestedPeople)
                _PersonTile(
                  person: person,
                  detail: '@${person.username}  ·  ${person.detail}',
                  trailing: _LinkButton(person: person),
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
                          trailing: _LinkButton(person: person),
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
              'Contact import is not available yet. Start a talk with an exact @username instead.',
            ),
          ),
        ),
      );
}

/// Show the shared Add people flow from the People hub or Your People.
void _showAddPeopleSheet(BuildContext pageContext) {
  showModalBottomSheet<void>(
    context: pageContext,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(pageContext).colorScheme.surface,
    builder: (sheetContext) => _AddPeopleSheet(
      onDiscover: () {
        Navigator.of(sheetContext).pop();
        pageContext.push('/talk/new');
      },
    ),
  );
}

void _sendLinkRequest(BuildContext context, _PeopleProfile person) {
  _showNotice(
    context,
    'Link requests are not available yet. Nothing was sent to '
    '${person.name.split(' ').first}.',
  );
}

class _LinkRequestsBanner extends StatelessWidget {
  const _LinkRequestsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                child: Icon(DocmacIconlyLight.addUser,
                    color: scheme.onPrimary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link requests',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count ${count == 1 ? 'person wants' : 'people want'} to link with you',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: .8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: scheme.onPrimary, shape: BoxShape.circle),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Icon(DocmacIconlyLight.arrowRight,
                  color: scheme.onPrimary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleFilterChip extends StatelessWidget {
  const _PeopleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.transparent : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 15, color: scheme.onPrimary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonQuickActions extends StatelessWidget {
  const _PersonQuickActions({required this.person});

  final _PeopleProfile person;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Talk to ${person.name.split(' ').first}',
        onPressed: () => context.push('/talk/person/${person.username}'),
        icon: const Icon(DocmacIconlyLight.chat),
      );
}

class _AddPeopleCard extends StatelessWidget {
  const _AddPeopleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(DocmacIconlyLight.addUser,
                    color: scheme.onPrimary, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add people',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFeatureFlags.localPreviews
                          ? 'Find friends by name or @username, then send a Link request.'
                          : 'Start a private talk with an exact @username.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(DocmacIconlyLight.arrowRight,
                  color: scheme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleUnavailable extends StatelessWidget {
  const _PeopleUnavailable();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DocmacIconlyLight.discovery, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('People discovery is not available yet',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'This build cannot list or recommend accounts. Start a private talk with an exact @username from New talk.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPeopleSearch extends StatelessWidget {
  const _EmptyPeopleSearch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      child: Row(
        children: [
          Icon(DocmacIconlyLight.search, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No people found',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Try a different name or @username.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPeopleSheet extends StatefulWidget {
  const _AddPeopleSheet({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  State<_AddPeopleSheet> createState() => _AddPeopleSheetState();
}

class _AddPeopleSheetState extends State<_AddPeopleSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalizedQuery = _PeopleProfile.normalizeQuery(_query);
    final results = _suggestedPeople
        .where((person) => person.matches(normalizedQuery))
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add people',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 3),
                        Text(
                          AppFeatureFlags.localPreviews
                              ? 'Send a Link request to start talking.'
                              : 'Link requests are not available yet. Start a talk with an exact @username.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: DocmacSearchBar(
                hintText: 'Search name or @username',
                semanticsLabel: 'Search people to add',
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _query.isEmpty
                    ? (_suggestedPeople.isEmpty
                        ? 'PEOPLE DISCOVERY'
                        : 'PEOPLE YOU MAY KNOW')
                    : '${results.length} MATCH${results.length == 1 ? '' : 'ES'}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                      child: Text(
                        _suggestedPeople.isEmpty
                            ? 'People discovery is not available yet. Use Find someone by @username to start a talk.'
                            : 'No one matched that search. Try another name or username.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) => _AddPersonTile(
                        person: results[index],
                      ),
                    ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextButton.icon(
                onPressed: widget.onDiscover,
                icon: Icon(DocmacIconlyLight.search,
                    size: 18, color: scheme.primary),
                label: const Text('Find someone by username'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPersonTile extends StatelessWidget {
  const _AddPersonTile({required this.person});

  final _PeopleProfile person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _outgoingLinkRequests,
      builder: (context, outgoing, _) {
        final requested = outgoing.contains(person.username);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              _Avatar(person: person),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '@${person.username}  ·  ${person.detail}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (requested)
                const _StatusPill(label: 'Requested')
              else
                FilledButton.tonalIcon(
                  key: ValueKey('add-person-${person.username}'),
                  onPressed: () => _sendLinkRequest(context, person),
                  icon: const Icon(DocmacIconlyLight.addUser, size: 15),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PeopleSearch extends StatelessWidget {
  const _PeopleSearch({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DocmacSearchBar(
        hintText: 'Find people...',
        semanticsLabel: 'Find people',
        onChanged: onChanged,
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
            child: Icon(icon,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 9),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
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
                    Text(title,
                        style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(detail,
                        style: TextStyle(
                            color: scheme.onPrimary.withValues(alpha: .8),
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: scheme.onPrimary, shape: BoxShape.circle),
                child: Text(badge,
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w900)),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, indent: 70),
          ],
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile(
      {required this.person, required this.trailing, this.detail});

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
                    Text(person.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      detail ?? '@${person.username}  ·  ${person.detail}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12),
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
  const _DiscoverTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap ?? () => context.push('/people/discover'),
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
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(detail,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12)),
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
                decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(DocmacIconlyLight.addUser, color: scheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find people you know',
                        style: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Contact import is not available yet.',
                        style: TextStyle(
                            color: scheme.onSecondaryContainer
                                .withValues(alpha: .76),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(DocmacIconlyLight.arrowRight,
                  color: scheme.onSecondaryContainer, size: 17),
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
            child: Text(person.initial,
                style: const TextStyle(fontWeight: FontWeight.w900)),
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
                  border: Border.all(
                      color: Theme.of(context).colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      );
}

class _NoRequestsRow extends StatelessWidget {
  const _NoRequestsRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Row(
        children: [
          Icon(DocmacIconlyLight.tickSquare, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No pending requests',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'You are all caught up.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _RequestActions extends StatelessWidget {
  const _RequestActions({required this.onAccept, required this.onIgnore});

  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: onAccept,
            icon: const Icon(DocmacIconlyLight.tickSquare, size: 16),
            label: const Text('Accept'),
          ),
          IconButton(
            tooltip: 'Ignore request',
            onPressed: onIgnore,
            icon: const Icon(DocmacIconlyLight.closeSquare, size: 19),
          ),
        ],
      );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.person});

  final _PeopleProfile person;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
        valueListenable: _outgoingLinkRequests,
        builder: (context, outgoing, _) {
          if (outgoing.contains(person.username)) {
            return const _StatusPill(label: 'Requested');
          }
          return TextButton.icon(
            onPressed: () => _sendLinkRequest(context, person),
            icon: const Icon(DocmacIconlyLight.addUser, size: 15),
            label: const Text('Link'),
          );
        },
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
        child: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(DocmacIconlyLight.search,
                size: 34, color: Theme.of(context).colorScheme.primary),
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
  const _PeopleProfile(
      this.name, this.username, this.initial, this.detail, this.available);

  final String name;
  final String username;
  final String initial;
  final String detail;
  final bool available;

  bool matches(String query) {
    return name.toLowerCase().contains(query) || username.contains(query);
  }

  /// Normalizes a raw user query for use with [matches].
  static String normalizeQuery(String raw) =>
      raw.toLowerCase().replaceFirst('@', '');
}

void _showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
