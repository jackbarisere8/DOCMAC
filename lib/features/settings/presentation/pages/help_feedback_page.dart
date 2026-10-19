import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/ui/docmac_iconly.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help and feedback')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _HelpRow(
              icon: DocmacIconlyLight.infoCircle,
              title: 'Help center',
              subtitle: 'Get help and contact support',
              onTap: () => context.push('/help/center'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.edit,
              title: 'Send feedback',
              subtitle: 'Report technical issues or share an idea',
              onTap: () => context.push('/help/feedback'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.document,
              title: 'Terms and privacy',
              onTap: () => _notice(context, 'Terms and privacy are ready to review.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.danger,
              title: 'Safety reports',
              onTap: () => _notice(context, 'Safety reports will appear here.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.infoCircle,
              title: 'App info',
              subtitle: 'Docmac 1.0.0',
              onTap: () => _notice(context, 'Docmac 1.0.0'),
            ),
          ],
        ),
      );

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _search = TextEditingController();
  var _query = '';

  static const _topics = [
    _HelpTopic('Chats & Messaging', 'Messages, backups, notifications, media, voice and video notes, AI experiences.', Icons.forum_outlined, route: '/help/chats'),
    _HelpTopic('Communities & Circles', 'Community spaces, admin permissions, and member guides.', Icons.groups_outlined, route: '/help/communities'),
    _HelpTopic('Status & Moments', 'Sharing updates, privacy, views, and third-party integrations.', Icons.amp_stories_outlined, route: '/help/status'),
    _HelpTopic('Privacy, Safety, and Security', 'End-to-end encryption, account controls, and reporting.', Icons.shield_outlined, route: '/help/privacy-safety-security'),
    _HelpTopic('Troubleshooting & Diagnostics', 'Fixing issues, connectivity, account recovery, and foreign devices.', Icons.build_outlined, route: '/help/troubleshooting'),
    _HelpTopic('Live & Calls', 'Voice rooms, audio calls, and scheduled sessions.', Icons.call_outlined),
  ];
  static const _articles = [
    'How to create and share a status',
    'How to fix connection issues',
    'Keep your account secure',
    'Not seeing a feature on Docmac',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String value) =>
      _query.isEmpty || value.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topics = _topics.where((item) => _matches('${item.title} ${item.description}')).toList();
    final articles = _articles.where(_matches).toList();
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Help center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Icon(Icons.support_agent_rounded, size: 42, color: scheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text('How can we help?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search Help Center',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear help search',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Help topics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final topic in topics)
            _HelpCenterRow(
              icon: topic.icon,
              title: topic.title,
              subtitle: topic.description,
              onTap: () {
                HapticFeedback.selectionClick();
                if (topic.route != null) {
                  context.push(topic.route!);
                } else {
                  _showArticle(context, topic.title, topic.description);
                }
              },
            ),
          if (topics.isEmpty && articles.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No help topics match that search.'))),
          if (articles.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Popular articles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final article in articles)
              _HelpCenterRow(
                icon: Icons.article_outlined,
                title: article,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (article.contains('status')) {
                    context.push('/help/status');
                  } else if (article.contains('connection') || article.contains('feature')) {
                    context.push('/help/troubleshooting');
                  } else {
                    _showArticle(context, article);
                  }
                },
              ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/help/feedback'),
            icon: const Icon(Icons.contact_support_outlined),
            label: const Text('Contact support'),
          ),
        ],
      ),
    );
  }

  static void _showArticle(BuildContext context, String title, [String? subtitle]) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (subtitle != null) ...[
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                const SizedBox(height: 16),
              ],
              Text(
                'Docmac protects your privacy and signals with end-to-end encryption. All messages and voice sessions are encrypted on your device and can only be decrypted by the intended recipient.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _feedback = TextEditingController();
  Uint8List? _attachment;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    _feedback.addListener(_refresh);
  }

  @override
  void dispose() {
    _feedback
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _addScreenshot() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1440);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachment = bytes;
        _attachmentName = file.name;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We could not add that screenshot.')));
      }
    }
  }

  void _submit() {
    if (_feedback.text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks. Your feedback is ready to send.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _feedback.text.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Send feedback')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Describe a technical issue or share an idea. For safety concerns, visit the Help Center first.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _feedback,
              minLines: 6,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Describe the issue or feedback', alignLabelWithHint: true),
            ),
            const SizedBox(height: 22),
            Text('Screenshot (optional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text('Remove sensitive information before attaching it.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _FeedbackAttachment(
              bytes: _attachment,
              name: _attachmentName,
              onAdd: _addScreenshot,
              onRemove: () => setState(() {
                _attachment = null;
                _attachmentName = null;
              }),
            ),
            const Spacer(),
            Text('By sending, you allow Docmac to review related technical information to help address your feedback.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton(onPressed: canSubmit ? _submit : null, child: const Text('Send feedback')),
          ]),
        ),
      ),
    );
  }
}

class _FeedbackAttachment extends StatelessWidget {
  const _FeedbackAttachment({required this.bytes, required this.name, required this.onAdd, required this.onRemove});

  final Uint8List? bytes;
  final String? name;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (bytes == null) {
      return OutlinedButton.icon(
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), alignment: Alignment.centerLeft),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add screenshot'),
      );
    }
    return Container(
      height: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes!, width: 76, height: 76, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name ?? 'Screenshot', maxLines: 2, overflow: TextOverflow.ellipsis)),
        IconButton(tooltip: 'Remove screenshot', onPressed: onRemove, icon: const Icon(Icons.close_rounded)),
      ]),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.title, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 7),
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
        onTap: onTap,
      );
}

class _HelpCenterRow extends StatelessWidget {
  const _HelpCenterRow({required this.icon, required this.title, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class _HelpTopic {
  const _HelpTopic(this.title, this.description, this.icon, {this.route});

  final String title;
  final String description;
  final IconData icon;
  final String? route;
}
