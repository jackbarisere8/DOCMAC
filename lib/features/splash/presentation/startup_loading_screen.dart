import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/firebase/firebase_configuration.dart';
import '../../../shared/widgets/docmac_mark.dart';

/// The first Flutter frame after the platform launch surface. It deliberately
/// uses the compact wordmark treatment, rather than a large standalone logo.
class StartupLoadingScreen extends StatefulWidget {
  const StartupLoadingScreen({super.key});

  @override
  State<StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<StartupLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2100), _routeFromStartup);
  }

  /// Firebase persists phone-auth sessions on device. Only a profile that has
  /// completed onboarding may bypass the public screens on a later launch.
  Future<void> _routeFromStartup() async {
    if (!FirebaseConfiguration.isAvailable || Firebase.apps.isEmpty) {
      if (mounted) context.go('/');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/');
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        context
            .go(profile.data()?['onboardingComplete'] == true ? '/orbit' : '/');
      }
    } catch (_) {
      // Do not grant access from a partial/offline profile. The auth screens
      // remain available and show their own actionable backend errors.
      if (mounted) context.go('/');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -.03),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DocmacMark(size: 58),
                  const SizedBox(width: 15),
                  Text(
                    'Docmac',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, .60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _AuroraLoader(
                      progress: MediaQuery.disableAnimationsOf(context)
                          ? .18
                          : _controller.value,
                      active: scheme.primary,
                      resting: scheme.onSurfaceVariant.withValues(alpha: .18),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Preparing your circles',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A layered progress arc gives the launch experience a crisp, modern motion
/// signature while preserving a static accessible state when animations are
/// disabled at system level.
class _AuroraLoader extends StatelessWidget {
  const _AuroraLoader({
    required this.progress,
    required this.active,
    required this.resting,
  });

  final double progress;
  final Color active;
  final Color resting;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: CustomPaint(
          painter: _AuroraLoaderPainter(
            progress: progress,
            active: active,
            resting: resting,
          ),
        ),
      );
}

class _AuroraLoaderPainter extends CustomPainter {
  const _AuroraLoaderPainter({
    required this.progress,
    required this.active,
    required this.resting,
  });

  final double progress;
  final Color active;
  final Color resting;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width * .36;
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final startAngle = -math.pi / 2 + (progress * math.pi * 2);
    const arcSpan = math.pi * 1.34;

    final track = Paint()
      ..color = resting
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      center,
      outerRadius,
      track,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + arcSpan,
        colors: [
          active.withValues(alpha: .20),
          active.withValues(alpha: .68),
          active,
        ],
        stops: const [0, .56, 1],
      ).createShader(outerRect);
    canvas.drawArc(outerRect, startAngle, arcSpan, false, arcPaint);

    final innerRadius = size.width * .205;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerPaint = Paint()
      ..color = active.withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      innerRect,
      startAngle + math.pi * .45,
      math.pi * .58,
      false,
      innerPaint,
    );

    final headAngle = startAngle + arcSpan;
    final head = Offset(
      center.dx + math.cos(headAngle) * outerRadius,
      center.dy + math.sin(headAngle) * outerRadius,
    );
    canvas.drawCircle(
      head,
      5.5,
      Paint()
        ..color = active.withValues(alpha: .20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(head, 2.75, Paint()..color = active);
    canvas.drawCircle(center, 3.2, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_AuroraLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.resting != resting;
}
