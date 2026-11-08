import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/feature_flags.dart';
import '../../../../config/router/app_back.dart';
import '../../../../core/ui/docmac_iconly.dart';

/// Call experience surface: active call timer, mute/speaker toggles, and audio route controls.
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

  bool get _isPhoneNumber =>
      RegExp(r'^[0-9+()\-\s]+$').hasMatch(widget.personId);

  String get name {
    final known = AppFeatureFlags.localPreviews
        ? const {
            'emma': 'Emma Clarke',
            'jack': 'Jack Wilson',
            'david': 'David Okafor',
            'tobi': 'Tobi Adeyemi',
          }
        : const <String, String>{};
    final knownName = known[widget.personId.toLowerCase()];
    if (knownName != null) return knownName;
    if (_isPhoneNumber) return widget.personId;
    return 'Docmac member';
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => connected = true);
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => duration += const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _showInCallOptions() {
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
                leading: const Icon(DocmacIconlyLight.volumeUp),
                title: const Text('Audio Output'),
                subtitle: Text(speaker ? 'Speakerphone' : 'Device earpiece'),
                trailing: Switch(
                  value: speaker,
                  onChanged: (val) {
                    Navigator.pop(sheetContext);
                    setState(() => speaker = val);
                  },
                ),
              ),
              const ListTile(
                leading: Icon(DocmacIconlyLight.shieldDone),
                title: Text('Call security'),
                subtitle: Text(
                  'Calling is a simulated preview in this build. No audio '
                  'leaves your device.',
                ),
                trailing: Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    AppBack.to(context, fallback: '/live');
                  },
                  icon: Icon(
                    DocmacIconlyLight.arrowDown,
                    color: colors.onPrimary,
                  ),
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 68,
                backgroundColor: colors.onPrimary.withValues(alpha: .18),
                foregroundColor: colors.onPrimary,
                child: _isPhoneNumber
                    ? const Icon(DocmacIconlyLight.voice, size: 52)
                    : Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                connected
                    ? 'Simulated call · $time'
                    : 'Starting simulated call…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: .8),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Simulated voice preview',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: .7),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallControl(
                    icon: muted
                        ? DocmacIconlyLight.voice_2
                        : DocmacIconlyLight.voice,
                    label: muted ? 'Unmute' : 'Mute',
                    active: muted,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => muted = !muted);
                    },
                  ),
                  _CallControl(
                    icon: speaker
                        ? DocmacIconlyLight.volumeUp
                        : DocmacIconlyLight.volumeOff,
                    label: 'Speaker',
                    active: speaker,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => speaker = !speaker);
                    },
                  ),
                  _CallControl(
                    icon: DocmacIconlyLight.moreCircle,
                    label: 'Options',
                    onTap: _showInCallOptions,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  AppBack.to(context, fallback: '/live');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                ),
                child: const Icon(DocmacIconlyLight.call, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: active ? color : color.withValues(alpha: .16),
            foregroundColor:
                active ? Theme.of(context).colorScheme.primary : color,
            fixedSize: const Size(58, 58),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
