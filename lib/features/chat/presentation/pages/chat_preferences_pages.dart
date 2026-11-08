import 'package:flutter/material.dart';

/// Talk appearance and message-timer pages were interactive mocks: they
/// changed local widget state, persisted nothing, and the disappearing timer
/// claimed messages would vanish for everyone. These honest screens replace
/// them until the features are actually built.

class ChatThemePage extends StatelessWidget {
  const ChatThemePage({super.key});

  @override
  Widget build(BuildContext context) => const _UnavailableTalkPreference(
        title: 'Talk theme',
        heading: 'Talk themes are not available yet',
        body: 'Per-conversation colours, chat colours, and wallpapers are not '
            'built. This screen cannot change how any chat looks, and nothing '
            'you tap is saved.',
        facts: [
          'Text messages are delivered through Firestore.',
          'The manual app-lock passcode protects this device only and does '
              'not encrypt messages.',
        ],
      );
}

class ChatColorPage extends StatelessWidget {
  const ChatColorPage({super.key});

  @override
  Widget build(BuildContext context) => const _UnavailableTalkPreference(
        title: 'Talk color',
        heading: 'Talk colors are not available yet',
        body: 'Changing the colour of a conversation is not built. No colour '
            'was applied or saved.',
      );
}

class WallpaperPage extends StatelessWidget {
  const WallpaperPage({super.key});

  @override
  Widget build(BuildContext context) => const _UnavailableTalkPreference(
        title: 'Wallpaper',
        heading: 'Wallpapers are not available yet',
        body: 'Choosing a wallpaper from the gallery or a colour is not '
            'built. Nothing was applied or saved.',
      );
}

class DisappearingMessagesPage extends StatelessWidget {
  const DisappearingMessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const _UnavailableTalkPreference(
        title: 'Disappearing messages',
        heading: 'Disappearing messages are not available yet',
        body: 'There is no message timer yet. Nothing in this build deletes '
            'messages automatically, for you or for anyone else. Messages stay '
            'in the conversation until the account is deleted.',
        facts: [
          'Deleting your account removes your profile, memberships, and '
              'sign-in record.',
          'Messages already delivered to another person stay in their history.',
          'End-to-end encryption is also not implemented yet.',
        ],
      );
}

class _UnavailableTalkPreference extends StatelessWidget {
  const _UnavailableTalkPreference({
    required this.title,
    required this.heading,
    required this.body,
    this.facts = const [],
  });

  final String title;
  final String heading;
  final String body;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
        children: [
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 24),
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
                    'What works today',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final fact in facts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 17, color: scheme.primary),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              fact,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
