import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WhatsApp-style Privacy Help Center screen (Image 5).
/// Contains the complete index of privacy, encryption, and data-rights documentation.
class PrivacyHelpPage extends StatefulWidget {
  const PrivacyHelpPage({super.key});

  @override
  State<PrivacyHelpPage> createState() => _PrivacyHelpPageState();
}

class _PrivacyArticle {
  const _PrivacyArticle(this.title, this.summary);
  final String title;
  final String summary;
}

class _PrivacyHelpPageState extends State<PrivacyHelpPage> {
  String _filter = '';
  bool _searching = false;
  final _searchController = TextEditingController();

  static const _articles = [
    _PrivacyArticle(
      'About end-to-end encryption',
      'All personal chats, calls, media, and voice notes are end-to-end encrypted by default using cryptographic keys held exclusively on your devices.',
    ),
    _PrivacyArticle(
      'About privacy checkup',
      'Privacy Checkup guides you through multiple layers of protection, letting you choose the right level of security for messages, calls, and personal info.',
    ),
    _PrivacyArticle(
      'How to change your privacy settings',
      'Learn how to adjust who can see your presence, last seen, profile picture, about info, and status updates.',
    ),
    _PrivacyArticle(
      'How to change group privacy settings',
      'Decide who can add you to Circles and Spaces. Choose between Everyone, My Contacts, or My Contacts Except.',
    ),
    _PrivacyArticle(
      'How to protect your IP address on Docmac calls',
      'Relaying calls through Docmac servers masks your device IP address from peer participants for enhanced network privacy.',
    ),
    _PrivacyArticle(
      'Does Docmac collect or sell your data?',
      'Docmac does not sell your personal data, nor do we read or analyze encrypted message content for advertising.',
    ),
    _PrivacyArticle(
      'About advanced chat privacy',
      'Discover features like Chat Lock, disappearing messages, and screenshot prevention for view-once media.',
    ),
    _PrivacyArticle(
      'Privacy at a Glance: Additional Information about using Status and Channels',
      'Understand how audience selectors and subscriber lists protect your identity across Relays and public channels.',
    ),
    _PrivacyArticle(
      'How to silence unknown callers',
      'Calls from unknown numbers can be automatically silenced while still appearing in your call history and arrivals feed.',
    ),
    _PrivacyArticle(
      'About last seen and online',
      'Control whether contacts can see when you were last active or if you are currently online in the app.',
    ),
    _PrivacyArticle(
      'About Docmac permissions',
      'An overview of system permissions (Camera, Microphone, Contacts, Photos) requested by Docmac and how they are handled.',
    ),
    _PrivacyArticle(
      'How to use app lock',
      'Lock Docmac with biometrics (Face ID, Fingerprint) or device PIN so your conversations remain protected if your phone is unlocked.',
    ),
    _PrivacyArticle(
      'About sharing your device’s location',
      'Live Location sharing is end-to-end encrypted and automatically stops after the duration you select.',
    ),
    _PrivacyArticle(
      'Exercising your privacy rights on Docmac',
      'How to request your account data report, delete your profile, or manage third-party connected integrations.',
    ),
    _PrivacyArticle(
      'What is traceability and why does Docmac oppose it?',
      'Why client-side message tracing undermines end-to-end encryption and jeopardizes digital safety for journalists and everyday citizens.',
    ),
    _PrivacyArticle(
      'The threat of traceability in Brazil and privacy',
      'An analysis of regulatory challenges regarding private communication integrity and fundamental rights to privacy.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticle(_PrivacyArticle article) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(article.title),
        content: SingleChildScrollView(
          child: Text(
            article.summary,
            style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openContactUs() {
    HapticFeedback.selectionClick();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Contact Docmac Privacy Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us how we can help with your privacy or security questions:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your issue or question...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support request submitted.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final query = _filter.trim().toLowerCase();
    final filtered = _articles.where((article) {
      return query.isEmpty ||
          article.title.toLowerCase().contains(query) ||
          article.summary.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _filter = val),
                decoration: InputDecoration(
                  hintText: 'Search privacy topics...',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
              )
            : const Text('Privacy'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _searching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_searching) {
                  _searching = false;
                  _filter = '';
                  _searchController.clear();
                } else {
                  _searching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'terms',
                child: Text('Terms of service'),
              ),
              PopupMenuItem(
                value: 'policy',
                child: Text('Privacy policy'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.help_outline_rounded, size: 18),
        label: const Text(
          'Contact us',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        onPressed: _openContactUs,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Privacy',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No privacy articles found for “$_filter”',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final article in filtered)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Icon(
                  Icons.article_outlined,
                  color: scheme.onSurfaceVariant,
                  size: 22,
                ),
                title: Text(
                  article.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),
                onTap: () => _openArticle(article),
              ),
        ],
      ),
    );
  }
}

