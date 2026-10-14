import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _tab = 0;
  final _read = <String>{};

  static const _updates = [
    _Notice('Orbit shield', 'A new sign-in was confirmed on your account.',
        '2m ago', DocmacIconlyLight.shieldDone, Color(0xFF596FD1)),
    _Notice('Circle pulse', 'Weekend crew has a new plan waiting for you.',
        '24m ago', DocmacIconlyLight.activity, Color(0xFFE39B32)),
    _Notice('Kept safely', 'Your Keepsakes are synced and ready.', '1d ago',
        DocmacIconlyLight.star, Color(0xFF64AE77)),
    _Notice('New connection', 'Amara has joined your Orbit.', '3d ago',
        DocmacIconlyLight.addUser, Color(0xFF8593A8)),
  ];
  static const _mentions = [
    _Notice('Weekend crew', 'Nora mentioned you in “Sunday plans.”', '18m ago',
        DocmacIconlyLight.message, Color(0xFF7B65D9)),
    _Notice('Design circle', 'David replied to your prototype note.',
        'Yesterday', DocmacIconlyLight.chat, Color(0xFF2E9C92)),
  ];

  @override
  Widget build(BuildContext context) {
    final notices = _tab == 0 ? _updates : _mentions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrivals'),
        actions: [
          IconButton(
            tooltip: 'Arrival preferences',
            onPressed: () => context.push('/notifications/preferences'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                _NotificationTab(
                    label: 'Updates',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 24),
                _NotificationTab(
                    label: 'Mentions',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() =>
                      _read.addAll(notices.map((notice) => notice.title))),
                  child: const Text('Mark all read'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notice = notices[index];
                final unread = !_read.contains(notice.title);
                return InkWell(
                  onTap: () => setState(() => _read.add(notice.title)),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: notice.color.withValues(alpha: .18),
                          foregroundColor: notice.color,
                          child: Icon(notice.icon),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(notice.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(fontSize: 16))),
                                  if (unread)
                                    Icon(DocmacIconlyLight.activity,
                                        size: 11, color: notice.color),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notice.detail,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 10),
                              Text(notice.time,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed controls for the notifications that arrive across Docmac.
class ArrivalPreferencesPage extends StatefulWidget {
  const ArrivalPreferencesPage({super.key});

  @override
  State<ArrivalPreferencesPage> createState() => _ArrivalPreferencesPageState();
}

class _ArrivalPreferencesPageState extends State<ArrivalPreferencesPage> {
  static const _defaults = {
    'tones': true,
    'reminders': true,
    'talkPriority': true,
    'talkReactions': true,
    'circlePriority': true,
    'circleReactions': true,
    'orbitPriority': true,
    'orbitReactions': true,
  };

  late Map<String, bool> _settings = Map.of(_defaults);

  void _toggle(String key, bool value) => setState(() => _settings[key] = value);

  Future<void> _chooseValue({
    required String title,
    required String current,
    required List<String> options,
  }) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 8),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: option == current
                      ? Icon(Icons.check_rounded,
                          color: Theme.of(sheetContext).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (selection != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title set to $selection')),
      );
    }
  }

  Future<void> _confirmReset() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset arrival preferences?'),
        content: const Text(
          'This resets notification tones, priority controls, reactions, and reminders to their defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset == true && mounted) {
      setState(() => _settings = Map.of(_defaults));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival preferences reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Arrival preferences'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Arrival preference options',
              onSelected: (value) {
                if (value == 'reset') _confirmReset();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Text('Reset arrival preferences'),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            _ArrivalToggle(
              title: 'Conversation tones',
              subtitle: 'Play sounds for incoming and outgoing messages.',
              value: _settings['tones']!,
              onChanged: (value) => _toggle('tones', value),
            ),
            _ArrivalToggle(
              title: 'Reminders',
              subtitle: 'Get occasional reminders about activity you have not seen.',
              value: _settings['reminders']!,
              onChanged: (value) => _toggle('reminders', value),
            ),
            const _ArrivalSection('Talk'),
            _ArrivalChoice(
              title: 'Notification tone',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Talk notification tone',
                current: 'Default',
                options: const ['Default', 'Chime', 'Pulse', 'Silent'],
              ),
            ),
            _ArrivalChoice(
              title: 'Vibrate',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Talk vibration',
                current: 'Default',
                options: const ['Default', 'Short', 'Long', 'Off'],
              ),
            ),
            const _ArrivalChoice(title: 'Popup notification', subtitle: 'Managed by your device', enabled: false),
            _ArrivalChoice(
              title: 'Light',
              subtitle: 'White',
              onTap: () => _chooseValue(
                title: 'Talk notification light',
                current: 'White',
                options: const ['White', 'Blue', 'Purple', 'Off'],
              ),
            ),
            _ArrivalToggle(
              title: 'Use high priority notifications',
              subtitle: 'Show previews at the top of the screen.',
              value: _settings['talkPriority']!,
              onChanged: (value) => _toggle('talkPriority', value),
            ),
            _ArrivalToggle(
              title: 'Reaction notifications',
              subtitle: 'Show notifications for reactions to your messages.',
              value: _settings['talkReactions']!,
              onChanged: (value) => _toggle('talkReactions', value),
            ),
            const _ArrivalSection('Circles'),
            _ArrivalChoice(
              title: 'Notification tone',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Circle notification tone',
                current: 'Default',
                options: const ['Default', 'Chime', 'Pulse', 'Silent'],
              ),
            ),
            _ArrivalChoice(
              title: 'Vibrate',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Circle vibration',
                current: 'Default',
                options: const ['Default', 'Short', 'Long', 'Off'],
              ),
            ),
            _ArrivalChoice(
              title: 'Light',
              subtitle: 'White',
              onTap: () => _chooseValue(
                title: 'Circle notification light',
                current: 'White',
                options: const ['White', 'Blue', 'Purple', 'Off'],
              ),
            ),
            _ArrivalToggle(
              title: 'Use high priority notifications',
              subtitle: 'Show Circle previews at the top of the screen.',
              value: _settings['circlePriority']!,
              onChanged: (value) => _toggle('circlePriority', value),
            ),
            _ArrivalToggle(
              title: 'Reaction notifications',
              subtitle: 'Show notifications for reactions in Circles.',
              value: _settings['circleReactions']!,
              onChanged: (value) => _toggle('circleReactions', value),
            ),
            const _ArrivalSection('Live and Orbit'),
            _ArrivalChoice(
              title: 'Call ringtone',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Call ringtone',
                current: 'Default',
                options: const ['Default', 'Echo', 'Ripple', 'Silent'],
              ),
            ),
            _ArrivalChoice(
              title: 'Call vibration',
              subtitle: 'Default',
              onTap: () => _chooseValue(
                title: 'Call vibration',
                current: 'Default',
                options: const ['Default', 'Short', 'Long', 'Off'],
              ),
            ),
            _ArrivalToggle(
              title: 'Use high priority notifications',
              subtitle: 'Show Orbit and Live previews at the top of the screen.',
              value: _settings['orbitPriority']!,
              onChanged: (value) => _toggle('orbitPriority', value),
            ),
            _ArrivalToggle(
              title: 'Reaction notifications',
              subtitle: 'Notify you when people react to your Orbit activity.',
              value: _settings['orbitReactions']!,
              onChanged: (value) => _toggle('orbitReactions', value),
            ),
          ],
        ),
      );
}

class _ArrivalSection extends StatelessWidget {
  const _ArrivalSection(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _ArrivalToggle extends StatelessWidget {
  const _ArrivalToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      );
}

class _ArrivalChoice extends StatelessWidget {
  const _ArrivalChoice({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 7),
        enabled: enabled,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      );
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab(
      {required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 3,
                width: active ? 62 : 0,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ],
          ),
        ),
      );
}

class _Notice {
  const _Notice(this.title, this.detail, this.time, this.icon, this.color);

  final String title;
  final String detail;
  final String time;
  final IconData icon;
  final Color color;
}
