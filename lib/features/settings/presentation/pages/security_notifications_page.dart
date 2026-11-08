import 'package:flutter/material.dart';

/// Explains the security that actually exists today. End-to-end encryption is
/// a roadmap requirement, not a shipped feature, so this screen must not
/// describe it in the present tense.
class SecurityNotificationsPage extends StatelessWidget {
  const SecurityNotificationsPage({super.key});

  void _showLearnMore(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Message privacy'),
        content: const Text(
          'Docmac does not encrypt messages end-to-end yet. Today, message '
          'documents are restricted to the people in each conversation by '
          'Firebase Authentication and Firestore security rules, and the '
          'service operator can access stored content for maintenance. '
          'End-to-end encryption will be announced before it is enabled.\n\n'
          'Device security alerts are not available yet either. This screen '
          'does not collect a PIN or store a device secret.',
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
    final isDark = theme.brightness == Brightness.dark;
    final brandGreen =
        isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(title: const Text('Security notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How your account is protected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Docmac does not encrypt messages end-to-end yet. Today, only the '
            'people in a conversation can open its documents, and access is '
            'enforced by Firebase Authentication and Firestore security rules. '
            'This applies to:',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _FeatureRow(
            icon: Icons.chat_bubble_outline_rounded,
            color: brandGreen,
            text: 'Text messages between conversation members',
          ),
          _FeatureRow(
            icon: Icons.group_outlined,
            color: brandGreen,
            text: 'Circle and group membership checks',
          ),
          _FeatureRow(
            icon: Icons.phonelink_erase_rounded,
            color: brandGreen,
            text: 'Account deletion and session revocation',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => _showLearnMore(context),
              child: Text(
                'Learn more',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show security notifications on this device',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Not available yet. Device alerts need a server-side '
                      'security event feed, which this build does not have.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Switch.adaptive(
                value: false,
                onChanged: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
