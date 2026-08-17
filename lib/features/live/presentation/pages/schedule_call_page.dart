import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../data/scheduled_call_repository.dart';

/// A focused planning surface for a future voice or video signal.
///
/// The screen deliberately keeps scheduling local until a call service is
/// connected. That makes the interaction usable now without suggesting a call
/// has been sent to other people when it has not.
class ScheduleCallPage extends StatefulWidget {
  const ScheduleCallPage({super.key});

  @override
  State<ScheduleCallPage> createState() => _ScheduleCallPageState();
}

class _ScheduleCallPageState extends State<ScheduleCallPage> {
  final _titleController = TextEditingController(text: 'Design sync');
  final _noteController = TextEditingController();
  Set<String> _invitees = {'Emma Clarke', 'David Okafor'};
  late DateTime _startsAt;
  late DateTime _endsAt;
  bool _isVideo = true;
  bool _sendReminder = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startsAt = DateTime(now.year, now.month, now.day + 1, 16, 0);
    _endsAt = _startsAt.add(const Duration(minutes: 45));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Choose signal date',
    );
    if (chosen == null || !mounted) return;
    setState(() {
      final duration = _endsAt.difference(_startsAt);
      _startsAt = DateTime(
        chosen.year,
        chosen.month,
        chosen.day,
        _startsAt.hour,
        _startsAt.minute,
      );
      _endsAt = _startsAt.add(duration);
    });
  }

  Future<void> _pickTime({required bool end}) async {
    final value = end ? _endsAt : _startsAt;
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: end ? 'Choose ending time' : 'Choose starting time',
    );
    if (chosen == null || !mounted) return;
    setState(() {
      final next = DateTime(
        value.year,
        value.month,
        value.day,
        chosen.hour,
        chosen.minute,
      );
      if (end) {
        _endsAt = next.isAfter(_startsAt)
            ? next
            : _startsAt.add(const Duration(minutes: 15));
      } else {
        final duration = _endsAt.difference(_startsAt);
        _startsAt = next;
        _endsAt = _startsAt.add(duration);
      }
    });
  }

  Future<void> _showPeoplePicker() async {
    const people = ['Emma Clarke', 'David Okafor', 'Tobi Adeyemi', 'Jack Wilson'];
    final next = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        var selected = Set<String>.from(_invitees);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Invite your people',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('They will receive the call details when you schedule it.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                ...people.map(
                  (person) => CheckboxListTile(
                    value: selected.contains(person),
                    contentPadding: EdgeInsets.zero,
                    title: Text(person),
                    secondary: _InitialAvatar(name: person, size: 36),
                    onChanged: (isSelected) => setSheetState(() {
                      isSelected! ? selected.add(person) : selected.remove(person);
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, selected),
                    child: const Text('Done'),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
    if (next != null) setState(() => _invitees = next);
  }

  Future<void> _schedule() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title so your people know the plan.')),
      );
      return;
    }
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to schedule a signal.')),
      );
      return;
    }

    final organizer = FirebaseAuth.instance.currentUser!;
    setState(() => _isSaving = true);
    try {
      await ScheduledCallRepository().create(
        organizerId: organizer.uid,
        draft: ScheduledCallDraft(
          title: title,
          note: _noteController.text.trim(),
          startsAt: _startsAt,
          endsAt: _endsAt,
          isVideo: _isVideo,
          inviteeNames: _invitees.toList(growable: false),
          reminderEnabled: _sendReminder,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_isVideo ? 'Video' : 'Voice'} signal scheduled for ${DateFormat.jm().format(_startsAt)}.'),
        ),
      );
    } on FirebaseException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the signal. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final day = DateFormat('EEE, d MMM').format(_startsAt);
    final duration = _endsAt.difference(_startsAt).inMinutes;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _ScheduleHeader(onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text('Make space for a real conversation.',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Choose a moment, a format, and the people who should be there.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                const _FieldLabel(label: 'Signal title'),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'What are you meeting about?'),
                ),
                const SizedBox(height: 22),
                const _FieldLabel(label: 'When'),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(children: [
                    _ScheduleRow(
                      icon: DocmacIconlyLight.calendar,
                      label: day,
                      trailing: 'Change',
                      onTap: _pickDate,
                    ),
                    Divider(height: 1, indent: 58, color: Theme.of(context).dividerColor),
                    _ScheduleRow(
                      icon: Icons.access_time_rounded,
                      label: 'Starts ${DateFormat.jm().format(_startsAt)}',
                      trailing: 'Change',
                      onTap: () => _pickTime(end: false),
                    ),
                    Divider(height: 1, indent: 58, color: Theme.of(context).dividerColor),
                    _ScheduleRow(
                      icon: Icons.timelapse_rounded,
                      label: 'Ends ${DateFormat.jm().format(_endsAt)}',
                      trailing: '$duration min',
                      onTap: () => _pickTime(end: true),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),
                const _FieldLabel(label: 'How you connect'),
                Row(children: [
                  Expanded(
                    child: _CallFormat(
                      selected: _isVideo,
                      icon: DocmacIconlyLight.video,
                      title: 'Video signal',
                      description: 'See the room',
                      onTap: () => setState(() => _isVideo = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CallFormat(
                      selected: !_isVideo,
                      icon: DocmacIconlyLight.voice,
                      title: 'Voice signal',
                      description: 'Keep it simple',
                      onTap: () => setState(() => _isVideo = false),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),
                const _FieldLabel(label: 'Your circle'),
                InkWell(
                  onTap: _showPeoplePicker,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 94,
                        height: 38,
                        child: Stack(
                          children: [
                            for (var index = 0; index < _invitees.length && index < 3; index++)
                              Positioned(
                                left: index * 27.0,
                                child: _InitialAvatar(
                                  name: _invitees.elementAt(index),
                                  size: 38,
                                  withBorder: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _invitees.isEmpty ? 'Add people' : '${_invitees.length} ${_invitees.length == 1 ? 'person' : 'people'} invited',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Icon(DocmacIconlyLight.arrowRight, color: scheme.primary, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 22),
                const _FieldLabel(label: 'A note for the room', optional: true),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Context, links, or a small agenda...'),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _sendReminder,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Give everyone a nudge'),
                  subtitle: const Text('A reminder goes out 15 minutes before.'),
                  onChanged: (value) => setState(() => _sendReminder = value),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _schedule,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(DocmacIconlyLight.calendar),
                label: Text(
                  _isSaving
                      ? 'Scheduling...'
                      : 'Schedule ${_isVideo ? 'video' : 'voice'} signal',
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 10),
        child: Row(children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(DocmacIconlyLight.arrowLeft),
          ),
          const SizedBox(width: 4),
          Text('Schedule a signal', style: Theme.of(context).textTheme.headlineSmall),
        ]),
      );
}

class _SignalPreview extends StatelessWidget {
  const _SignalPreview();

  @override
  Widget build(BuildContext context) => Container(
        height: 126,
        decoration: BoxDecoration(
          color: AppColors.brandBase,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(children: [
          const Positioned(right: 13, top: 12, child: _SignalOrbitIcon(size: 102)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('DOCMAC SIGNAL',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8)),
              ),
              const Spacer(),
              const Text('A moment with your people',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

class _SignalOrbitIcon extends StatelessWidget {
  const _SignalOrbitIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _SignalOrbitPainter(),
      );
}

class _SignalOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: .26);
    canvas.drawCircle(center, size.width * .38, ring);
    canvas.drawCircle(center, size.width * .24, ring);
    final core = Paint()..color = AppColors.primary;
    canvas.drawCircle(center, size.width * .13, core);
    final mark = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawLine(center + const Offset(-6, 0), center + const Offset(6, 0), mark);
    canvas.drawLine(center + const Offset(0, -6), center + const Offset(0, 6), mark);
    final dot = Paint()..color = AppColors.accent;
    canvas.drawCircle(center + Offset(size.width * .38, -size.width * .06), 5, dot);
    canvas.drawCircle(center + Offset(-size.width * .23, size.width * .30), 4, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.optional = false});
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.labelLarge,
            children: [
              TextSpan(text: label),
              if (optional)
                TextSpan(
                  text: '  optional',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
      );
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.icon, required this.label, required this.trailing, required this.onTap});
  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: Theme.of(context).textTheme.labelLarge),
        trailing: Text(trailing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                )),
      );
}

class _CallFormat extends StatelessWidget {
  const _CallFormat({required this.selected, required this.icon, required this.title, required this.description, required this.onTap});
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? scheme.primary : Theme.of(context).dividerColor, width: selected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(height: 15),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.size, this.withBorder = false});
  final String name;
  final double size;
  final bool withBorder;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          border: withBorder ? Border.all(color: Theme.of(context).colorScheme.surface, width: 2) : null,
        ),
        child: Text(name.substring(0, 1),
            style: TextStyle(color: AppColors.brandBase, fontWeight: FontWeight.w800, fontSize: size * .38)),
      );
}
