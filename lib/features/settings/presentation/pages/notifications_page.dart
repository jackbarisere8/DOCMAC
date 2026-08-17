import 'package:flutter/material.dart';

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
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Arrival preferences are ready to customize.')),
            ),
            icon: const Icon(DocmacIconlyLight.filter),
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
