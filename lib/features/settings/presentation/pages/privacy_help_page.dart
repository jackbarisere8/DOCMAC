import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';

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
      'About message privacy',
      'Docmac does not encrypt messages end-to-end yet. Today, access is limited to the people in each conversation by Firebase Authentication and Firestore security rules. End-to-end encryption is planned before it is offered.',
    ),
    _PrivacyArticle(
      'About privacy checkup',
      'Privacy Checkup is not available yet. This build has no guided flow for choosing message, call, or personal-info protections.',
    ),
    _PrivacyArticle(
      'How to change your privacy settings',
      'Audience controls for presence, last seen, profile pictures, about info, and status updates are not available yet. This build does not apply choices that the server never receives.',
    ),
    _PrivacyArticle(
      'How to change group privacy settings',
      'Controls for who can add you to Circles and Spaces are not available yet.',
    ),
    _PrivacyArticle(
      'How to protect your IP address on Docmac calls',
      'Calling is a simulated UI in this build. No call audio or video leaves the device, so there are no relayed calls or peer IP addresses to protect yet.',
    ),
    _PrivacyArticle(
      'Does Docmac collect or sell your data?',
      'Docmac does not sell your personal data, nor do we use private message content for advertising.',
    ),
    _PrivacyArticle(
      'About advanced chat privacy',
      'Chat Lock, disappearing messages, and screenshot prevention are not available yet. The manual passcode on this device does not encrypt messages.',
    ),
    _PrivacyArticle(
      'Privacy at a Glance: Additional Information about using Status and Channels',
      'Audience selectors and subscriber lists for Relays and public channels are not available yet.',
    ),
    _PrivacyArticle(
      'How to silence unknown callers',
      'Unknown-caller silencing is not available yet, and calls are simulated in this build.',
    ),
    _PrivacyArticle(
      'About last seen and online',
      'Last seen and online visibility controls are not available yet. Docmac does not show this information from this screen.',
    ),
    _PrivacyArticle(
      'About Docmac permissions',
      'Permission prompts appear only when a specific feature asks for a capability. Photo-library access may be requested when you attach an image. This build does not use camera, microphone, or contacts permissions for messaging.',
    ),
    _PrivacyArticle(
      'How to use manual lock',
      'Set a 4-digit passcode under Settings → Lock app and tap Lock now to cover the app until you enter it. This build does not lock automatically when it returns from the background.',
    ),
    _PrivacyArticle(
      'About sharing your device’s location',
      'Live Location sharing is not available yet.',
    ),
    _PrivacyArticle(
      'Exercising your privacy rights on Docmac',
      'You can delete your account from Settings → Account. Account data export and third-party connected integrations are not available yet.',
    ),
    _PrivacyArticle(
      'What is traceability and why does Docmac oppose it?',
      'Why client-side message tracing undermines private communication and jeopardizes digital safety for journalists and everyday citizens.',
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
            ? DocmacSearchBar(
                controller: _searchController,
                autofocus: true,
                height: 42,
                hintText: 'Search privacy topics...',
                semanticsLabel: 'Search privacy topics',
                onChanged: (val) => setState(() => _filter = val),
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
            icon: const Icon(Icons.more_vert_rounded, size: 21),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'terms',
                child: DocmacMenuItem(
                  icon: DocmacIconlyLight.document,
                  label: 'Terms of service',
                ),
              ),
              PopupMenuItem(
                value: 'policy',
                child: DocmacMenuItem(
                  icon: DocmacIconlyLight.shieldDone,
                  label: 'Privacy policy',
                ),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
