import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';

/// Reusable scaffold for Help Center subcategories matching WhatsApp design
/// (Images 1-5). Includes real-time search and the pinned "? Contact us" FAB.
class HelpCategoryScaffold extends StatefulWidget {
  const HelpCategoryScaffold({
    super.key,
    required this.title,
    required this.sectionHeader,
    required this.children,
    this.searchQuery,
    this.onSearchChanged,
  });

  final String title;
  final String sectionHeader;
  final List<Widget> children;
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;

  @override
  State<HelpCategoryScaffold> createState() => _HelpCategoryScaffoldState();
}

class _HelpCategoryScaffoldState extends State<HelpCategoryScaffold> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openContactDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Contact support'),
        content: const Text(
          'Support messaging is not available yet. This build cannot send '
          'support requests, so nothing you type here would reach the team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? DocmacSearchBar(
                controller: _searchController,
                autofocus: true,
                height: 42,
                hintText: 'Search ${widget.title.toLowerCase()}...',
                semanticsLabel: 'Search ${widget.title.toLowerCase()}',
                onChanged: widget.onSearchChanged,
              )
            : Text(widget.title),
        actions: [
          IconButton(
            icon:
                Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  widget.onSearchChanged?.call('');
                } else {
                  _isSearching = true;
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
                value: 'privacy',
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
        onPressed: () => _openContactDialog(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              widget.sectionHeader,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...widget.children,
        ],
      ),
    );
  }
}

/// Help Center -> Privacy, Safety, and Security (Image 1)
class HelpPrivacySafetySecurityPage extends StatelessWidget {
  const HelpPrivacySafetySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return HelpCategoryScaffold(
      title: 'Help Center',
      sectionHeader: 'Privacy, Safety, and Security',
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.lock_outline_rounded,
              color: scheme.onSurface, size: 22),
          title: const Text('Privacy',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/settings/privacy-help');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.shield_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Safety',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Safety',
                'Safety reporting is not available yet. Docmac limits conversations to their members with account access controls while reporting tools are being built.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.security_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Security',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/settings/security-notifications');
          },
        ),
      ],
    );
  }
}

/// Help Center -> Communities / Spaces & Circles (Image 2)
class HelpCommunitiesPage extends StatelessWidget {
  const HelpCommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return HelpCategoryScaffold(
      title: 'Help Center',
      sectionHeader: 'Communities',
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.flag_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Get Started',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Getting Started with Communities',
                'Create topic-based announcement spaces and bring related Circles together under one roof.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.manage_accounts_outlined,
              color: scheme.onSurface, size: 22),
          title: const Text('Admin',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Community Admins',
                'Community admins can manage member permissions, add or remove sub-circles, and broadcast announcements.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.group_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Member',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Member Guide',
                'Browse community topics, join sub-circles, and customize notification settings for individual groups.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.lock_outline_rounded,
              color: scheme.onSurface, size: 22),
          title: const Text('Privacy, Safety, and Security',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/help/privacy-safety-security');
          },
        ),
      ],
    );
  }
}

/// Help Center -> Chats / Talks (Image 3)
class HelpChatsPage extends StatelessWidget {
  const HelpChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return HelpCategoryScaffold(
      title: 'Help Center',
      sectionHeader: 'Chats',
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.chat_bubble_outline_rounded,
              color: scheme.onSurface, size: 22),
          title: const Text('Individual and Group Chats',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Individual and Group Chats',
                'Start 1:1 conversations with another account. Circles and group conversation screens are a local preview in this build and are not delivered to other accounts yet.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.cloud_upload_outlined,
              color: scheme.onSurface, size: 22),
          title: const Text('Back Up and Restore',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Back Up and Restore',
                'Chat backup is not available in this build. Your conversations are stored in Docmac and return when you sign in on the same account.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.notifications_none_rounded,
              color: scheme.onSurface, size: 22),
          title: const Text('Notifications',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/notifications/preferences');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.image_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Media',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Media Handling',
                'Media messages are not available in this build; chat sends text only. Photo, document, and video sharing will ship with its own upload, storage, and privacy work.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.mic_none_rounded, color: scheme.onSurface, size: 22),
          title: const Text('Voice Messages and Chats',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Voice Notes',
                'Voice notes are not available yet. Debug builds can record a local preview that stays on this device and is never delivered; release builds send text messages only.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading:
              Icon(Icons.videocam_outlined, color: scheme.onSurface, size: 22),
          title: const Text('Video Notes',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'Instant Video Notes',
                'Video notes are not available in this build. Chat currently sends text only.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.auto_awesome_outlined,
              color: scheme.onSurface, size: 22),
          title: const Text('AI Experiences',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            _showTopicInfo(context, 'AI in Docmac',
                'Docmac Forge and perspective engines provide on-demand summaries and assistive drafting on content you choose to share.');
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(Icons.help_outline_rounded,
              color: scheme.onSurface, size: 22),
          title: const Text('Troubleshooting',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/help/troubleshooting');
          },
        ),
      ],
    );
  }
}

/// Help Center -> Status / Moments (Image 4)
class HelpStatusPage extends StatefulWidget {
  const HelpStatusPage({super.key});

  @override
  State<HelpStatusPage> createState() => _HelpStatusPageState();
}

class _HelpStatusPageState extends State<HelpStatusPage> {
  String _query = '';

  static const _articles = [
    'About status',
    'How to create and share a status',
    'How to see who viewed or liked your status',
    'How to view, like, and reply to status',
    'How to manage status privacy',
    'How to share your Docmac Status to other apps',
    'How to hide and unhide statuses',
    'How to edit, save and delete your status',
    'About status mentions',
    'Can’t create or share status',
    'Can’t see someone’s statuses or replies',
    'How to integrate status with third-party apps',
    'About seeing ads on Docmac Status',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = _query.trim().toLowerCase();
    final filtered = _articles
        .where(
            (a) => normalized.isEmpty || a.toLowerCase().contains(normalized))
        .toList();

    return HelpCategoryScaffold(
      title: 'Status',
      sectionHeader: 'Status',
      searchQuery: _query,
      onSearchChanged: (val) => setState(() => _query = val),
      children: [
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No articles found.')),
          )
        else
          for (final article in filtered)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Icon(Icons.article_outlined,
                  color: scheme.onSurfaceVariant, size: 22),
              title: Text(article,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14.5)),
              onTap: () {
                HapticFeedback.selectionClick();
                _showTopicInfo(context, article,
                    'Documentation and step-by-step guidance for $article.');
              },
            ),
      ],
    );
  }
}

/// Help Center -> Troubleshooting (Image 5)
class HelpTroubleshootingPage extends StatefulWidget {
  const HelpTroubleshootingPage({super.key});

  @override
  State<HelpTroubleshootingPage> createState() =>
      _HelpTroubleshootingPageState();
}

class _HelpTroubleshootingPageState extends State<HelpTroubleshootingPage> {
  String _query = '';

  static const _articles = [
    'Not seeing a feature on Docmac',
    'Fixing issues on Docmac',
    'How to fix connection issues',
    'Can’t download or update Docmac',
    'How to manually update Docmac',
    'Can’t change phone number',
    'Contact names missing',
    'Can’t see a contact’s profile information',
    'How to recover lost contacts',
    'Don’t recognize contact’s account',
    'Seeing “Your devices were logged out”',
    'Seeing “You have been logged out”',
    'Seeing “You have been logged out for your account security”',
    'About using Docmac abroad',
    'About Docmac support languages',
    'About the languages Docmac is available in',
    'Can’t use keyboard in Docmac',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = _query.trim().toLowerCase();
    final filtered = _articles
        .where(
            (a) => normalized.isEmpty || a.toLowerCase().contains(normalized))
        .toList();

    return HelpCategoryScaffold(
      title: 'Troubleshooting',
      sectionHeader: 'Troubleshooting',
      searchQuery: _query,
      onSearchChanged: (val) => setState(() => _query = val),
      children: [
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No articles found.')),
          )
        else
          for (final article in filtered)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Icon(Icons.article_outlined,
                  color: scheme.onSurfaceVariant, size: 22),
              title: Text(article,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14.5)),
              onTap: () {
                HapticFeedback.selectionClick();
                _showTopicInfo(context, article,
                    'Diagnostic and troubleshooting instructions for $article.');
              },
            ),
      ],
    );
  }
}

void _showTopicInfo(BuildContext context, String title, String detail) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: Text(
        detail,
        style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(height: 1.5),
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
