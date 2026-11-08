import 'package:flutter/material.dart';

/// Honest placeholder for passkey sign-in.
///
/// The previous screen stored a boolean in SharedPreferences and claimed a
/// passkey had been created, but no WebAuthn credential existed and sign-in
/// never used one. Real passkeys need a relying-party server, challenge
/// storage, and credential verification, so this build does not pretend to
/// offer them.
class PasskeysPage extends StatelessWidget {
  const PasskeysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final brandGreen =
        isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(title: const Text('Passkeys')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: brandGreen,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.key_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Passkeys are not available yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign-in uses Firebase Authentication today: phone one-time codes '
            'or email and password. A passkey needs a verified WebAuthn '
            'credential on a relying-party server, so this build does not '
            'create one.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What protects your account today',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const _Fact(
                  icon: Icons.sms_outlined,
                  text: 'One-time SMS codes for phone sign-in',
                ),
                const _Fact(
                  icon: Icons.password_rounded,
                  text: 'Firebase-managed password hashing for email accounts',
                ),
                const _Fact(
                  icon: Icons.phonelink_erase_rounded,
                  text: 'Account deletion and password reset revoke sessions',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
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
