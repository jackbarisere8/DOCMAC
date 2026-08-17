import 'package:flutter/material.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key, this.shareWith});
  final String? shareWith;

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final _moments = <_Moment>[
    const _Moment('Emma', 'A good read', Icons.menu_book_outlined, '2h left'),
    const _Moment(
        'David', 'Small wins', Icons.emoji_events_outlined, '6h left'),
    const _Moment('Nora', 'Sunday notes', Icons.edit_note_rounded, '10h left'),
  ];

  Future<void> _createMoment() async {
    final result = await showModalBottomSheet<_Moment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateMomentSheet(defaultAudience: widget.shareWith),
    );
    if (result != null && mounted) setState(() => _moments.insert(0, result));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Moments')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _createMoment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New moment')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('A small window into your people’s day.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
                'Every moment is private to the audience you choose and expires in 24 hours.'),
            const SizedBox(height: 24),
            for (final moment in _moments) ...[
              _MomentTile(moment: moment),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment});
  final _Moment moment;
  @override
  Widget build(BuildContext context) => Container(
        height: 145,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 16, child: Text(moment.owner.substring(0, 1))),
            const SizedBox(width: 9),
            Text(moment.owner),
            const Spacer(),
            Text(moment.expires)
          ]),
          const Spacer(),
          Icon(moment.icon, size: 30),
          const SizedBox(height: 6),
          Text(moment.title, style: Theme.of(context).textTheme.titleLarge),
        ]),
      );
}

class _CreateMomentSheet extends StatefulWidget {
  const _CreateMomentSheet({this.defaultAudience});
  final String? defaultAudience;
  @override
  State<_CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<_CreateMomentSheet> {
  final controller = TextEditingController();
  String audience = 'Everyone';
  IconData type = Icons.text_fields_rounded;
  @override
  void initState() {
    super.initState();
    audience = widget.defaultAudience ?? audience;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Share a moment',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 18),
                Wrap(spacing: 8, children: [
                  for (final item in [
                    (Icons.text_fields_rounded, 'Text'),
                    (Icons.photo_outlined, 'Photo'),
                    (Icons.videocam_outlined, 'Video'),
                    (Icons.mic_none_rounded, 'Voice'),
                    (Icons.music_note_outlined, 'Music'),
                    (Icons.poll_outlined, 'Poll'),
                    (Icons.help_outline_rounded, 'Question'),
                  ])
                    ChoiceChip(
                        label: Text(item.$2),
                        selected: type == item.$1,
                        onSelected: (_) => setState(() => type = item.$1)),
                ]),
                const SizedBox(height: 16),
                TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'What’s happening?',
                        hintText: 'Share a small update')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: audience,
                    decoration:
                        const InputDecoration(labelText: 'Who can see this?'),
                    items: {
                      'Everyone',
                      'Circle',
                      'Specific people',
                      'Only me',
                      if (widget.defaultAudience != null)
                        widget.defaultAudience!
                    }
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => audience = value ?? audience)),
                const SizedBox(height: 18),
                FilledButton(
                    onPressed: () => Navigator.pop(
                        context,
                        _Moment(
                            'You · $audience',
                            controller.text.trim().isEmpty
                                ? 'A new moment'
                                : controller.text.trim(),
                            type,
                            '24h left')),
                    child: const Text('Share for 24 hours')),
              ]),
        ),
      );
}

class _Moment {
  const _Moment(this.owner, this.title, this.icon, this.expires);
  final String owner;
  final String title;
  final IconData icon;
  final String expires;
}
