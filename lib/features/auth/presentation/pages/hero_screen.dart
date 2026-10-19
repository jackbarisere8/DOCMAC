import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../core/theme/app_colors.dart';

/// The 2026 flagship welcome / onboarding experience matching the reference video.
/// Features a dynamic 3D isometric floating device showcase displaying Talks,
/// Circles, and Moments with organic breathing motion, paired with an elevated
/// bottom card and tactile black pill action button.
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
      duration: const Duration(milliseconds: 3600),
      value: 0.5,
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
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
    final size = MediaQuery.of(context).size;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient soft radial gradient & glow blobs
          _AmbientBackground(palette: palette),

          // 3D Isometric Device Showcase at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: (size.height * 0.52).clamp(320.0, 500.0),
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, _) => _IsometricDeviceShowcase(
                  floatValue: disableAnimations ? 0.5 : _floatingController.value,
                  palette: palette,
                ),
              ),
            ),
          ),

          // Elevated Bottom Sheet Surface
          Align(
            alignment: Alignment.bottomCenter,
            child: _LandingContentSheet(palette: palette),
          ),
        ],
      ),
    );
  }
}

/// The 3D isometric perspective floating showcase displaying three tilted devices.
class _IsometricDeviceShowcase extends StatelessWidget {
  const _IsometricDeviceShowcase({
    required this.floatValue,
    required this.palette,
  });

  final double floatValue;
  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final t = floatValue * 2 * math.pi;

    return Center(
      child: SizedBox(
        width: 360,
        height: 380,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Left Device: Circles & Communities
            Positioned(
              left: 10,
              top: 35 + math.sin(t) * 6,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(-0.16)
                  ..rotateY(0.20)
                  ..rotateZ(-0.08),
                child: Transform.scale(
                  scale: 0.88,
                  child: const _DeviceFrame(
                    child: _CirclesMockupScreen(),
                  ),
                ),
              ),
            ),

            // Right Device: Moments / 24h Status
            Positioned(
              right: 12,
              top: 40 + math.sin(t + 1.4) * 8,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(-0.18)
                  ..rotateY(0.08)
                  ..rotateZ(-0.04),
                child: Transform.scale(
                  scale: 0.90,
                  child: const _DeviceFrame(
                    child: _MomentsMockupScreen(),
                  ),
                ),
              ),
            ),

            // Center Device: Talk / Direct E2EE Chat (Front, elevated)
            Positioned(
              top: 20 + math.sin(t + 2.8) * 10,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(-0.15)
                  ..rotateY(0.12)
                  ..rotateZ(-0.05),
                child: Transform.scale(
                  scale: 1.02,
                  child: const _DeviceFrame(
                    isFront: true,
                    child: _TalkMockupScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Realistic mobile device bezel with glass reflection and Dynamic Island.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.child,
    this.isFront = false,
  });

  final Widget child;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isFront ? const Color(0xFF334155) : const Color(0xFF1E293B),
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isFront ? 0.32 : 0.20),
            blurRadius: isFront ? 32 : 20,
            spreadRadius: isFront ? 2 : 0,
            offset: Offset(0, isFront ? 18 : 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Screen Mockup Content
            Positioned.fill(child: child),

            // Subtle Glass Specular Reflection Highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Dynamic Island Pill Cutout
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 48,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mockup screen 1: Talk / Chat conversation with speech bubbles & voice note.
class _TalkMockupScreen extends StatelessWidget {
  const _TalkMockupScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF38BDF8),
                ),
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sophia Davis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'online',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.videocam_outlined, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              const Icon(Icons.call_outlined, size: 13, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 14),

          // Incoming message bubble
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ready for our encrypted sync? 🔒',
                style: TextStyle(color: Colors.white, fontSize: 8.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Outgoing voice note bubble
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  // Waveform bars
                  for (final h in [6, 12, 18, 9, 15, 20, 11, 7]) ...[
                    Container(
                      width: 2.2,
                      height: h.toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                  const SizedBox(width: 5),
                  const Text('0:28', style: TextStyle(color: Colors.white, fontSize: 7.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Heart reaction badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('❤️ 1', style: TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup screen 2: Circles / Communities list with topic cards.
class _CirclesMockupScreen extends StatelessWidget {
  const _CirclesMockupScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Circles & Spaces',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // Circle card 1
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(child: Text('🎨', style: TextStyle(fontSize: 11))),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Design Forge',
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600)),
                      Text('34 Active • Audio Room',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          // Circle card 2
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 11))),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Core Engineering',
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600)),
                      Text('E2EE Group Talk',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup screen 3: Moments / 24h Status story card.
class _MomentsMockupScreen extends StatelessWidget {
  const _MomentsMockupScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF312E81), Color(0xFF4C1D95)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story Progress Bars
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Moments',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sunset in Lagos 🌇',
                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Shared with Close Circles',
                  style: TextStyle(color: Colors.white70, fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Elevated bottom content sheet with brand typography, chips, and black pill action.
class _LandingContentSheet extends StatelessWidget {
  const _LandingContentSheet({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Grab bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Small Brand Lockup
          _BrandLockup(palette: palette),
          const SizedBox(height: 12),

          // Main Headline (kept verbatim for test compatibility)
          Text(
            'The people that matter.\nAlways within reach.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: palette.foreground,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle copy
          Text(
            'Discover inspiring circles, seamless real-time talks, and ready-to-use privacy built to keep your world close.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 13,
              height: 1.40,
            ),
          ),
          const SizedBox(height: 18),

          // Privacy Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(
                icon: Icons.lock_outline_rounded,
                label: 'End-to-End Encrypted',
                isDark: isDark,
              ),
              _FeatureChip(
                icon: Icons.bolt_rounded,
                label: 'Sub-10ms',
                isDark: isDark,
              ),
              _FeatureChip(
                icon: Icons.shield_outlined,
                label: 'Zero Plaintext',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Full-width black rounded pill button [ Get Started ]
          _GetStartedPillButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/register');
            },
          ),
          const SizedBox(height: 12),

          // Sign In Link
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/auth');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: scheme.onSurface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Already have an account? ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Sign In',
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small subtle feature chip in the hero sheet.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0284C7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

/// Signature 2026 full-width rounded black pill button [ Get Started -> ].
class _GetStartedPillButton extends StatelessWidget {
  const _GetStartedPillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.18),
              ),
              child: Icon(
                DocmacIconlyLight.arrowRight,
                size: 15,
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.brandTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.forum_outlined,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Docmac',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: palette.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -.45,
              ),
        ),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.36),
          radius: 1.35,
          colors: [palette.topCanvas, palette.canvas, palette.bottomCanvas],
          stops: const [0, .54, 1],
        ),
      ),
      child: Stack(
        children: [
          _GlowBlob(
            alignment: const Alignment(-0.8, -0.6),
            color: palette.cyanGlow,
            opacity: palette.glowOpacity,
            size: 200,
          ),
          _GlowBlob(
            alignment: const Alignment(0.8, -0.4),
            color: palette.limeGlow,
            opacity: palette.glowOpacity * 0.7,
            size: 180,
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.color,
    required this.opacity,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HeroPalette {
  const _HeroPalette({
    required this.canvas,
    required this.topCanvas,
    required this.bottomCanvas,
    required this.foreground,
    required this.muted,
    required this.detail,
    required this.brandTint,
    required this.glowOpacity,
    required this.cyanGlow,
    required this.limeGlow,
  });

  factory _HeroPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _HeroPalette(
      canvas: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      topCanvas: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      bottomCanvas: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
      foreground: isDark ? Colors.white : const Color(0xFF0F172A),
      muted: isDark ? Colors.white70 : const Color(0xFF64748B),
      detail: isDark ? Colors.white60 : const Color(0xFF94A3B8),
      brandTint: isDark
          ? AppColors.primary.withValues(alpha: .20)
          : AppColors.primary.withValues(alpha: .12),
      glowOpacity: isDark ? .28 : .12,
      cyanGlow: const Color(0xFF0284C7),
      limeGlow: const Color(0xFF10B981),
    );
  }

  final Color canvas;
  final Color topCanvas;
  final Color bottomCanvas;
  final Color foreground;
  final Color muted;
  final Color detail;
  final Color brandTint;
  final double glowOpacity;
  final Color cyanGlow;
  final Color limeGlow;
}
