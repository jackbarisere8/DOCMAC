import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// A Circle is Docmac's name for a private group conversation.
class CircleCreatePage extends StatefulWidget {
  const CircleCreatePage({super.key});

  @override
  State<CircleCreatePage> createState() => _CircleCreatePageState();
}

class _CircleCreatePageState extends State<CircleCreatePage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _members = <String>[];
  String _disappearing = '24 hours';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Circle')),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Create Circle',
          onPressed: _name.text.trim().isEmpty ? null : _create,
          child: const Icon(DocmacIconlyLight.tickSquare),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            Row(
              children: [
                const _CircleAvatar(size: 62, showCamera: true),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter Circle name',
                      suffixIcon: Icon(Icons.emoji_emotions_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _description,
              maxLength: 2048,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Circle description (optional)',
                alignLabelWithHint: true,
                hintText:
                    'Describe what your Circle is about and who it is for.',
              ),
            ),
            const Divider(height: 38),
            _MenuRow(
              icon: DocmacIconlyLight.activity,
              title: 'Disappearing messages',
              subtitle: _disappearing,
              onTap: () => _pickOption(
                'Disappearing messages',
                const ['Off', '24 hours', '7 days', '90 days'],
                _disappearing,
                (value) => setState(() => _disappearing = value),
              ),
            ),
            _MenuRow(
              icon: DocmacIconlyLight.lock,
              title: 'Private Circle',
              subtitle: 'People join only by invitation or invite link.',
              onTap: () {},
            ),
            _MenuRow(
              icon: DocmacIconlyLight.setting,
              title: 'Circle permissions',
              onTap: () => context.push('/circle/permissions'),
            ),
            const Divider(height: 38),
            Text('Members: ${_members.isEmpty ? 'None' : _members.length}'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addMembers,
              icon: const Icon(DocmacIconlyLight.addUser),
              label: const Text('Add members'),
            ),
          ],
        ),
      );

  Future<void> _addMembers() async {
    final selected = await showCircleMemberPicker(context, initial: _members);
    if (selected != null) {
      setState(() {
        _members
          ..clear()
          ..addAll(selected);
      });
    }
  }

  void _pickOption(String title, List<String> options, String selected,
      ValueChanged<String> onSelected) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                if (value == null) return;
                onSelected(value);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  for (final option in options)
                    RadioListTile<String>(
                      value: option,
                      title: Text(option),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _create() {
    CircleTalkStore.create(
      name: _name.text.trim(),
      description: _description.text.trim(),
      members: _members,
      disappearing: _disappearing,
      visibility: 'Private',
    );
    context.go('/circle');
  }
}

class CircleTalkPage extends StatefulWidget {
  const CircleTalkPage({super.key});

  @override
  State<CircleTalkPage> createState() => _CircleTalkPageState();
}

class _CircleTalkPageState extends State<CircleTalkPage> {
  final _composer = TextEditingController();
  final _messages = <String>[
    'Welcome to the Circle. Use this space to share plans and stay connected.',
    'Glad to be here!',
  ];

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circle = CircleTalkStore.current;
    if (circle == null) return const CircleCreatePage();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Talk',
          onPressed: () => context.go('/talk'),
          icon: const Icon(DocmacIconlyLight.arrowLeft),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => context.push('/circle/info'),
          child: Row(
            children: [
              const _CircleAvatar(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, overflow: TextOverflow.ellipsis),
                    Text('${circle.memberCount} members',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Start Circle call',
            onPressed: () => _showCallOptions(context),
            icon: const Icon(DocmacIconlyLight.call),
          ),
          PopupMenuButton<String>(
            tooltip: 'Circle options',
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'members', child: Text('Add members')),
              PopupMenuItem(value: 'info', child: Text('Circle info')),
              PopupMenuItem(value: 'media', child: Text('Circle media')),
              PopupMenuItem(value: 'search', child: Text('Search messages')),
              PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
              PopupMenuItem(
                  value: 'disappearing', child: Text('Disappearing messages')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'more', child: Text('More options')),
            ],
            icon: const Icon(DocmacIconlyLight.moreCircle),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              children: [
                const Center(child: _StatusChip(text: 'Private Circle')),
                const SizedBox(height: 18),
                for (var index = 0; index < _messages.length; index++)
                  Align(
                    alignment: index.isEven
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? colors.surfaceContainerHighest
                            : colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(
                          color: index.isEven
                              ? colors.onSurface
                              : colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    onPressed: () {},
                    icon: const Icon(DocmacIconlyLight.plus),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _send,
                    icon: const Icon(DocmacIconlyLight.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final value = _composer.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(value);
      _composer.clear();
    });
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'members':
        context.push('/circle/members/add');
        return;
      case 'info':
      case 'media':
        context.push('/circle/info');
        return;
      case 'search':
        showSearch<void>(
            context: context, delegate: _CircleSearchDelegate(_messages));
        return;
      case 'disappearing':
        context.push('/circle/info?tab=settings');
        return;
      case 'mute':
      case 'more':
        _showMoreOptions();
        return;
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
                leading: Icon(DocmacIconlyLight.volumeOff),
                title: Text('Mute Circle')),
            ListTile(
              leading: const Icon(DocmacIconlyLight.delete),
              title: const Text('Clear chat'),
              onTap: () {
                setState(_messages.clear);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(DocmacIconlyLight.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Leave Circle',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                showCircleLeaveDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CircleConversationInfoPage extends StatefulWidget {
  const CircleConversationInfoPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CircleConversationInfoPage> createState() =>
      _CircleConversationInfoPageState();
}

class _CircleConversationInfoPageState
    extends State<CircleConversationInfoPage> {
  late int _tab = widget.initialTab;
  bool _chatLock = false;

  @override
  Widget build(BuildContext context) {
    final circle = CircleTalkStore.current;
    if (circle == null) return const CircleCreatePage();
    return Scaffold(
      appBar: AppBar(
        title: Text(circle.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Circle management',
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/circle/edit');
              }
              if (value == 'members') {
                context.push('/circle/members/add');
              }
              if (value == 'export') {
                _notice('Circle export is being prepared.');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'members', child: Text('Add members')),
              PopupMenuItem(value: 'edit', child: Text('Edit Circle')),
              PopupMenuItem(value: 'export', child: Text('Export chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
            child: Row(
              children: [
                const _CircleAvatar(size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(circle.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('${circle.memberCount} members · Private'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Members')),
              ButtonSegment(value: 1, label: Text('Media')),
              ButtonSegment(value: 2, label: Text('Settings')),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_tab) {
              0 => _members(circle),
              1 => _media(),
              _ => _settings(circle),
            },
          ),
        ],
      ),
    );
  }

  Widget _members(CircleTalk circle) => ListView(
        children: [
          _InfoRow(
            icon: DocmacIconlyLight.addUser,
            title: 'Add members',
            emphasis: true,
            onTap: () => context.push('/circle/members/add'),
          ),
          _InfoRow(
              icon: DocmacIconlyLight.profile,
              title: 'Add members to People',
              onTap: () => _notice('Member contacts are ready to save.')),
          const Divider(),
          for (final member in circle.members)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: CircleAvatar(child: Text(member.substring(0, 1))),
              title: Text(member),
              subtitle: Text(member == 'You' ? 'Circle owner' : 'Member'),
              trailing:
                  member == 'You' ? const Chip(label: Text('Owner')) : null,
            ),
        ],
      );

  Widget _media() => Center(
        child: Text('Media, links and docs will appear here.',
            style: Theme.of(context).textTheme.bodyMedium),
      );

  Widget _settings(CircleTalk circle) => ListView(
        children: [
          _InfoRow(
              icon: DocmacIconlyLight.folder,
              title: 'Manage storage',
              subtitle: 'No media stored',
              onTap: () {}),
          _InfoRow(
              icon: DocmacIconlyLight.notification,
              title: 'Notifications',
              subtitle: 'All',
              onTap: () {}),
          _InfoRow(
              icon: DocmacIconlyLight.image,
              title: 'Media visibility',
              onTap: () {}),
          const Divider(),
          _InfoRow(
              icon: DocmacIconlyLight.lock,
              title: 'Encryption',
              subtitle: 'Messages and calls are end-to-end encrypted.',
              onTap: () {}),
          _InfoRow(
              icon: DocmacIconlyLight.activity,
              title: 'Disappearing messages',
              subtitle: circle.disappearing,
              onTap: () {}),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            secondary: const Icon(DocmacIconlyLight.lock),
            title: const Text('Chat lock'),
            subtitle: const Text('Lock and hide this chat on this device.'),
            value: _chatLock,
            onChanged: (value) => setState(() => _chatLock = value),
          ),
          _InfoRow(
              icon: DocmacIconlyLight.shieldDone,
              title: 'Advanced chat privacy',
              subtitle: 'Off',
              onTap: () {}),
          _InfoRow(
              icon: DocmacIconlyLight.document,
              title: 'Transcripts',
              subtitle: 'English',
              onTap: () {}),
          const Divider(),
          _InfoRow(
            icon: DocmacIconlyLight.addUser,
            title: 'Create a similar Circle',
            subtitle: 'Start with the same members.',
            emphasis: true,
            onTap: () => context.push('/circle/new'),
          ),
          _InfoRow(
              icon: DocmacIconlyLight.heart,
              title: 'Add to favourites',
              onTap: () {}),
          _InfoRow(
              icon: DocmacIconlyLight.document,
              title: 'Export chat',
              onTap: () {}),
          _InfoRow(
            icon: DocmacIconlyLight.logout,
            title: 'Leave Circle',
            destructive: true,
            onTap: () => showCircleLeaveDialog(context),
          ),
          _InfoRow(
              icon: DocmacIconlyLight.danger,
              title: 'Report Circle',
              destructive: true,
              onTap: () {}),
        ],
      );

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class CircleAddMembersPage extends StatefulWidget {
  const CircleAddMembersPage({super.key});

  @override
  State<CircleAddMembersPage> createState() => _CircleAddMembersPageState();
}

class _CircleAddMembersPageState extends State<CircleAddMembersPage> {
  final _selected = <String>[];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final people = circlePeople
        .where((person) => person.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add members')),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _add,
              child: const Icon(DocmacIconlyLight.arrowRight),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search people',
              prefixIcon: Icon(DocmacIconlyLight.search),
            ),
          ),
          _InfoRow(
            icon: DocmacIconlyLight.send,
            title: 'Invite to Circle via link',
            emphasis: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Circle invite link copied.')),
            ),
          ),
          for (final person in people)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              secondary: CircleAvatar(child: Text(person.substring(0, 1))),
              title: Text(person),
              subtitle: const Text('Available on Docmac'),
              value: _selected.contains(person),
              onChanged: (_) => setState(() => _selected.contains(person)
                  ? _selected.remove(person)
                  : _selected.add(person)),
            ),
        ],
      ),
    );
  }

  void _add() {
    CircleTalkStore.current?.addMembers(_selected);
    context.pop();
  }
}

class CircleEditPage extends StatefulWidget {
  const CircleEditPage({super.key});

  @override
  State<CircleEditPage> createState() => _CircleEditPageState();
}

class _CircleEditPageState extends State<CircleEditPage> {
  late final _name = TextEditingController(text: CircleTalkStore.current?.name);
  late final _description =
      TextEditingController(text: CircleTalkStore.current?.description);
  bool _topics = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Circle'),
          actions: [
            IconButton(
              tooltip: 'Save Circle',
              onPressed: _save,
              icon: const Icon(DocmacIconlyLight.tickSquare),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(children: [
                      const _CircleAvatar(size: 66, showCamera: true),
                      const SizedBox(width: 16),
                      Expanded(
                          child: TextField(
                              controller: _name,
                              decoration: const InputDecoration(
                                  labelText: 'Circle name'))),
                    ]),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Column(children: [
                _InfoRow(
                    icon: DocmacIconlyLight.user,
                    title: 'Circle type',
                    subtitle: CircleTalkStore.current?.visibility,
                    onTap: () => context.push('/circle/access')),
                _InfoRow(
                    icon: DocmacIconlyLight.message,
                    title: 'Chat history',
                    subtitle: 'Visible',
                    onTap: () => context.push('/circle/access')),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  secondary: const Icon(DocmacIconlyLight.category),
                  title: const Text('Topics'),
                  subtitle: const Text('Create focused conversations.'),
                  value: _topics,
                  onChanged: (value) => setState(() => _topics = value),
                ),
              ]),
            ),
            Card(
              child: Column(children: [
                _InfoRow(
                    icon: DocmacIconlyLight.heart,
                    title: 'Reactions',
                    subtitle: 'All',
                    onTap: () => context.push('/circle/reactions')),
                _InfoRow(
                    icon: DocmacIconlyLight.ticketStar,
                    title: 'Permissions',
                    subtitle: 'Custom',
                    onTap: () => context.push('/circle/permissions')),
                _InfoRow(
                    icon: DocmacIconlyLight.send,
                    title: 'Invite links',
                    subtitle: '1 active link',
                    onTap: () => context.push('/circle/access')),
                _InfoRow(
                    icon: DocmacIconlyLight.shieldDone,
                    title: 'Administrators',
                    subtitle: '1',
                    onTap: () => showCircleAdmins(context)),
              ]),
            ),
            TextButton(
              onPressed: () => showCircleLeaveDialog(context),
              child: const Text('Delete and leave Circle'),
            ),
          ],
        ),
      );

  void _save() {
    final circle = CircleTalkStore.current;
    if (circle != null && _name.text.trim().isNotEmpty) {
      circle.name = _name.text.trim();
      circle.description = _description.text.trim();
    }
    context.pop();
  }
}

class CirclePermissionsPage extends StatefulWidget {
  const CirclePermissionsPage({super.key});
  @override
  State<CirclePermissionsPage> createState() => _CirclePermissionsPageState();
}

class _CirclePermissionsPageState extends State<CirclePermissionsPage> {
  final _items = <String, bool>{
    'Send messages': true,
    'Send media': true,
    'Add people': true,
    'Pin messages': true,
    'Edit own tags': false,
    'Change Circle info': true,
  };
  double _slowMode = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Circle permissions')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('What can members of this Circle do?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: _items.entries
                    .map((item) => SwitchListTile(
                          title: Text(item.key),
                          value: item.value,
                          onChanged: (value) =>
                              setState(() => _items[item.key] = value),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            Text('Slow mode', style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: _slowMode,
              min: 0,
              max: 60,
              divisions: 6,
              label: _slowMode == 0 ? 'Off' : '${_slowMode.round()} sec',
              onChanged: (value) => setState(() => _slowMode = value),
            ),
            Text(_slowMode == 0
                ? 'Members can reply freely.'
                : 'Members wait ${_slowMode.round()} seconds between messages.'),
          ],
        ),
      );
}

class CircleReactionsPage extends StatefulWidget {
  const CircleReactionsPage({super.key});
  @override
  State<CircleReactionsPage> createState() => _CircleReactionsPageState();
}

class _CircleReactionsPageState extends State<CircleReactionsPage> {
  String _selection = 'All reactions';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reactions')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available reactions',
                  style: Theme.of(context).textTheme.titleLarge),
              Card(
                child: RadioGroup<String>(
                  groupValue: _selection,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selection = value);
                    }
                  },
                  child: Column(
                    children:
                        ['All reactions', 'Some reactions', 'No reactions']
                            .map((option) => RadioListTile<String>(
                                  value: option,
                                  title: Text(option),
                                ))
                            .toList(),
                  ),
                ),
              ),
              const Text(
                  'Members can use the reactions you allow on Circle messages.'),
            ],
          ),
        ),
      );
}

class CircleAccessPage extends StatefulWidget {
  const CircleAccessPage({super.key});
  @override
  State<CircleAccessPage> createState() => _CircleAccessPageState();
}

class _CircleAccessPageState extends State<CircleAccessPage> {
  bool _protectContent = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Circle settings')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Circle privacy',
                style: Theme.of(context).textTheme.titleLarge),
            const Card(
              child: ListTile(
                leading: Icon(DocmacIconlyLight.lock),
                title: Text('Private Circle'),
                subtitle: Text('Members join by invitation or an invite link.'),
              ),
            ),
            Text('Invite link', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: const Text('docmac.app/circle/invite'),
                trailing: IconButton(
                  tooltip: 'Copy invite link',
                  icon: const Icon(DocmacIconlyLight.document),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied.')),
                  ),
                ),
              ),
            ),
            Card(
              child: SwitchListTile(
                title: const Text('Restrict saving content'),
                subtitle: const Text(
                    'Members cannot save or forward Circle content.'),
                value: _protectContent,
                onChanged: (value) => setState(() => _protectContent = value),
              ),
            ),
          ],
        ),
      );
}

class CircleTalkStore {
  CircleTalkStore._();

  static CircleTalk? current;

  static void create({
    required String name,
    required String description,
    required List<String> members,
    required String disappearing,
    required String visibility,
  }) {
    current = CircleTalk(
      name: name,
      description: description,
      members: ['You', ...members],
      disappearing: disappearing,
      visibility: visibility,
    );
  }
}

class CircleTalk {
  CircleTalk({
    required this.name,
    required this.description,
    required this.members,
    required this.disappearing,
    required this.visibility,
  });

  String name;
  String description;
  final List<String> members;
  final String disappearing;
  final String visibility;

  int get memberCount => members.length;

  void addMembers(Iterable<String> added) {
    for (final member in added) {
      if (!members.contains(member)) members.add(member);
    }
  }
}

const circlePeople = [
  'Amara Okafor',
  'David Mensah',
  'Nora Williams',
  'Tobi Adeyemi',
  'Emma Clarke',
  'Jack Wilson',
];

Future<List<String>?> showCircleMemberPicker(BuildContext context,
    {required List<String> initial}) {
  final picked = [...initial];
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SizedBox(
          height: 520,
          child: Column(
            children: [
              const ListTile(title: Text('Add members')),
              Expanded(
                child: ListView(
                  children: [
                    for (final person in circlePeople)
                      CheckboxListTile(
                        title: Text(person),
                        value: picked.contains(person),
                        onChanged: (_) => setSheetState(() =>
                            picked.contains(person)
                                ? picked.remove(person)
                                : picked.add(person)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, picked),
                    child: const Text('Done'),
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

class _CircleAvatar extends StatelessWidget {
  const _CircleAvatar({required this.size, this.showCamera = false});

  final double size;
  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          child: Icon(DocmacIconlyLight.addUser, size: size * .47),
        ),
        if (showCamera)
          Positioned(
            right: -3,
            bottom: -3,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: const Icon(DocmacIconlyLight.camera, size: 15),
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.emphasis = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool emphasis;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive
        ? colors.error
        : emphasis
            ? colors.primary
            : colors.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text),
      );
}

void _showCallOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: Icon(DocmacIconlyLight.call), title: Text('Voice call')),
          ListTile(
              leading: Icon(DocmacIconlyLight.video),
              title: Text('Video call')),
          ListTile(
              leading: Icon(DocmacIconlyLight.addUser),
              title: Text('Select people')),
          ListTile(
              leading: Icon(DocmacIconlyLight.send),
              title: Text('Send call link')),
        ],
      ),
    ),
  );
}

void showCircleAdmins(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Circle admins')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            ListTile(
                leading: Icon(DocmacIconlyLight.shieldDone),
                title: Text('Add admin')),
            ListTile(
                leading: CircleAvatar(child: Text('Y')),
                title: Text('You'),
                subtitle: Text('Owner')),
          ],
        ),
      ),
    ),
  );
}

void showCircleLeaveDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave Circle?'),
      content: const Text('You will stop receiving messages from this Circle.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            CircleTalkStore.current = null;
            context.go('/talk');
          },
          child: const Text('Leave'),
        ),
      ],
    ),
  );
}

class _CircleSearchDelegate extends SearchDelegate<void> {
  _CircleSearchDelegate(this.messages)
      : super(searchFieldLabel: 'Search Circle');

  final List<String> messages;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(DocmacIconlyLight.arrowLeft),
      );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    final matches = messages
        .where((message) => message.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView(children: [
      for (final message in matches) ListTile(title: Text(message))
    ]);
  }
}
