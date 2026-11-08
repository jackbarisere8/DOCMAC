import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';

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
              title: 'Privacy information',
              subtitle: 'What Docmac enforces today',
              onTap: () => context.push('/settings/privacy-help'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.danger,
              title: 'Safety reports',
              onTap: () =>
                  _notice(context, 'Safety reporting is not available yet.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.infoCircle,
              title: 'App info',
              subtitle: 'About this build',
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Docmac'),
                  content: const Text(
                    'Version information is not available in this build.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
    _HelpTopic(
        'Chats & Messaging',
        'Messages, backups, notifications, media, voice and video notes, AI experiences.',
        Icons.forum_outlined,
        route: '/help/chats'),
    _HelpTopic(
        'Communities & Circles',
        'Community spaces, admin permissions, and member guides.',
        Icons.groups_outlined,
        route: '/help/communities'),
    _HelpTopic(
        'Status & Moments',
        'Sharing updates, privacy, views, and third-party integrations.',
        Icons.amp_stories_outlined,
        route: '/help/status'),
    _HelpTopic(
        'Privacy, Safety, and Security',
        'Privacy controls, account safety, and reporting.',
        Icons.shield_outlined,
        route: '/help/privacy-safety-security'),
    _HelpTopic(
        'Troubleshooting & Diagnostics',
        'Fixing issues, connectivity, account recovery, and foreign devices.',
        Icons.build_outlined,
        route: '/help/troubleshooting'),
    _HelpTopic(
        'Live & Calls',
        'Voice rooms, audio calls, and scheduled sessions.',
        Icons.call_outlined),
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
    final topics = _topics
        .where((item) => _matches('${item.title} ${item.description}'))
        .toList();
    final articles = _articles.where(_matches).toList();
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Help center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Icon(Icons.support_agent_rounded,
                  size: 42, color: scheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text('How can we help?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              DocmacSearchBar(
                controller: _search,
                hintText: 'Search Help Center',
                semanticsLabel: 'Search Help Center',
                clearTooltip: 'Clear help search',
                onChanged: (value) => setState(() => _query = value.trim()),
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
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child:
                    Center(child: Text('No help topics match that search.'))),
          if (articles.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Popular articles',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final article in articles)
              _HelpCenterRow(
                icon: Icons.article_outlined,
                title: article,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (article.contains('status')) {
                    context.push('/help/status');
                  } else if (article.contains('connection') ||
                      article.contains('feature')) {
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

  static void _showArticle(BuildContext context, String title,
      [String? subtitle]) {
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
                'Docmac limits every conversation to its members using Firebase '
                'Authentication and Firestore security rules. Messages are not '
                'end-to-end encrypted yet; that work will ship before it is '
                'advertised.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
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

class SendFeedbackPage extends StatelessWidget {
  const SendFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Send feedback')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        children: [
          Icon(Icons.feedback_outlined, size: 52, color: scheme.primary),
          const SizedBox(height: 18),
          Text(
            'Feedback submission is not available yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'This build does not send feedback or screenshots to a server. '
            'The previous form collected text and claimed it was ready to '
            'send, so it has been removed rather than pretending to work.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 26),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle});

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
  const _HelpCenterRow(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle});

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
