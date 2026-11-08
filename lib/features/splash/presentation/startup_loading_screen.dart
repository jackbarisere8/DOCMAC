import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/firebase/firebase_configuration.dart';

/// The 2026 flagship startup splash screen.
/// Implements the high-precision vector path-drawing logo animation, glowing
/// comet stroke head, smooth gradient fill, and typography fade-up seen in the
/// reference video.
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient background glow spots
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.5 - 120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final animValue = disableAnimations ? 1.0 : _controller.value;
                  // Stroke drawing: 0.0 -> 0.65
                  final strokeProgress = Curves.easeInOutCubic.transform(
                    (animValue / 0.65).clamp(0.0, 1.0),
                  );
                  // Fill fade-in: 0.55 -> 0.85
                  final fillProgress = Curves.easeOutQuad.transform(
                    ((animValue - 0.55) / 0.30).clamp(0.0, 1.0),
                  );
                  // Text slide & fade: 0.70 -> 0.95
                  final textProgress = Curves.easeOutCubic.transform(
                    ((animValue - 0.70) / 0.25).clamp(0.0, 1.0),
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Vector Path Logo
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CustomPaint(
                          painter: _DocmacVectorLogoPainter(
                            strokeProgress: strokeProgress,
                            fillProgress: fillProgress,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Brand Wordmark & Tagline
                      Opacity(
                        opacity: textProgress,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1.0 - textProgress)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Docmac',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'A private place for the people that matter.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.60),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that executes the dynamic path-drawing, glowing comet tip,
/// and smooth gradient fill for the Docmac emblem.
class _DocmacVectorLogoPainter extends CustomPainter {
  const _DocmacVectorLogoPainter({
    required this.strokeProgress,
    required this.fillProgress,
  });

  final double strokeProgress;
  final double fillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Define Outer "D" Monogram Path
    final outerPath = Path()
      ..moveTo(w * 0.22, h * 0.14)
      ..lineTo(w * 0.52, h * 0.14)
      ..cubicTo(w * 0.88, h * 0.14, w * 0.94, h * 0.34, w * 0.94, h * 0.50)
      ..cubicTo(w * 0.94, h * 0.66, w * 0.88, h * 0.86, w * 0.52, h * 0.86)
      ..lineTo(w * 0.22, h * 0.86)
      ..close();

    // 2. Define Inner Wing / Accent Path
    final innerPath = Path()
      ..moveTo(w * 0.36, h * 0.32)
      ..lineTo(w * 0.58, h * 0.32)
      ..cubicTo(w * 0.72, h * 0.32, w * 0.74, h * 0.44, w * 0.66, h * 0.54)
      ..lineTo(w * 0.44, h * 0.70)
      ..cubicTo(w * 0.38, h * 0.74, w * 0.36, h * 0.70, w * 0.36, h * 0.64)
      ..close();

    // 3. Draw Gradient Fill when fillProgress > 0
    if (fillProgress > 0.0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: fillProgress * 0.96),
            const Color(0xFF38BDF8).withValues(alpha: fillProgress * 0.92),
            const Color(0xFF0284C7).withValues(alpha: fillProgress * 0.85),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      canvas.drawPath(outerPath, fillPaint);

      // Carve out inner counter with dark canvas blend
      final innerClearPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0A0D14);
      canvas.drawPath(innerPath, innerClearPaint);
    }

    // 4. Draw Animated Stroke Outlines with Glowing Comet Tip
    if (strokeProgress < 1.0 || fillProgress < 0.8) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white
            .withValues(alpha: (1.0 - fillProgress).clamp(0.2, 1.0));

      final outerMetrics = outerPath.computeMetrics();
      for (final metric in outerMetrics) {
        final length = metric.length;
        final extractLength = length * strokeProgress;
        final extractPath = metric.extractPath(0.0, extractLength);
        canvas.drawPath(extractPath, strokePaint);

        // Draw glowing comet head at the drawing tip
        if (strokeProgress > 0.01 && strokeProgress < 0.99) {
          final tangent = metric.getTangentForOffset(extractLength);
          if (tangent != null) {
            final cometPos = tangent.position;
            // Halo glow
            canvas.drawCircle(
              cometPos,
              6.5,
              Paint()
                ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
            );
            // Core bright point
            canvas.drawCircle(
              cometPos,
              2.8,
              Paint()..color = Colors.white,
            );
          }
        }
      }

      // Draw Inner Wing Stroke
      final innerMetrics = innerPath.computeMetrics();
      for (final metric in innerMetrics) {
        final length = metric.length;
        final extractLength = length * strokeProgress;
        final extractPath = metric.extractPath(0.0, extractLength);
        canvas.drawPath(
          extractPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF38BDF8).withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DocmacVectorLogoPainter oldDelegate) =>
      oldDelegate.strokeProgress != strokeProgress ||
      oldDelegate.fillProgress != fillProgress;
}
