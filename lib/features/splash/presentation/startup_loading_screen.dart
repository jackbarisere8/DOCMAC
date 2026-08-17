import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      duration: const Duration(milliseconds: 1250),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) context.go('/');
    });
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
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: const DocmacMark(size: 44),
                  ),
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
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primaryContainer.withValues(alpha: .55),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: .23),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _OrbitSignalLoader(
                        progress: _controller.value,
                        active: scheme.primary,
                        resting: scheme.onSurfaceVariant.withValues(alpha: .23),
                      ),
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

/// A small orbit of signals gives the app its own loading signature.
class _OrbitSignalLoader extends StatelessWidget {
  const _OrbitSignalLoader({
    required this.progress,
    required this.active,
    required this.resting,
  });

  final double progress;
  final Color active;
  final Color resting;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 45,
        height: 45,
        child: CustomPaint(
          painter: _OrbitSignalPainter(
            progress: progress,
            active: active,
            resting: resting,
          ),
        ),
      );
}

class _OrbitSignalPainter extends CustomPainter {
  const _OrbitSignalPainter({
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
    final radius = size.width * .31;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = resting
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var index = 0; index < 3; index++) {
      final phase = (progress - index / 3) % 1;
      final angle = (progress * math.pi * 2) + (index * math.pi * 2 / 3);
      final pulse = .42 + (math.sin(phase * math.pi) * .58);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(
        point,
        3.5 + (pulse * 1.5),
        Paint()..color = Color.lerp(resting, active, pulse)!,
      );
    }
    canvas.drawCircle(center, 3.8, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_OrbitSignalPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.resting != resting;
}
