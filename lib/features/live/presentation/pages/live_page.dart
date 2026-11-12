import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../data/models/call_record.dart';
import '../providers/live_providers.dart';

/// Docmac's private call hub: the next connection, useful call tools, and a
/// persistent, reactive signal history.
class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage> {
  Future<void> _pickPerson() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _PeopleSheet(),
    );
    if (result != null && mounted) {
      ref.read(callsNotifierProvider.notifier).logOutgoingCall(
            target: result.$1,
            displayName: result.$2,
          );
      context.push('/live/call/${result.$1}');
    }
  }

  Future<void> _openKeypad() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _KeypadSheet(),
    );
  }

  void _showOptions() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(DocmacIconlyLight.calendar),
                title: const Text('Scheduled signals'),
                subtitle: const Text('Plan a moment with your people'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/live/schedule');
                },
              ),
              ListTile(
                leading: const Icon(DocmacIconlyLight.setting),
                title: const Text('Live preferences'),
                subtitle: const Text('Audio, notifications, and privacy'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/settings');
                },
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final calls = ref.watch(filteredCallsProvider);
    final activeFilter = ref.watch(callFilterProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -1.05),
                    radius: 1.35,
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.16 : 0.07),
                      scheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Header(onMore: _showOptions),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Start a signal',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _QuickActions(
                  favoritesActive: activeFilter == CallFilter.favorites,
                  onVoice: _pickPerson,
                  onSchedule: () => context.push('/live/schedule'),
                  onKeypad: _openKeypad,
                  onFavorites: () {
                    HapticFeedback.selectionClick();
                    final notifier = ref.read(callFilterProvider.notifier);
                    notifier.state = activeFilter == CallFilter.favorites
                        ? CallFilter.all
                        : CallFilter.favorites;
                  },
                ),
                const SizedBox(height: 10),
                const _SimulationNote(),
                const SizedBox(height: 30),
                Row(children: [
                  Expanded(
                    child: Text(
                      'Recent signals',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  _FilterAction(
                    icon: activeFilter == CallFilter.all
                        ? Icons.call_missed_outgoing_rounded
                        : Icons.restart_alt_rounded,
                    label:
                        activeFilter == CallFilter.all ? 'Missed' : 'Show all',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(callFilterProvider.notifier).state =
                          activeFilter == CallFilter.all
                              ? CallFilter.missed
                              : CallFilter.all;
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                if (calls.isEmpty)
                  const _EmptyCalls()
                else
                  _CallList(
                    calls: calls,
                    onCall: (call) {
                      HapticFeedback.lightImpact();
                      ref.read(callsNotifierProvider.notifier).logOutgoingCall(
                            target: call.personId,
                            displayName: call.name,
                            isVideo: call.video,
                          );
                      context.push('/live/call/${call.personId}');
                    },
                    onToggleFavorite: (call) {
                      ref
                          .read(callsNotifierProvider.notifier)
                          .toggleFavorite(call.id);
                    },
                    onDelete: (call) {
                      ref
                          .read(callsNotifierProvider.notifier)
                          .deleteCall(call.id);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single, quiet line replaces the old build disclaimer so the page keeps
/// its airy hierarchy without hiding how preview calls behave.
class _SimulationNote extends StatelessWidget {
  const _SimulationNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Simulated on this device. No audio is sent.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11.5,
                  height: 1.3,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
                ),
          ),
        ),
      ],
    );
  }
}

class _FilterAction extends StatelessWidget {
  const _FilterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.85),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMore});
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Live',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          _HeaderAction(
            icon: DocmacIconlyLight.calendar,
            label: 'Schedule a signal',
            onTap: () => context.push('/live/schedule'),
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            icon: DocmacIconlyLight.moreCircle,
            label: 'Live options',
            onTap: onMore,
          ),
        ],
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.85),
              ),
            ),
            child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.favoritesActive,
    required this.onVoice,
    required this.onSchedule,
    required this.onKeypad,
    required this.onFavorites,
  });
  final bool favoritesActive;
  final VoidCallback onVoice;
  final VoidCallback onSchedule;
  final VoidCallback onKeypad;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _QuickAction(
          icon: DocmacIconlyLight.voice,
          label: 'Voice',
          primary: true,
          onTap: onVoice,
        )),
        const SizedBox(width: 9),
        Expanded(
            child: _QuickAction(
                icon: DocmacIconlyLight.calendar,
                label: 'Schedule',
                onTap: onSchedule)),
        const SizedBox(width: 9),
        Expanded(
            child: _QuickAction(
                icon: Icons.dialpad_rounded, label: 'Keypad', onTap: onKeypad)),
        const SizedBox(width: 9),
        Expanded(
            child: _QuickAction(
          icon: DocmacIconlyLight.heart,
          label: 'Favourites',
          active: favoritesActive,
          onTap: onFavorites,
        )),
      ]);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(18);

    final Color iconBackground;
    final Color iconColor;
    final Color labelColor;
    if (primary) {
      iconBackground = Colors.white.withValues(alpha: 0.16);
      iconColor = scheme.onPrimary;
      labelColor = scheme.onPrimary;
    } else if (active) {
      iconBackground = scheme.primary.withValues(alpha: 0.16);
      iconColor = scheme.primary;
      labelColor = scheme.onPrimaryContainer;
    } else {
      iconBackground = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : scheme.surfaceContainerHigh;
      iconColor = scheme.onSurface;
      labelColor = scheme.onSurfaceVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: primary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF4A83FF), AppColors.darkPrimary]
                    : [AppColors.primary, AppColors.brandBase],
              )
            : null,
        color: primary
            ? null
            : active
                ? scheme.primaryContainer
                : (isDark ? AppColors.darkCard : scheme.surface),
        border: Border.all(
          color: primary
              ? Colors.white.withValues(alpha: 0.12)
              : active
                  ? scheme.primary.withValues(alpha: 0.4)
                  : theme.dividerColor.withValues(alpha: 0.8),
        ),
        borderRadius: radius,
        boxShadow: primary
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallList extends StatelessWidget {
  const _CallList({
    required this.calls,
    required this.onCall,
    required this.onToggleFavorite,
    required this.onDelete,
  });
  final List<CallRecord> calls;
  final ValueChanged<CallRecord> onCall;
  final ValueChanged<CallRecord> onToggleFavorite;
  final ValueChanged<CallRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? null : scheme.surface,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkCard, AppColors.darkSurface],
              )
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.8 : 1),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(children: [
        for (var index = 0; index < calls.length; index++) ...[
          _CallRow(
            call: calls[index],
            onCall: () => onCall(calls[index]),
            onToggleFavorite: () => onToggleFavorite(calls[index]),
            onDelete: () => onDelete(calls[index]),
          ),
          if (index != calls.length - 1)
            Divider(
              height: 1,
              indent: 72,
              color: theme.dividerColor.withValues(alpha: 0.7),
            ),
        ],
      ]),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.call,
    required this.onCall,
    required this.onToggleFavorite,
    required this.onDelete,
  });
  final CallRecord call;
  final VoidCallback onCall;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  void _showCallMenu(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  call.favorite
                      ? Icons.favorite
                      : Icons.favorite_border_rounded,
                  color: call.favorite ? Colors.red : null,
                ),
                title: Text(call.favorite
                    ? 'Remove from Favourites'
                    : 'Add to Favourites'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onToggleFavorite();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove from Recent Calls',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onCall,
        onLongPress: () => _showCallMenu(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(children: [
            _Avatar(initial: call.initial, tint: call.tint),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Flexible(
                        child: Text(call.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge)),
                    if (call.favorite) ...[
                      const SizedBox(width: 5),
                      const Icon(DocmacIconlyLight.heart,
                          size: 12, color: AppColors.accent),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(
                      call.missed
                          ? Icons.call_missed_outgoing_rounded
                          : (call.isOutgoing
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded),
                      size: 14,
                      color:
                          call.missed ? scheme.error : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                        child: Text(call.detail,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontSize: 12))),
                  ]),
                ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(call.when,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10.5)),
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10.5)),
                child: Icon(
                    call.video
                        ? DocmacIconlyLight.video
                        : DocmacIconlyLight.voice,
                    size: 16),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.tint});
  final String initial;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Text(initial,
          style: const TextStyle(
              color: AppColors.brandBase, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyCalls extends StatelessWidget {
  const _EmptyCalls();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: isDark ? null : scheme.surface,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkCard, AppColors.darkSurface],
              )
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(DocmacIconlyLight.heart, size: 20, color: scheme.primary),
        ),
        const SizedBox(height: 12),
        Text('Nothing here yet', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Try a different filter or start a new signal.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
      ]),
    );
  }
}

class _PeopleSheet extends StatelessWidget {
  const _PeopleSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start a voice signal',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text('Choose someone who is ready to talk.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                if (_people.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'The people picker is not available yet. Start a private '
                      'talk with an exact @username, or use the keypad to open '
                      'the simulated call screen.',
                    ),
                  )
                else
                  for (final person in _people)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Avatar(initial: person.$2, tint: person.$3),
                      title: Text(person.$1),
                      subtitle: Text(person.$4),
                      trailing:
                          const Icon(DocmacIconlyLight.arrowRight, size: 18),
                      onTap: () =>
                          Navigator.pop(context, (person.$5, person.$1)),
                    ),
              ]),
        ),
      );
}

class _KeypadSheet extends ConsumerStatefulWidget {
  const _KeypadSheet();

  @override
  ConsumerState<_KeypadSheet> createState() => _KeypadSheetState();
}

class _KeypadSheetState extends ConsumerState<_KeypadSheet> {
  String _number = '';

  void _addToContacts() {
    final router = GoRouter.of(context);
    final number = _number;
    Navigator.of(context).pop();
    router.push('/contacts/new', extra: number);
  }

  void _initiateCall() {
    if (_number.isEmpty) return;
    HapticFeedback.mediumImpact();
    final dialed = _number;
    ref.read(callsNotifierProvider.notifier).logOutgoingCall(target: dialed);
    Navigator.of(context).pop();
    context.push('/live/call/$dialed');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _number.isEmpty
                    ? const SizedBox(key: ValueKey('no-contact-action'))
                    : IconButton(
                        key: const ValueKey('contact-action'),
                        tooltip: 'Add to contacts',
                        onPressed: _addToContacts,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                      ),
              ),
            ),
            Text(_number.isEmpty ? 'Enter a number' : _number,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['*', '0', '#'],
            ])
              Row(children: [
                for (final key in row)
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: _Key(
                              value: key,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _number += key);
                              }))),
              ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                tooltip: 'Delete number',
                onPressed: _number.isEmpty
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() =>
                            _number = _number.substring(0, _number.length - 1));
                      },
                icon: const Icon(Icons.backspace_outlined),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _number.isEmpty ? null : _initiateCall,
                style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(19)),
                child: const Icon(DocmacIconlyLight.voice),
              ),
            ]),
          ]),
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
              height: 48,
              child: Center(
                  child: Text(value,
                      style: Theme.of(context).textTheme.headlineSmall))),
        ),
      );
}

const _samplePeople = [
  ('Emma Clarke', 'E', AppColors.accent, 'Available now', 'emma'),
  ('David Okafor', 'D', Color(0xFFD9E9F8), 'Last signal yesterday', 'david'),
  ('Tobi Adeyemi', 'T', Color(0xFFE6DFEF), 'Available now', 'tobi'),
  ('Jack Wilson', 'J', Color(0xFFF5E6C8), 'Last signal Monday', 'jack'),
];

List<(String, String, Color, String, String)> get _people =>
    AppFeatureFlags.localPreviews ? _samplePeople : const [];
