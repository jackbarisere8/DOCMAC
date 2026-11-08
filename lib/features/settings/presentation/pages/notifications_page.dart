import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Honest empty Arrivals feed.
///
/// The previous screen showed invented account alerts, Circle activity, and
/// mentions. This build does not deliver push notifications, so there is
/// nothing real to list yet.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrivals'),
        actions: [
          IconButton(
            tooltip: 'Notification settings',
            onPressed: () => context.push('/notifications/preferences'),
            icon: const Icon(DocmacIconlyLight.setting, size: 21),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 56, color: scheme.primary),
              const SizedBox(height: 18),
              Text(
                'No notifications yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Push notifications and in-app alerts are not delivered in '
                'this build. When they ship, account alerts and mentions will '
                'appear here instead of sample content.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Honest placeholder for notification preferences.
class ArrivalPreferencesPage extends StatelessWidget {
  const ArrivalPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Arrival preferences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Center(
            child: Icon(Icons.notifications_off_outlined,
                size: 56, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            'Notification preferences are not available yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Docmac does not deliver push notifications or in-app alerts in '
            'this build, so tones, vibration, priority, reaction, and reminder '
            'controls would not change anything. They are disabled rather '
            'than saved locally and shown as active.',
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
