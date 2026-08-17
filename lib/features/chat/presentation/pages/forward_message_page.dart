import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForwardMessagePage extends StatefulWidget {
  const ForwardMessagePage({super.key});

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  final _noteController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _selected = <String>{};
  String _query = '';

  static const _talks = [
    ('My Orbit status', 'Share with your circles', Icons.bolt_rounded),
    ('Weekend crew', 'Nora, David, Amara', Icons.groups_rounded),
    ('Jack Wilson', 'Active now', Icons.person_rounded),
    ('Design circle', '4 members', Icons.palette_outlined),
    ('Nora Williams', 'Available', Icons.person_rounded),
    ('Tobi Adeyemi', 'Available', Icons.person_rounded),
    ('Emma Clarke', 'Sent you a new moment', Icons.person_rounded),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final talks = _talks
        .where((talk) => talk.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward to…'),
        actions: [
          IconButton(
              tooltip: 'New circle',
              onPressed: () => context.push('/circle/new'),
              icon: const Icon(Icons.group_add_outlined)),
          IconButton(
            tooltip: 'Search talks',
            onPressed: () => _searchFocusNode.requestFocus(),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search people and circles',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              children: [
                Text('Frequently contacted',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                for (final talk in talks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colors.primary.withValues(alpha: .7),
                      foregroundColor: colors.onPrimary,
                      child: Icon(talk.$3),
                    ),
                    title: Text(talk.$1),
                    subtitle: Text(talk.$2),
                    trailing: Checkbox(
                      shape: const CircleBorder(),
                      value: _selected.contains(talk.$1),
                      onChanged: (_) => setState(() {
                        _selected.contains(talk.$1)
                            ? _selected.remove(talk.$1)
                            : _selected.add(talk.$1);
                      }),
                    ),
                    onTap: () => setState(() {
                      _selected.contains(talk.$1)
                          ? _selected.remove(talk.$1)
                          : _selected.add(talk.$1);
                    }),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration:
                            const InputDecoration(hintText: 'Add a message…'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Forward message',
                      onPressed: _selected.isEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Forwarded to ${_selected.length} talk(s).')),
                              );
                              context.pop();
                            },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
