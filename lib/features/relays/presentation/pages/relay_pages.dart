import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Relays are Docmac's one-to-many publishing identities.
class RelaysPage extends StatelessWidget {
  const RelaysPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Relays'),
          actions: [
            IconButton(
              tooltip: 'Create Relay',
              onPressed: () => context.push('/relays/new'),
              icon: const Icon(DocmacIconlyLight.plus),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text('Tune in to voices worth returning to.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            _RelayCard(
                relay: RelayStore.current,
                onTap: () => context.push('/relays/home')),
            const SizedBox(height: 20),
            Text('Suggested Relays',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const _SuggestedRelay('Design Notes', '@designnotes',
                'Creative process, clearly shared.'),
            const _SuggestedRelay('Local Lens', '@locallens',
                'Small stories from close to home.'),
          ],
        ),
      );
}

class RelayCreatePage extends StatefulWidget {
  const RelayCreatePage({super.key});

  @override
  State<RelayCreatePage> createState() => _RelayCreatePageState();
}

class _RelayCreatePageState extends State<RelayCreatePage> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Technology';
  RelayVisibility _visibility = RelayVisibility.public;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Relay')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Center(child: _RelayAvatar(size: 92, editable: true)),
            const SizedBox(height: 26),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Relay name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _handle,
              maxLength: 32,
              decoration: const InputDecoration(
                labelText: 'Relay username',
                prefixText: '@',
                hintText: 'yourrelay',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                hintText: 'What should people tune in for?',
              ),
            ),
            const SizedBox(height: 8),
            _SelectRow(
              icon: DocmacIconlyLight.category,
              title: 'Category',
              value: _category,
              onTap: _pickCategory,
            ),
            _SelectRow(
              icon: _visibility == RelayVisibility.public
                  ? DocmacIconlyLight.show
                  : Icons.link_rounded,
              title: 'Visibility',
              value: _visibility.label,
              onTap: _pickVisibility,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed:
                  _name.text.trim().isEmpty || _handle.text.trim().isEmpty
                      ? null
                      : _create,
              child: const Text('Create Relay'),
            ),
          ],
        ),
      );

  void _pickCategory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _category,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  for (final category in const [
                    'Technology',
                    'Culture',
                    'Education',
                    'Business',
                    'Community',
                  ])
                    RadioListTile<String>(
                      value: category,
                      title: Text(category),
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
    final handle = _handle.text.trim().toLowerCase().replaceFirst('@', '');
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use 3–20 lowercase letters, numbers, or underscores.'),
        ),
      );
      return;
    }
    RelayStore.current = Relay(
      name: _name.text.trim(),
      handle: handle,
      description: _description.text.trim(),
      category: _category,
      visibility: _visibility,
    );
    context.go('/relays/home');
  }

  void _pickVisibility() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<RelayVisibility>(
              groupValue: _visibility,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _visibility = value);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  for (final visibility in RelayVisibility.values)
                    RadioListTile<RelayVisibility>(
                      value: visibility,
                      title: Text(visibility.label),
                      subtitle: Text(visibility.description),
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

class RelayHomePage extends StatefulWidget {
  const RelayHomePage({super.key});

  @override
  State<RelayHomePage> createState() => _RelayHomePageState();
}

class _RelayHomePageState extends State<RelayHomePage> {
  int _tab = 0;
  bool _isTunedIn = false;

  @override
  Widget build(BuildContext context) {
    final relay = RelayStore.current;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(relay.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Relay options',
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'drop', child: Text('Create Drop')),
              PopupMenuItem(value: 'schedule', child: Text('Schedule Drop')),
              PopupMenuItem(value: 'analytics', child: Text('Relay analytics')),
              PopupMenuItem(
                  value: 'tunedIn', child: Text('Manage tuned-in people')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'share', child: Text('Share Relay')),
              PopupMenuItem(value: 'report', child: Text('Report Relay')),
            ],
            icon: const Icon(DocmacIconlyLight.moreCircle),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            child: Column(
              children: [
                const _RelayAvatar(size: 86),
                const SizedBox(height: 12),
                Text(relay.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 3),
                Text('@${relay.handle}',
                    style: TextStyle(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(relay.description, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('${relay.tunedInLabel} Tuned In · ${relay.category}'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _changeTuning(relay),
                  icon: Icon(_isTunedIn
                      ? DocmacIconlyLight.tickSquare
                      : DocmacIconlyLight.plus),
                  label: Text(_isTunedIn ? 'Tuned In' : 'Tune In'),
                ),
              ],
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Drops')),
              ButtonSegment(value: 1, label: Text('Media')),
              ButtonSegment(value: 2, label: Text('Live')),
              ButtonSegment(value: 3, label: Text('Tuned In')),
              ButtonSegment(value: 4, label: Text('About')),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(relay)),
        ],
      ),
    );
  }

  Widget _body(Relay relay) => switch (_tab) {
        0 => ListView(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            children: [
              for (final drop in relay.drops)
                _DropCard(
                  drop: drop,
                  onOpenForge: () => context.push('/forge'),
                  onOpenReplies: () => _showReplies(drop),
                ),
              if (relay.drops.isEmpty)
                const _RelayEmpty(
                    icon: DocmacIconlyLight.document,
                    title: 'No Drops yet',
                    detail: 'The first Drop will appear here.'),
            ],
          ),
        1 => const _RelayEmpty(
            icon: DocmacIconlyLight.image,
            title: 'No media yet',
            detail: 'Photos, videos and files from Drops will appear here.'),
        2 => const _RelayEmpty(
            icon: DocmacIconlyLight.voice,
            title: 'No Relay Live right now',
            detail: 'Live sessions published by this Relay will appear here.'),
        3 => _TunedInList(relay: relay),
        _ => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _AboutRow('Created', 'August 2026'),
              _AboutRow('Visibility', relay.visibility.label),
              _AboutRow('Category', relay.category),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(DocmacIconlyLight.send),
                label: const Text('Share Relay'),
              ),
            ],
          ),
      };

  void _handleMenu(String value) {
    switch (value) {
      case 'drop':
        context.push('/relays/drop');
        return;
      case 'analytics':
        context.push('/relays/analytics');
        return;
      case 'schedule':
        _notice('Scheduling is ready for your next Drop.');
        return;
      case 'tunedIn':
        _notice('Tuned-in people management will open here.');
        return;
      case 'share':
        _notice('Relay link copied.');
        return;
      case 'report':
        _notice('Report options will open here.');
        return;
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _changeTuning(Relay relay) async {
    if (!_isTunedIn) {
      setState(() {
        _isTunedIn = true;
        relay.tunedInCount += 1;
      });
      return;
    }

    final shouldStop = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stop receiving?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You will stop receiving new Drops from @${relay.handle}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Stop receiving'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep receiving'),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldStop != true || !mounted) return;
    setState(() {
      _isTunedIn = false;
      relay.tunedInCount -= 1;
    });
  }

  void _showReplies(RelayDrop drop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RepliesSheet(drop: drop),
    );
  }
}

class RelayDropPage extends StatefulWidget {
  const RelayDropPage({super.key});

  @override
  State<RelayDropPage> createState() => _RelayDropPageState();
}

class _RelayDropPageState extends State<RelayDropPage> {
  final _content = TextEditingController();
  bool _allowReplies = true;
  bool _forgePerspective = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Create Drop'),
          actions: [
            TextButton(onPressed: _publish, child: const Text('Publish')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _content,
              minLines: 8,
              maxLines: 14,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What do you want to publish?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(DocmacIconlyLight.image),
              label: const Text('Add media'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(DocmacIconlyLight.message),
              title: const Text('Allow replies'),
              subtitle:
                  const Text('Replies stay public and scoped to this Drop.'),
              value: _allowReplies,
              onChanged: (value) => setState(() => _allowReplies = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(DocmacIconlyLight.work),
              title: const Text('Open in Forge'),
              subtitle: const Text(
                  'Create a Perspective for a deliberate, structured debate.'),
              value: _forgePerspective,
              onChanged: (value) => setState(() => _forgePerspective = value),
            ),
          ],
        ),
      );

  void _publish() {
    final text = _content.text.trim();
    if (text.isEmpty) return;
    RelayStore.current.drops.insert(
      0,
      RelayDrop(
        text,
        allowReplies: _allowReplies,
        forgePerspective: _forgePerspective,
      ),
    );
    context.pop();
  }
}

class _TunedInList extends StatelessWidget {
  const _TunedInList({required this.relay});

  final Relay relay;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('${relay.tunedInLabel} Tuned In',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text("People who choose to receive this Relay's Drops.",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final tunedInPerson in const [
            ('Emma Clarke', 'emma', 'E'),
            ('David Mensah', 'davidm', 'D'),
            ('Amara Okafor', 'amara', 'A'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(tunedInPerson.$3)),
              title: Text(tunedInPerson.$1),
              subtitle: Text('@${tunedInPerson.$2}'),
            ),
        ],
      );
}

class _RepliesSheet extends StatefulWidget {
  const _RepliesSheet({required this.drop});

  final RelayDrop drop;

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Replies', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(widget.drop.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              if (widget.drop.replies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No replies yet. Start the conversation here.'),
                )
              else
                for (final reply in widget.drop.replies)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Text('Y')),
                    title: const Text('You'),
                    subtitle: Text(reply),
                  ),
              const SizedBox(height: 8),
              TextField(
                controller: _reply,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a public reply',
                  suffixIcon: IconButton(
                    tooltip: 'Post reply',
                    icon: const Icon(DocmacIconlyLight.send),
                    onPressed: _post,
                  ),
                ),
                onSubmitted: (_) => _post(),
              ),
            ],
          ),
        ),
      );

  void _post() {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.drop.replies.add(text);
      _reply.clear();
    });
  }
}

class RelayAnalyticsPage extends StatelessWidget {
  const RelayAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Relay analytics')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Audience and Drop performance',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            const Row(children: [
              Expanded(child: _Metric('12.4K', 'Tuned In')),
              SizedBox(width: 10),
              Expanded(child: _Metric('+8.2%', 'Growth')),
            ]),
            const SizedBox(height: 10),
            const Row(children: [
              Expanded(child: _Metric('8.9K', 'Drop reach')),
              SizedBox(width: 10),
              Expanded(child: _Metric('18%', 'Engagement')),
            ]),
            const SizedBox(height: 24),
            const _AnalyticsLine('Shares', '326'),
            const _AnalyticsLine('Responses', '84'),
            const _AnalyticsLine('Live viewers', '—'),
          ],
        ),
      );
}

class RelayStore {
  RelayStore._();

  static Relay current = Relay(
    name: 'Docmac News',
    handle: 'docmac',
    description:
        'Updates from the private place where your people are present.',
    category: 'Technology',
    visibility: RelayVisibility.public,
  )..drops.add(RelayDrop(
      'A calmer way to share, talk and stay close is taking shape.',
      allowReplies: true,
      forgePerspective: true,
    ));
}

class Relay {
  Relay({
    required this.name,
    required this.handle,
    required this.description,
    required this.category,
    required this.visibility,
  });
  final String name;
  final String handle;
  final String description;
  final String category;
  final RelayVisibility visibility;
  int tunedInCount = 12400;
  final List<RelayDrop> drops = [];

  String get tunedInLabel => tunedInCount >= 1000
      ? '${(tunedInCount / 1000).toStringAsFixed(1)}K'
      : tunedInCount.toString();
}

class RelayDrop {
  RelayDrop(
    this.text, {
    required this.allowReplies,
    required this.forgePerspective,
  });
  final String text;
  final bool allowReplies;
  final bool forgePerspective;
  final List<String> replies = [];
}

enum RelayVisibility {
  public('Public', 'Anyone can discover it and tune in.'),
  unlisted('Unlisted',
      'It is not shown in discovery; people tune in through its link.');

  const RelayVisibility(this.label, this.description);
  final String label;
  final String description;
}

class _RelayCard extends StatelessWidget {
  const _RelayCard({required this.relay, required this.onTap});
  final Relay relay;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: const _RelayAvatar(size: 48),
          title: Text(relay.name),
          subtitle: Text('@${relay.handle} · ${relay.tunedInLabel} Tuned In'),
          trailing: const Icon(DocmacIconlyLight.arrowRight),
        ),
      );
}

class _SuggestedRelay extends StatefulWidget {
  const _SuggestedRelay(this.name, this.handle, this.description);
  final String name;
  final String handle;
  final String description;

  @override
  State<_SuggestedRelay> createState() => _SuggestedRelayState();
}

class _SuggestedRelayState extends State<_SuggestedRelay> {
  bool _isTunedIn = false;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const _RelayAvatar(size: 44),
        title: Text(widget.name),
        subtitle: Text('${widget.handle} · ${widget.description}'),
        trailing: OutlinedButton(
          onPressed:
              _isTunedIn ? null : () => setState(() => _isTunedIn = true),
          child: Text(_isTunedIn ? 'Tuned In' : 'Tune In'),
        ),
      );
}

class _RelayAvatar extends StatelessWidget {
  const _RelayAvatar({required this.size, this.editable = false});
  final double size;
  final bool editable;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Center(
          child: Icon(
            DocmacIconlyLight.discovery,
            size: size * .45,
            color: scheme.onSurface,
          ),
        ),
        if (editable)
          Positioned(
            right: -2,
            bottom: -2,
            child: Icon(
              DocmacIconlyLight.camera,
              size: 18,
              color: scheme.primary,
            ),
          ),
      ]),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class _DropCard extends StatelessWidget {
  const _DropCard({
    required this.drop,
    required this.onOpenForge,
    required this.onOpenReplies,
  });
  final RelayDrop drop;
  final VoidCallback onOpenForge;
  final VoidCallback onOpenReplies;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(drop.text,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.4)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, children: [
              TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(DocmacIconlyLight.heart, size: 17),
                  label: const Text('482')),
              TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(DocmacIconlyLight.send, size: 17),
                  label: const Text('91')),
              if (drop.allowReplies)
                TextButton.icon(
                  onPressed: onOpenReplies,
                  icon: const Icon(DocmacIconlyLight.message, size: 17),
                  label: Text('${drop.replies.length} Replies'),
                ),
              if (drop.forgePerspective)
                TextButton(
                    onPressed: onOpenForge, child: const Text('Open in Forge')),
            ]),
          ]),
        ),
      );
}

class _RelayEmpty extends StatelessWidget {
  const _RelayEmpty(
      {required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center)
          ])));
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value));
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label)
      ]));
}

class _AnalyticsLine extends StatelessWidget {
  const _AnalyticsLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(DocmacIconlyLight.chart),
      title: Text(label),
      trailing: Text(value));
}
