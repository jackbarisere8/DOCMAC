import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Call experience shell for Phase 1. Signalling/media transport is intentionally
/// kept behind this surface so it can be connected without changing navigation.
class VoiceCallPage extends StatefulWidget {
  const VoiceCallPage({super.key, required this.personId});
  final String personId;
  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  Timer? timer;
  Duration duration = Duration.zero;
  bool muted = false;
  bool speaker = true;
  bool connected = false;

  String get name =>
      {
        'emma': 'Emma Clarke',
        'jack': 'Jack Wilson',
        'david': 'David Okafor',
        'tobi': 'Tobi Adeyemi'
      }[widget.personId] ??
      'Your person';

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => connected = true);
      timer = Timer.periodic(const Duration(seconds: 1),
          (_) => setState(() => duration += const Duration(seconds: 1)));
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(DocmacIconlyLight.arrowDown,
                        color: colors.onPrimary))),
            const Spacer(),
            CircleAvatar(
                radius: 68,
                backgroundColor: colors.onPrimary.withValues(alpha: .18),
                foregroundColor: colors.onPrimary,
                child: Text(name.substring(0, 1),
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w800))),
            const SizedBox(height: 24),
            Text(name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(connected ? time : 'Calling…',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colors.onPrimary.withValues(alpha: .8))),
            const SizedBox(height: 10),
            Text('Voice call',
                style:
                    TextStyle(color: colors.onPrimary.withValues(alpha: .7))),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _CallControl(
                  icon: muted ? DocmacIconlyLight.voice_2 : DocmacIconlyLight.voice,
                  label: muted ? 'Unmute' : 'Mute',
                  active: muted,
                  onTap: () => setState(() => muted = !muted)),
              _CallControl(
                  icon: speaker
                      ? DocmacIconlyLight.volumeUp
                      : DocmacIconlyLight.volumeOff,
                  label: 'Speaker',
                  active: speaker,
                  onTap: () => setState(() => speaker = !speaker)),
              _CallControl(
                  icon: DocmacIconlyLight.moreCircle,
                  label: 'More',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Call options are ready.')))),
            ]),
            const SizedBox(height: 26),
            FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20)),
                child: const Icon(DocmacIconlyLight.call, size: 28)),
          ]),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Column(children: [
      IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(
              backgroundColor: active ? color : color.withValues(alpha: .16),
              foregroundColor:
                  active ? Theme.of(context).colorScheme.primary : color,
              fixedSize: const Size(58, 58)),
          icon: Icon(icon)),
      const SizedBox(height: 7),
      Text(label, style: TextStyle(color: color)),
    ]);
  }
}
