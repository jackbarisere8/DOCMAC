import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';
import '../../data/connections_controller.dart';
import '../../data/models/connection_profile.dart';
import '../widgets/connection_avatar.dart';

enum ConnectionTab { followers, contacts }

enum FollowerFilter { followers, following, requests }

/// The single place where the two sides of a Docmac relationship are kept
/// apart: social connections and phone contacts.
///
/// Connections never get a Talk button on their own. Chat is unlocked only when
/// the same person is also saved in the phone book, which is shown with an
/// explicit "In contacts" badge.
class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({
    super.key,
    this.initialTab = ConnectionTab.followers,
    this.initialFollowerFilter = FollowerFilter.followers,
  });

  final ConnectionTab initialTab;
  final FollowerFilter initialFollowerFilter;

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  late ConnectionTab _tab;
  late FollowerFilter _filter;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _filter = widget.initialFollowerFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(ConnectionTab tab) {
    if (_tab == tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = tab;
      _searchController.clear();
      _query = '';
    });
  }

  void _selectFilter(FollowerFilter filter) {
    if (_filter == filter) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = filter);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<ConnectionProfile> _matching(Iterable<ConnectionProfile> people) {
    final query = _query.trim().toLowerCase().replaceFirst('@', '');
    if (query.isEmpty) return people.toList(growable: false);
    return people
        .where(
          (person) =>
              person.name.toLowerCase().contains(query) ||
              person.username.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<ContactProfile> _matchingContacts(Iterable<ContactProfile> contacts) {
    final query = _query.trim().toLowerCase().replaceFirst('@', '');
    if (query.isEmpty) return contacts.toList(growable: false);
    return contacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(query) ||
              contact.phone.toLowerCase().contains(query) ||
              (contact.username?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(connectionsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 18,
        title: const Text('Connections'),
        actions: [
          IconButton(
            tooltip: 'Add a contact',
            onPressed: () => context.push('/contacts/new'),
            icon: const Icon(DocmacIconlyLight.addUser, size: 20),
          ),
          IconButton(
            tooltip: 'Contact settings',
            onPressed: () => context.push('/contacts/settings'),
            icon: const Icon(DocmacIconlyLight.setting, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ValueListenableBuilder<ConnectionsState>(
        valueListenable: controller,
        builder: (context, connections, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              DocmacSearchBar(
                fieldKey: const ValueKey('connections-search'),
                controller: _searchController,
                height: 46,
                hintText: _tab == ConnectionTab.followers
                    ? 'Search connections'
                    : 'Search contacts or numbers',
                semanticsLabel: _tab == ConnectionTab.followers
                    ? 'Search connections'
                    : 'Search contacts',
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 14),
              _CircleTabs(
                selected: _tab,
                followerCount: connections.followerCount,
                contactCount: connections.contactCount,
                onSelected: _selectTab,
              ),
              const SizedBox(height: 8),
              _QuietNote(tab: _tab, connections: connections),
              const SizedBox(height: 15),
              if (_tab == ConnectionTab.followers)
                _FollowersBody(
                  state: this,
                  connections: connections,
                  controller: controller,
                )
              else
                _ContactsBody(
                  state: this,
                  connections: connections,
                  controller: controller,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A low, two-part control. The selected side is a plain sheet of paper,
/// not a blue slab, so the page keeps its calm.
class _CircleTabs extends StatelessWidget {
  const _CircleTabs({
    required this.selected,
    required this.followerCount,
    required this.contactCount,
    required this.onSelected,
  });

  final ConnectionTab selected;
  final int followerCount;
  final int contactCount;
  final ValueChanged<ConnectionTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CircleSegment(
              key: const ValueKey('connections-tab-followers'),
              selected: selected == ConnectionTab.followers,
              icon: DocmacIconlyLight.user,
              label: 'Connections',
              count: followerCount,
              onTap: () => onSelected(ConnectionTab.followers),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _CircleSegment(
              key: const ValueKey('connections-tab-contacts'),
              selected: selected == ConnectionTab.contacts,
              icon: DocmacIconlyLight.user1,
              label: 'Contacts',
              count: contactCount,
              onTap: () => onSelected(ConnectionTab.contacts),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleSegment extends StatelessWidget {
  const _CircleSegment({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      child: Material(
        color: selected ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? scheme.onSurfaceVariant
                      : scheme.onSurfaceVariant.withValues(alpha: .7),
                  fontSize: 10.5,
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

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.tab, required this.connections});

  final ConnectionTab tab;
  final ConnectionsState connections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isContacts = tab == ConnectionTab.contacts;
    final text = isContacts
        ? '${connections.onDocmacContactCount} of ${connections.contactCount} '
            'can receive a Talk today.'
        : 'Connections stay social. Talk opens only for saved contacts.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(
            DocmacIconlyLight.infoCircle,
            size: 13,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowersBody extends StatelessWidget {
  const _FollowersBody({
    required this.state,
    required this.connections,
    required this.controller,
  });

  final _ConnectionsPageState state;
  final ConnectionsState connections;
  final ConnectionsController controller;

  @override
  Widget build(BuildContext context) {
    final requests = state._matching(connections.requests);
    final followers = state._matching(connections.followers);
    final following = state._matching(connections.following);
    final searching = state._query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connections.requestCount > 0 &&
            state._filter != FollowerFilter.requests) ...[
          _RequestStrip(
            count: connections.requestCount,
            onTap: () => state._selectFilter(FollowerFilter.requests),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                key: const ValueKey('connections-filter-followers'),
                label: 'Connections',
                count: connections.followerCount,
                selected: state._filter == FollowerFilter.followers,
                onTap: () => state._selectFilter(FollowerFilter.followers),
              ),
              const SizedBox(width: 7),
              _FilterChip(
                key: const ValueKey('connections-filter-following'),
                label: 'Links',
                count: connections.followingCount,
                selected: state._filter == FollowerFilter.following,
                onTap: () => state._selectFilter(FollowerFilter.following),
              ),
              const SizedBox(width: 7),
              _FilterChip(
                key: const ValueKey('connections-filter-requests'),
                label: 'Requests',
                count: connections.requestCount,
                selected: state._filter == FollowerFilter.requests,
                onTap: () => state._selectFilter(FollowerFilter.requests),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state._filter == FollowerFilter.requests)
          _RequestsSection(
            state: state,
            controller: controller,
            requests: requests,
            total: connections.requestCount,
            searching: searching,
          )
        else if (state._filter == FollowerFilter.following)
          _PeopleSection(
            title: 'People you link with',
            subtitle: 'Their public moments show up in your feed.',
            emptyLabel: searching
                ? 'No one you link with matches that search.'
                : 'You have not linked with anyone yet.',
            people: following,
            controller: controller,
            state: state,
          )
        else
          _PeopleSection(
            title: 'Linked to you',
            subtitle: 'Social only. Talk needs a saved contact.',
            emptyLabel: searching
                ? 'No connection matches that search.'
                : 'No connections yet. Share your profile to get started.',
            people: followers,
            controller: controller,
            state: state,
          ),
      ],
    );
  }
}

class _RequestStrip extends StatelessWidget {
  const _RequestStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  DocmacIconlyLight.addUser,
                  size: 16,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 person asked to link with you'
                      : '$count people asked to link with you',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.1,
                  ),
                ),
              ),
              Text(
                'Review',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                DocmacIconlyLight.arrowRight,
                size: 13,
                color: scheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.state,
    required this.controller,
    required this.requests,
    required this.total,
    required this.searching,
  });

  final _ConnectionsPageState state;
  final ConnectionsController controller;
  final List<ConnectionProfile> requests;
  final int total;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Waiting on you',
          subtitle: 'Accept to link with each other.',
          trailing: '$total',
        ),
        const SizedBox(height: 9),
        if (requests.isEmpty)
          _EmptyCard(
            icon: DocmacIconlyLight.tickSquare,
            title: searching ? 'No request matches' : 'All caught up',
            message: searching
                ? 'Try another name or username.'
                : 'There are no link requests waiting right now.',
          )
        else
          _GroupCard(
            children: [
              for (final person in requests)
                _RequestTile(
                  person: person,
                  onAccept: () {
                    HapticFeedback.selectionClick();
                    controller.acceptRequest(person.id);
                    state._notify(
                      'You and ${person.shortName} are now linked.',
                    );
                  },
                  onIgnore: () {
                    HapticFeedback.selectionClick();
                    controller.ignoreRequest(person.id);
                    state._notify('Request from ${person.shortName} ignored.');
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection({
    required this.title,
    required this.subtitle,
    required this.emptyLabel,
    required this.people,
    required this.controller,
    required this.state,
  });

  final String title;
  final String subtitle;
  final String emptyLabel;
  final List<ConnectionProfile> people;
  final ConnectionsController controller;
  final _ConnectionsPageState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: title,
          subtitle: subtitle,
          trailing: '${people.length}',
        ),
        const SizedBox(height: 9),
        if (people.isEmpty)
          _EmptyCard(
            icon: DocmacIconlyLight.user1,
            title: 'Nothing here yet',
            message: emptyLabel,
          )
        else
          _GroupCard(
            children: [
              for (final person in people)
                _FollowerTile(
                  person: person,
                  following: person.youFollow,
                  onFollow: () {
                    HapticFeedback.selectionClick();
                    controller.toggleFollow(person);
                  },
                  onChat: person.isContact
                      ? () => context.push('/talk/person/${person.id}')
                      : null,
                ),
            ],
          ),
      ],
    );
  }
}

class _FollowerTile extends StatelessWidget {
  const _FollowerTile({
    required this.person,
    required this.following,
    required this.onFollow,
    this.onChat,
  });

  final ConnectionProfile person;
  final bool following;
  final VoidCallback onFollow;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/person/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ConnectionAvatar(
              initials: person.initials,
              tint: person.tint,
              isOnline: person.isOnline,
              size: 42,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      if (person.isContact) ...[
                        const SizedBox(width: 5),
                        const _MiniBadge(label: 'In contacts'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${person.username} · ${person.detail}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (onChat != null)
              IconButton(
                key: ValueKey('follower-chat-${person.id}'),
                tooltip: 'Talk to ${person.shortName}',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                onPressed: onChat,
                icon: Icon(
                  DocmacIconlyLight.chat,
                  size: 17,
                  color: scheme.onSurface,
                ),
              ),
            if (following)
              Tooltip(
                message: 'Linked. Tap to unlink.',
                child: IconButton(
                  key: ValueKey('follower-follow-${person.id}'),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: onFollow,
                  icon: Container(
                    width: 29,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      DocmacIconlyLight.tickSquare,
                      size: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              )
            else
              FilledButton(
                key: ValueKey('follower-follow-${person.id}'),
                onPressed: onFollow,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Link'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.person,
    required this.onAccept,
    required this.onIgnore,
  });

  final ConnectionProfile person;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/person/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectionAvatar(
              initials: person.initials,
              tint: person.tint,
              isOnline: person.isOnline,
              size: 42,
              showRing: true,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      if (person.isContact) ...[
                        const SizedBox(width: 5),
                        const _MiniBadge(label: 'Contact'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${person.username} · ${person.detail}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(
                        key: ValueKey('accept-request-${person.id}'),
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 31),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 7),
                      OutlinedButton(
                        key: ValueKey('ignore-request-${person.id}'),
                        onPressed: onIgnore,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 31),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: scheme.onSurfaceVariant,
                          side: BorderSide(color: scheme.outlineVariant),
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Ignore'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsBody extends StatelessWidget {
  const _ContactsBody({
    required this.state,
    required this.connections,
    required this.controller,
  });

  final _ConnectionsPageState state;
  final ConnectionsState connections;
  final ConnectionsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onDocmac = state._matchingContacts(connections.onDocmacContacts);
    final invites = state._matchingContacts(connections.inviteContacts);
    final searching = state._query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your address book',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
            ),
            Text(
              '${connections.contactCount} saved',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/contacts/new'),
                icon: const Icon(DocmacIconlyLight.addUser, size: 16),
                label: const Text('Add contact'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/people/invite'),
                icon: const Icon(DocmacIconlyLight.paperPlus, size: 15),
                label: const Text('Import'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: scheme.onSurfaceVariant,
                  side: BorderSide(color: scheme.outlineVariant),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionHeading(
          title: 'On Docmac',
          subtitle: 'Tap Talk to open a private conversation.',
          trailing: '${onDocmac.length}',
        ),
        const SizedBox(height: 9),
        if (onDocmac.isEmpty)
          _EmptyCard(
            icon: DocmacIconlyLight.chat,
            title: searching ? 'No contact matches' : 'No chat-ready contacts',
            message: searching
                ? 'Try another name, username or phone number.'
                : 'Import or add a contact who already uses Docmac.',
          )
        else
          _GroupCard(
            children: [
              for (final contact in onDocmac)
                _ContactTile(
                  contact: contact,
                  onTalk: () => context
                      .push('/talk/person/${contact.username ?? contact.id}'),
                ),
            ],
          ),
        const SizedBox(height: 20),
        _SectionHeading(
          title: 'Not on Docmac yet',
          subtitle: 'Invite them. They join this list once they accept.',
          trailing: '${invites.length}',
        ),
        const SizedBox(height: 9),
        if (invites.isEmpty)
          _EmptyCard(
            icon: DocmacIconlyLight.tickSquare,
            title: searching ? 'No contact matches' : 'Everyone is here',
            message: searching
                ? 'Try another name, username or phone number.'
                : 'All of your saved contacts are already on Docmac.',
          )
        else
          _GroupCard(
            children: [
              for (final contact in invites)
                _ContactTile(
                  contact: contact,
                  onInvite: () {
                    HapticFeedback.selectionClick();
                    controller.inviteContact(contact.id);
                    state._notify(
                      'Invite ready for ${contact.shortName}. Share it when you are.',
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    this.onTalk,
    this.onInvite,
  });

  final ContactProfile contact;
  final VoidCallback? onTalk;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTalk ?? onInvite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ConnectionAvatar(
              initials: contact.initials,
              tint: contact.tint,
              isOnline: contact.isOnline,
              size: 42,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (contact.isOnDocmac && contact.username != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      '@${contact.username} · ${contact.note ?? 'On Docmac'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                  ] else if (contact.note != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      contact.note!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (onTalk != null)
              OutlinedButton.icon(
                key: ValueKey('contact-talk-${contact.id}'),
                onPressed: onTalk,
                icon: const Icon(DocmacIconlyLight.chat, size: 14),
                label: const Text('Talk'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 31),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              OutlinedButton(
                key: ValueKey('contact-invite-${contact.id}'),
                onPressed: contact.invited ? null : onInvite,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 31),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: scheme.onSurfaceVariant,
                  side: BorderSide(color: scheme.outlineVariant),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(contact.invited ? 'Invited' : 'Invite'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.surface : scheme.onSurface;

    return Material(
      color: selected ? scheme.onSurface : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.onSurface : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? scheme.surface.withValues(alpha: .72)
                      : scheme.onSurfaceVariant,
                  fontSize: 10,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            trailing,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                indent: 65,
                color: scheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DocmacIconlyLight.tickSquare,
            size: 9,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: 18),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
