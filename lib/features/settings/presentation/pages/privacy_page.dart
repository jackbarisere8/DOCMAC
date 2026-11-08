import 'package:flutter/material.dart';

/// Honest privacy overview.
///
/// The previous screen offered audience pickers, visibility switches, read
/// receipts, blocking, and account-deletion controls that only wrote to
/// SharedPreferences. None of those settings were enforced by Firestore or the
/// other participant's app. This page lists what is actually enforced today and
/// clearly marks the rest as unavailable instead of collecting dead toggles.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Audience, last-seen, read-receipt, typing, blocking, and '
                    'mute controls are not available yet. This build does not '
                    'save preferences that the server never applies.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _Section(
            title: 'Protection enforced today',
            children: [
              _Fact(
                icon: Icons.group_outlined,
                title: 'Conversation membership',
                detail:
                    'Firestore rules let only the people in a conversation read its messages.',
              ),
              _Fact(
                icon: Icons.person_outline_rounded,
                title: 'Private account details',
                detail:
                    'Your phone number and other contact details stay in an owner-only account document.',
              ),
              _Fact(
                icon: Icons.lock_outline_rounded,
                title: 'End-to-end encryption',
                detail:
                    'Not shipped yet. Messages are protected by account access and Firestore rules, but the service operator can access stored text.',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _Section(
            title: 'Visibility controls not available yet',
            children: [
              _UnavailableRow('Phone number'),
              _UnavailableRow('Last seen and online'),
              _UnavailableRow('Profile photo'),
              _UnavailableRow('Forwarded messages'),
              _UnavailableRow('Calls'),
              _UnavailableRow('Voice messages'),
              _UnavailableRow('Messages'),
              _UnavailableRow('Birthday'),
              _UnavailableRow('Gifts'),
              _UnavailableRow('Bio'),
              _UnavailableRow('Saved music'),
              _UnavailableRow('Invites'),
            ],
          ),
          const SizedBox(height: 22),
          const _Section(
            title: 'Talk controls',
            children: [
              _UnavailableRow('Read receipts'),
              _UnavailableRow('Typing indicator'),
              _UnavailableRow('Link previews'),
              _UnavailableRow('Archive and mute'),
            ],
          ),
          const SizedBox(height: 22),
          const _Section(
            title: 'Blocked and muted people',
            children: [
              _UnavailableRow('Blocked people'),
              _UnavailableRow('Muted people'),
            ],
          ),
          const SizedBox(height: 22),
          const _Section(
            title: 'Contacts',
            children: [
              _UnavailableRow('Sync contacts'),
              _UnavailableRow('Suggest frequent contacts'),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Account deletion is available from Settings → Account. '
            'Data export, automatic deletion schedules, and blocked-people '
            'management are not available yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(children: children),
            ),
          ),
        ],
      );
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(detail),
      );
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(label),
        trailing: Text(
          'Not available yet',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      );
}
