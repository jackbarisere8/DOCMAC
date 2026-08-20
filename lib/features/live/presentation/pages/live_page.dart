import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';

/// Docmac's private call hub: the next connection, useful call tools, and a
/// concise history in one calm place.
class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  bool _favoritesOnly = false;
  bool _missedOnly = false;

  List<_Call> get _visibleCalls => _calls.where((call) {
        if (_favoritesOnly && !call.favorite) return false;
        if (_missedOnly && !call.missed) return false;
        return true;
      }).toList();

  Future<void> _pickPerson() async {
    final person = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _PeopleSheet(),
    );
    if (person != null && mounted) context.push('/live/call/$person');
  }

  Future<void> _openKeypad() async {
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
    final calls = _visibleCalls;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _Header(onMore: _showOptions),
            const SizedBox(height: 30),
            Text('Start a signal', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Choose how you want to connect.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            _QuickActions(
              favoritesActive: _favoritesOnly,
              onVoice: _pickPerson,
              onSchedule: () => context.push('/live/schedule'),
              onKeypad: _openKeypad,
              onFavorites: () => setState(() {
                _favoritesOnly = !_favoritesOnly;
                if (_favoritesOnly) _missedOnly = false;
              }),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: Text('Recent signals', style: Theme.of(context).textTheme.headlineSmall)),
              if (_favoritesOnly || _missedOnly)
                TextButton(
                  onPressed: () => setState(() {
                    _favoritesOnly = false;
                    _missedOnly = false;
                  }),
                  child: const Text('Show all'),
                )
              else
                TextButton.icon(
                  onPressed: () => setState(() => _missedOnly = true),
                  icon: const Icon(Icons.call_missed_outgoing_rounded, size: 15),
                  label: const Text('Missed'),
                ),
            ]),
            const SizedBox(height: 12),
            if (calls.isEmpty)
              const _EmptyCalls()
            else
              _CallList(calls: calls, onCall: (call) => context.push('/live/call/${call.personId}')),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMore});
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Make time together', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 3),
            Text('Call, plan, and stay close.', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        _HeaderAction(
          icon: DocmacIconlyLight.calendar,
          label: 'Schedule a signal',
          onTap: () => context.push('/live/schedule'),
        ),
        const SizedBox(width: 8),
        _HeaderAction(icon: DocmacIconlyLight.moreCircle, label: 'Live options', onTap: onMore),
      ]);
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20),
            ),
          ),
        ),
      );
}

class _NextSignal extends StatelessWidget {
  const _NextSignal({required this.onSchedule});
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) => Container(
        height: 194,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandBase, Color(0xFF155CC4)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(children: [
          const Positioned(right: -10, top: -14, child: _SignalMap(size: 188)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('NEXT SIGNAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .9)),
              ),
              const Spacer(),
              const Text('Design circle', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.7)),
              const SizedBox(height: 4),
              Text('Today · 6:30 PM · Video', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12)),
              const SizedBox(height: 14),
              InkWell(
                onTap: onSchedule,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                  child: const Text('VIEW PLAN', style: TextStyle(color: AppColors.brandBase, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
                ),
              ),
            ]),
          ),
        ]),
      );
}

class _SignalMap extends StatelessWidget {
  const _SignalMap({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SignalMapPainter());
}

class _SignalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .52);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final scale in [.21, .36, .51]) {
      canvas.drawCircle(center, size.width * scale, line);
    }
    final path = Path()
      ..moveTo(0, size.height * .62)
      ..quadraticBezierTo(size.width * .24, size.height * .37, size.width * .48, size.height * .62)
      ..quadraticBezierTo(size.width * .72, size.height * .86, size.width, size.height * .54);
    canvas.drawPath(path, line);
    canvas.drawCircle(center, 16, Paint()..color = AppColors.primary);
    final mark = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + const Offset(-7, 0), center + const Offset(7, 0), mark);
    canvas.drawLine(center + const Offset(0, -7), center + const Offset(0, 7), mark);
    final satellite = Paint()..color = AppColors.accent;
    canvas.drawCircle(center + Offset(size.width * .32, -size.width * .17), 6, satellite);
    canvas.drawCircle(center + Offset(-size.width * .22, size.width * .32), 4, satellite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.favoritesActive, required this.onVoice, required this.onSchedule, required this.onKeypad, required this.onFavorites});
  final bool favoritesActive;
  final VoidCallback onVoice;
  final VoidCallback onSchedule;
  final VoidCallback onKeypad;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _QuickAction(icon: DocmacIconlyLight.voice, label: 'Voice', onTap: onVoice)),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: DocmacIconlyLight.calendar, label: 'Schedule', onTap: onSchedule)),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: Icons.dialpad_rounded, label: 'Keypad', onTap: onKeypad)),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: DocmacIconlyLight.heart, label: 'Favourites', active: favoritesActive, onTap: onFavorites)),
      ]);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 92,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : scheme.surface,
          border: Border.all(color: active ? scheme.onSurface : Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? scheme.onSurface : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: active ? scheme.surface : scheme.onSurface),
          ),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _CallList extends StatelessWidget {
  const _CallList({required this.calls, required this.onCall});
  final List<_Call> calls;
  final ValueChanged<_Call> onCall;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: [
          for (var index = 0; index < calls.length; index++) ...[
            _CallRow(call: calls[index], onCall: () => onCall(calls[index])),
            if (index != calls.length - 1) Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
          ],
        ]),
      );
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.call, required this.onCall});
  final _Call call;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onCall,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(children: [
          _Avatar(initial: call.initial, tint: call.tint),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(call.name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge)),
              if (call.favorite) ...[const SizedBox(width: 5), const Icon(DocmacIconlyLight.heart, size: 12)],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(call.missed ? Icons.call_missed_outgoing_rounded : Icons.call_made_rounded, size: 14, color: call.missed ? scheme.error : scheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Expanded(child: Text(call.detail, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))),
            ]),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(call.when, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            Container(
              width: 31,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Icon(call.video ? DocmacIconlyLight.video : DocmacIconlyLight.voice, size: 16),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.tint});
  final String initial;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(15)),
        child: Text(initial, style: const TextStyle(color: AppColors.brandBase, fontWeight: FontWeight.w800)),
      );
}

class _EmptyCalls extends StatelessWidget {
  const _EmptyCalls();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: [
          const Icon(DocmacIconlyLight.heart, size: 25),
          const SizedBox(height: 10),
          Text('Nothing here yet', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 3),
          Text('Try a different filter or start a new signal.', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
}

class _PeopleSheet extends StatelessWidget {
  const _PeopleSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Start a voice signal', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text('Choose someone who is ready to talk.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            for (final person in _people)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Avatar(initial: person.$2, tint: person.$3),
                title: Text(person.$1),
                subtitle: Text(person.$4),
                trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
                onTap: () => Navigator.pop(context, person.$5),
              ),
          ]),
        ),
      );
}

class _KeypadSheet extends StatefulWidget {
  const _KeypadSheet();

  @override
  State<_KeypadSheet> createState() => _KeypadSheetState();
}

class _KeypadSheetState extends State<_KeypadSheet> {
  String _number = '';

  void _addToContacts() {
    final router = GoRouter.of(context);
    final number = _number;
    Navigator.of(context).pop();
    router.push('/contacts/new', extra: number);
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
            Text(_number.isEmpty ? 'Enter a number' : _number, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['*', '0', '#'],
            ])
              Row(children: [
                for (final key in row)
                  Expanded(child: Padding(padding: const EdgeInsets.all(5), child: _Key(value: key, onTap: () => setState(() => _number += key)))),
              ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                tooltip: 'Delete number',
                onPressed: _number.isEmpty ? null : () => setState(() => _number = _number.substring(0, _number.length - 1)),
                icon: const Icon(Icons.backspace_outlined),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _number.isEmpty ? null : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling $_number is not available yet.'))),
                style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(19)),
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
          child: SizedBox(height: 48, child: Center(child: Text(value, style: Theme.of(context).textTheme.headlineSmall))),
        ),
      );
}

class _Call {
  const _Call({required this.personId, required this.name, required this.initial, required this.detail, required this.when, required this.tint, this.video = false, this.missed = false, this.favorite = false});
  final String personId;
  final String name;
  final String initial;
  final String detail;
  final String when;
  final Color tint;
  final bool video;
  final bool missed;
  final bool favorite;
}

const _people = [
  ('Emma Clarke', 'E', AppColors.accent, 'Available now', 'emma'),
  ('David Okafor', 'D', Color(0xFFD9E9F8), 'Last signal yesterday', 'david'),
  ('Tobi Adeyemi', 'T', Color(0xFFE6DFEF), 'Available now', 'tobi'),
  ('Jack Wilson', 'J', Color(0xFFF5E6C8), 'Last signal Monday', 'jack'),
];

const _calls = [
  _Call(personId: 'emma', name: 'Emma Clarke', initial: 'E', detail: 'Voice signal · 18 min', when: '6:21 PM', tint: AppColors.accent, favorite: true),
  _Call(personId: 'david', name: 'David Okafor', initial: 'D', detail: 'Missed video signal', when: '4:40 PM', tint: Color(0xFFD9E9F8), video: true, missed: true),
  _Call(personId: 'tobi', name: 'Tobi Adeyemi', initial: 'T', detail: 'Voice signal · 42 min', when: 'Yesterday', tint: Color(0xFFE6DFEF), favorite: true),
  _Call(personId: 'jack', name: 'Jack Wilson', initial: 'J', detail: 'Voice signal · 6 min', when: 'Mon', tint: Color(0xFFF5E6C8)),
];
