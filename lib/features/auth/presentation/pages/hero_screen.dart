import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_mark.dart';

const double _kPhoneWidth = 216;
const double _kPhoneHeight = 446;

/// The welcome experience shown before authentication.
///
/// One physically lit device floats over a studio wash, with real hardware
/// detailing (metal rail, side keys, island camera, glass sheen) and a live
/// conversation on screen. The sheet below carries the brand lockup, a short
/// promise, three quiet trust signals, and the primary action.
class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
      value: 0.5,
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _floatingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HeroPalette.of(context);
    final size = MediaQuery.sizeOf(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final stageHeight = (size.height * 0.58).clamp(360.0, 560.0);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _StageBackdrop(palette: palette),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: stageHeight,
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, _) => _DeviceStage(
                  floatValue:
                      disableAnimations ? 0.5 : _floatingController.value,
                  palette: palette,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _WelcomeSheet(palette: palette),
          ),
        ],
      ),
    );
  }
}

/// Soft studio backdrop: a vertical paper wash with a barely-there grain so the
/// surface never reads as a flat generated gradient.
class _StageBackdrop extends StatelessWidget {
  const _StageBackdrop({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.topCanvas,
                palette.canvas,
                palette.bottomCanvas,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GrainPainter(color: palette.grain),
              isComplex: true,
              willChange: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(19);
    final paint = Paint();
    for (var i = 0; i < 260; i++) {
      paint.color = color.withValues(
        alpha: color.a * (0.28 + random.nextDouble() * 0.72),
      );
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.3 + random.nextDouble() * 0.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DeviceStage extends StatelessWidget {
  const _DeviceStage({
    required this.floatValue,
    required this.palette,
  });

  final double floatValue;
  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final t = floatValue * 2 * math.pi;
    final lift = math.sin(t) * 5.0;
    final breath = (math.cos(t) + 1) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final haloSize =
            (constraints.maxWidth * 0.86).clamp(280.0, 344.0).toDouble();

        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 20,
              child: _Halo(size: haloSize, palette: palette),
            ),
            Positioned(
              top: 12 + _kPhoneHeight - 16 + lift * 0.5,
              child: _ContactShadow(palette: palette, breath: breath),
            ),
            Positioned(
              top: 10 + lift,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(0.014)
                  ..rotateY(0.05)
                  ..rotateZ(-0.018),
                child: const _PhoneHardware(child: _ChatMockup()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.palette});

  final double size;
  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(0, -0.08),
            radius: 0.62,
            colors: [
              palette.haloCenter,
              palette.haloMid,
              palette.haloEdge,
            ],
            stops: const [0, 0.58, 1],
          ),
          border: Border.all(
            color: palette.haloRim,
            width: 0.8,
          ),
        ),
      ),
    );
  }
}

class _ContactShadow extends StatelessWidget {
  const _ContactShadow({required this.palette, required this.breath});

  final _HeroPalette palette;
  final double breath;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.42 + breath * 0.16,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 11, sigmaY: 8),
          child: Container(
            width: 178,
            height: 18,
            decoration: BoxDecoration(
              color:
                  palette.shadow.withValues(alpha: palette.isDark ? 0.6 : 0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

/// Realistic hardware shell: brushed metal rail, black bezel, island, side
/// keys, subtle rim light, and a glass sheen laid over the panel.
class _PhoneHardware extends StatelessWidget {
  const _PhoneHardware({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _kPhoneWidth,
        height: _kPhoneHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(3.2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(41),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF616A77),
                      Color(0xFF2A313C),
                      Color(0xFF11161E),
                      Color(0xFF3B4350),
                      Color(0xFF090D13),
                    ],
                    stops: [0, 0.16, 0.43, 0.76, 1],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33060A12),
                      blurRadius: 36,
                      spreadRadius: -5,
                      offset: Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Color(0x1C060A12),
                      blurRadius: 9,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4.8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05070C),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.7,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32.5),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: MediaQuery.withNoTextScaling(child: child),
                        ),
                        const Positioned.fill(
                          child: IgnorePointer(child: _ScreenGlass()),
                        ),
                        const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: _DynamicIsland(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: -1.4,
              top: 92,
              child: _SideKey(height: 26),
            ),
            const Positioned(
              left: -1.4,
              top: 128,
              child: _SideKey(height: 46),
            ),
            const Positioned(
              right: -1.4,
              top: 112,
              child: _SideKey(height: 64, isRight: true),
            ),
            Positioned(
              top: 3.4,
              left: 70,
              right: 70,
              child: Container(
                height: 0.7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideKey extends StatelessWidget {
  const _SideKey({required this.height, this.isRight = false});

  final double height;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.6,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF48505D), Color(0xFF11161E)],
        ),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isRight ? 0 : 2),
          right: Radius.circular(isRight ? 2 : 0),
        ),
      ),
    );
  }
}

class _ScreenGlass extends StatelessWidget {
  const _ScreenGlass();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.055),
                  Colors.white.withValues(alpha: 0.012),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.026),
                ],
                stops: const [0, 0.28, 0.62, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -110,
          left: -45,
          child: Transform.rotate(
            angle: 0.42,
            child: Container(
              width: 76,
              height: 530,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.085),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 19,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 7),
          child: Container(
            width: 5.2,
            height: 5.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.35, -0.35),
                radius: 0.85,
                colors: [Color(0xFF24446C), Color(0xFF03060A)],
                stops: [0.15, 1],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A believable chat thread, drawn at device scale. No emoji stand-ins and no
/// oversized marketing bubbles — just the app UI a person would actually see.
class _ChatMockup extends StatelessWidget {
  const _ChatMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A111C), Color(0xFF0B1320)],
        ),
      ),
      child: Column(
        children: [
          const _ChatStatusBar(),
          const _ChatHeader(),
          Container(height: 0.7, color: Colors.white.withValues(alpha: 0.055)),
          const _PrivacyNotice(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth - 20,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text(
                              'TODAY',
                              style: TextStyle(
                                color: Color(0xFF67758A),
                                fontSize: 5.8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          SizedBox(height: 7),
                          _IncomingBubble(
                            text: 'Are you on the new build?',
                            time: '09:36',
                          ),
                          SizedBox(height: 7),
                          _OutgoingBubble(
                            text: 'Yes, the new build landed.',
                            time: '09:37',
                          ),
                          SizedBox(height: 7),
                          _IncomingBubble(
                            text: 'Ready for the project sync?',
                            time: '09:38',
                          ),
                          SizedBox(height: 7),
                          _VoiceNoteBubble(),
                          SizedBox(height: 7),
                          _IncomingBubble(
                            text: 'Perfect. See you at 10.',
                            time: '09:39',
                          ),
                          SizedBox(height: 7),
                          _OutgoingBubble(
                            text: 'On my way.',
                            time: '09:40',
                          ),
                          SizedBox(height: 18),
                          _TypingRow(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const _ChatComposer(),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

class _ChatStatusBar extends StatelessWidget {
  const _ChatStatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 9, 13, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 8.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            const _SignalBars(),
            const SizedBox(width: 4),
            Icon(
              Icons.wifi_rounded,
              size: 8.4,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4.5),
            const _BatteryGlyph(),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();

  @override
  Widget build(BuildContext context) {
    const heights = [2.6, 3.8, 5.0, 6.2];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final height in heights)
          Container(
            width: 1.6,
            height: height,
            margin: const EdgeInsets.only(right: 1.2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(0.6),
            ),
          ),
      ],
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.5,
          height: 6.4,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 0.6,
            ),
            borderRadius: BorderRadius.circular(1.8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 8.4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(0.8),
              ),
            ),
          ),
        ),
        Container(
          width: 1.2,
          height: 2.6,
          margin: const EdgeInsets.only(left: 0.8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: Row(
        children: [
          Icon(
            DocmacIconlyLight.arrowLeft,
            size: 13,
            color: Colors.white.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 7),
          const _ChatAvatar(),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sophia Davis',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFF2F5F9),
                    fontSize: 9.6,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 1.5),
                Row(
                  children: [
                    Container(
                      width: 3.4,
                      height: 3.4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'online',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 6.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            DocmacIconlyLight.video,
            size: 13.5,
            color: Colors.white.withValues(alpha: 0.72),
          ),
          const SizedBox(width: 8),
          Icon(
            DocmacIconlyLight.call,
            size: 12.5,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF93B7FF), Color(0xFF3F6BD4)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5FCE).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 19,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              DocmacIconlyLight.lock,
              size: 6.8,
              color: Color(0xFF7E8BA0),
            ),
            SizedBox(width: 3.5),
            Text(
              'Conversations stay between their members',
              style: TextStyle(
                color: Color(0xFF7E8BA0),
                fontSize: 6.3,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 153),
        padding: const EdgeInsets.fromLTRB(8.5, 6.5, 8.5, 5),
        decoration: BoxDecoration(
          color: const Color(0xFF172131),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.045),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE9EEF6),
                fontSize: 8.1,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFF77849A),
                fontSize: 5.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingBubble extends StatelessWidget {
  const _OutgoingBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 153),
        padding: const EdgeInsets.fromLTRB(9, 6.5, 8, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E80FA), Color(0xFF1D63D9)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D63D9).withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.1,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 5.8,
                  ),
                ),
                const SizedBox(width: 2.4),
                Icon(
                  Icons.done_all_rounded,
                  size: 7,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceNoteBubble extends StatelessWidget {
  const _VoiceNoteBubble();

  static const _waveHeights = <double>[
    4,
    8,
    13,
    6.5,
    11,
    16,
    9,
    5,
    12,
    7.5,
    14,
    4.5,
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 166,
            padding: const EdgeInsets.fromLTRB(6, 6, 7, 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E80FA), Color(0xFF1D63D9)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D63D9).withValues(alpha: 0.3),
                  blurRadius: 9,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.17),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final height in _waveHeights)
                        Container(
                          width: 1.5,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '0:28',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 6.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2534),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    DocmacIconlyLight.heart,
                    size: 6.2,
                    color: Color(0xFFFF7A8E),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sophia is typing',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.44),
            fontSize: 6.1,
          ),
        ),
        const SizedBox(width: 4),
        for (final opacity in [0.8, 0.5, 0.26])
          Container(
            width: 2.1,
            height: 2.1,
            margin: const EdgeInsets.only(right: 1.6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF182231),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Icon(
              DocmacIconlyLight.plus,
              size: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 29,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF121B28),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 7.3,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    DocmacIconlyLight.camera,
                    size: 8.5,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3C8BFF), Color(0xFF1C61D7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D63D9).withValues(alpha: 0.3),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              DocmacIconlyLight.voice,
              size: 11.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 11,
      child: Center(
        child: Container(
          width: 44,
          height: 2.4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSheet extends StatelessWidget {
  const _WelcomeSheet({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 22, 24, 14 + bottomInset),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: palette.hairline, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(
              alpha: palette.isDark ? 0.5 : 0.07,
            ),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandLockup(palette: palette),
          const SizedBox(height: 16),
          Text(
            'The people that matter.\nAlways within reach.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: palette.foreground,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.12,
              letterSpacing: -1.15,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Private talks, close circles, and live moments.\n'
              'Built for the people who matter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.muted,
                fontSize: 13,
                height: 1.45,
                letterSpacing: 0.05,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TrustRow(palette: palette),
          const SizedBox(height: 22),
          _GetStartedButton(
            palette: palette,
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/register');
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/auth');
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: palette.foreground,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: palette.subtle.withValues(alpha: 0.6),
                      decorationThickness: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The real Docmac mark, not a stock chat glyph, with a restrained brand glow.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(
                  alpha: palette.isDark ? 0.2 : 0.13,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const DocmacMark(size: 29),
        ),
        const SizedBox(width: 9),
        Text(
          'Docmac',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: palette.foreground,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

/// Three quiet assurances with hairlines, rather than a row of pill badges.
class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrustSignal(
            icon: DocmacIconlyLight.shieldDone,
            label: 'END-TO-END ENCRYPTED',
            palette: palette,
          ),
          _TrustDivider(palette: palette),
          _TrustSignal(
            icon: DocmacIconlyLight.hide,
            label: 'NO TRACKING',
            palette: palette,
          ),
          _TrustDivider(palette: palette),
          _TrustSignal(
            icon: DocmacIconlyLight.lock,
            label: 'ZERO PLAINTEXT',
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _TrustSignal extends StatelessWidget {
  const _TrustSignal({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: palette.brand),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: palette.subtle,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.55,
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 11,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: palette.hairline,
    );
  }
}

/// A tactile ink pill with a pressed state, inner edge light, and layered
/// shadow. The arrow sits in its own recessed well.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({
    required this.palette,
    required this.onPressed,
  });

  final _HeroPalette palette;
  final VoidCallback onPressed;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final isDark = palette.isDark;
    // The pill inverts: dark ink on a white pill in dark mode, white ink on a
    // near-black pill in light mode. Using palette.foreground here painted
    // near-white text on a white pill and made the label disappear.
    final foreground = isDark ? const Color(0xFF0B1220) : Colors.white;
    final radius = BorderRadius.circular(28);

    return Semantics(
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFFFFFFFF), Color(0xFFE7ECF3)]
                    : const [Color(0xFF172033), Color(0xFF080D15)],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.09),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(
                    alpha: isDark ? 0.32 : 0.18,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: InkWell(
                onTap: widget.onPressed,
                onHighlightChanged: (value) {
                  if (mounted) setState(() => _pressed = value);
                },
                splashColor: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.07),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.1),
                          border: Border.all(
                            color: (isDark ? Colors.black : Colors.white)
                                .withValues(alpha: 0.07),
                            width: 0.6,
                          ),
                        ),
                        child: Icon(
                          DocmacIconlyLight.arrowRight,
                          size: 14,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPalette {
  const _HeroPalette({
    required this.isDark,
    required this.canvas,
    required this.topCanvas,
    required this.bottomCanvas,
    required this.foreground,
    required this.muted,
    required this.subtle,
    required this.hairline,
    required this.surface,
    required this.brand,
    required this.haloCenter,
    required this.haloMid,
    required this.haloEdge,
    required this.haloRim,
    required this.shadow,
    required this.grain,
  });

  factory _HeroPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return _HeroPalette(
        isDark: true,
        canvas: const Color(0xFF080B12),
        topCanvas: const Color(0xFF0F1622),
        bottomCanvas: const Color(0xFF05070B),
        foreground: const Color(0xFFF4F7FB),
        muted: const Color(0xFF9AA6B8),
        subtle: const Color(0xFF7E8BA0),
        hairline: Colors.white.withValues(alpha: 0.09),
        surface: const Color(0xFF0B1018),
        brand: const Color(0xFF6BA3FF),
        haloCenter: const Color(0x3D2E7BEA),
        haloMid: const Color(0x141E4A80),
        haloEdge: const Color(0x00000000),
        haloRim: Colors.white.withValues(alpha: 0.045),
        shadow: Colors.black,
        grain: Colors.white.withValues(alpha: 0.03),
      );
    }

    return _HeroPalette(
      isDark: false,
      canvas: const Color(0xFFF8F9FB),
      topCanvas: const Color(0xFFF1F5FA),
      bottomCanvas: const Color(0xFFECF0F6),
      foreground: const Color(0xFF0B1220),
      muted: const Color(0xFF5D697B),
      subtle: const Color(0xFF68758A),
      hairline: const Color(0xFFE7EAF0),
      surface: Colors.white,
      brand: AppColors.primary,
      haloCenter: const Color(0xF2FFFFFF),
      haloMid: const Color(0x99E4EEFB),
      haloEdge: const Color(0x00E4EEFB),
      haloRim: Colors.white.withValues(alpha: 0.65),
      shadow: const Color(0xFF0B1220),
      grain: const Color(0xFF0B1220).withValues(alpha: 0.05),
    );
  }

  final bool isDark;
  final Color canvas;
  final Color topCanvas;
  final Color bottomCanvas;
  final Color foreground;
  final Color muted;
  final Color subtle;
  final Color hairline;
  final Color surface;
  final Color brand;
  final Color haloCenter;
  final Color haloMid;
  final Color haloEdge;
  final Color haloRim;
  final Color shadow;
  final Color grain;
}
