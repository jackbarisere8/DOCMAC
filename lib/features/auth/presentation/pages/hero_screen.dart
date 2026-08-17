import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../core/theme/app_colors.dart';

/// A full-screen, theme-aware welcome experience.
///
/// The message field is decorative; the content and its actions stay in the
/// safe area so the page feels edge-to-edge without colliding with system UI.
class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = _HeroPalette.of(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AmbientBackground(palette: palette),
          _MessageField(palette: palette),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: _LandingContent(
                  height: constraints.maxHeight,
                  palette: palette,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingContent extends StatelessWidget {
  const _LandingContent({required this.height, required this.palette});

  final double height;
  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The action remains anchored by the spacer below; this just brings the
    // Docmac lockup and message lower without creating more empty space.
    final topSpace = (height * .48).clamp(232.0, 468.0).toDouble();
    final heading = theme.textTheme.headlineLarge?.copyWith(
      color: palette.foreground,
      fontSize: 31,
      fontWeight: FontWeight.w800,
      height: 1.03,
      letterSpacing: -1.2,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: IntrinsicHeight(
        child: Column(
          children: [
            SizedBox(height: topSpace),
            _BrandLockup(palette: palette),
            const SizedBox(height: 18),
            Text(
              'The people that matter.\nAlways within reach.',
              textAlign: TextAlign.center,
              style: heading,
            ),
            const SizedBox(height: 11),
            Text(
              'A private place for the relationships that matter most.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Private  •  Fast  •  End-to-End Encrypted',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.detail,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const _GetStartedButton(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/auth'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                foregroundColor: palette.foreground,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: palette.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: () => context.go('/register'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.onPrimary.withValues(alpha: .14),
            ),
            child: Icon(DocmacIconlyLight.arrowRight,
                size: 17, color: scheme.onPrimary),
          ),
          const SizedBox(width: 10),
          const Text('Get started',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ],
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
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.brandTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.forum_outlined,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Docmac',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: palette.foreground,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -.55,
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
          center: const Alignment(0, -.32),
          radius: 1.32,
          colors: [palette.topCanvas, palette.canvas, palette.bottomCanvas],
          stops: const [0, .52, 1],
        ),
      ),
      child: Stack(
        children: [
          _GlowBlob(
            alignment: const Alignment(-1.12, -.58),
            color: palette.cyanGlow,
            opacity: palette.glowOpacity,
            size: 185,
          ),
          _GlowBlob(
            alignment: const Alignment(1.12, -.28),
            color: palette.limeGlow,
            opacity: palette.glowOpacity,
            size: 180,
          ),
          _GlowBlob(
            alignment: const Alignment(.93, .27),
            color: palette.violetGlow,
            opacity: palette.glowOpacity * .8,
            size: 160,
          ),
          _GlowBlob(
            alignment: const Alignment(-.97, .22),
            color: palette.cyanGlow,
            opacity: palette.glowOpacity * .7,
            size: 135,
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
        imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
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

class _MessageField extends StatelessWidget {
  const _MessageField({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 94,
            left: 48,
            child: _MessagePreview(
              name: 'Sophia',
              message: 'Are you coming?',
              tint: AppColors.accent,
              palette: palette,
              hasPhoto: true,
              turn: -.025,
            ),
          ),
          Positioned(
            top: 57,
            right: 33,
            child: _MessagePreview(
              name: 'Ava',
              message: 'New message',
              tint: const Color(0xFFF6B4C7),
              palette: palette,
              faded: true,
              turn: .035,
            ),
          ),
          Positioned(
            top: 177,
            left: 9,
            child: _MessagePreview(
              name: 'Noah',
              message: 'Just joined your circle',
              tint: const Color(0xFFD66D88),
              palette: palette,
              faded: true,
              turn: -.02,
            ),
          ),
          Positioned(
            top: 177,
            right: 45,
            child: _MessagePreview(
              name: 'James',
              message: 'Shared 3 photos',
              tint: const Color(0xFF9B2B4A),
              palette: palette,
              hasPhoto: true,
              turn: .035,
            ),
          ),
          Positioned(
            top: 259,
            right: 12,
            child: _MessagePreview(
              name: 'Emma',
              message: 'Voice message',
              tint: AppColors.primary,
              palette: palette,
              hasPhoto: true,
              turn: -.02,
            ),
          ),
          Positioned(
            top: 279,
            left: 53,
            child: _VoicePreview(palette: palette),
          ),
          Positioned(
            top: 322,
            left: 4,
            child: _MessagePreview(
              name: 'Mia',
              message: 'Sent you a reaction',
              tint: const Color(0xFFE986A2),
              palette: palette,
              faded: true,
              turn: .025,
            ),
          ),
          Positioned(
            bottom: 70,
            right: 30,
            child: _Sparkle(color: palette.sparkle),
          ),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.name,
    required this.message,
    required this.tint,
    required this.palette,
    required this.turn,
    this.hasPhoto = false,
    this.faded = false,
  });

  final String name;
  final String message;
  final Color tint;
  final _HeroPalette palette;
  final double turn;
  final bool hasPhoto;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? .34 : 1,
      child: Transform.rotate(
        angle: turn,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: palette.messageSurface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: palette.messageBorder),
                boxShadow: [
                  BoxShadow(
                    color: palette.messageShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _Avatar(name: name, tint: tint, hasPhoto: hasPhoto),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.messageText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          message,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.messageDetail,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.tint,
    required this.hasPhoto,
  });

  final String name;
  final Color tint;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint,
                  tint.withValues(alpha: .45),
                  AppColors.brandBase
                ],
              )
            : null,
        color: hasPhoto ? null : tint,
      ),
      child: hasPhoto
          ? Icon(Icons.person_rounded,
              color: Colors.white.withValues(alpha: .9), size: 18)
          : Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: AppColors.brandBase,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _VoicePreview extends StatelessWidget {
  const _VoicePreview({required this.palette});

  final _HeroPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 79,
          height: 42,
          decoration: BoxDecoration(
            color: palette.messageSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.messageBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VoiceDot(height: 6),
              SizedBox(width: 5),
              _VoiceDot(height: 14, active: true),
              SizedBox(width: 5),
              _VoiceDot(height: 20, active: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceDot extends StatelessWidget {
  const _VoiceDot({required this.height, this.active = false});

  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : Colors.white70,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: .785,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
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
    required this.messageSurface,
    required this.messageBorder,
    required this.messageText,
    required this.messageDetail,
    required this.messageShadow,
    required this.brandTint,
    required this.sparkle,
    required this.glowOpacity,
    required this.cyanGlow,
    required this.limeGlow,
    required this.violetGlow,
  });

  factory _HeroPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _HeroPalette(
      canvas: scheme.surface,
      topCanvas: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      bottomCanvas: isDark ? AppColors.darkSurface : scheme.surface,
      foreground: scheme.onSurface,
      muted: isDark
          ? Colors.white.withValues(alpha: .72)
          : scheme.onSurfaceVariant,
      detail: isDark
          ? Colors.white.withValues(alpha: .84)
          : scheme.onSurface.withValues(alpha: .76),
      messageSurface: isDark
          ? Colors.white.withValues(alpha: .18)
          : Colors.white.withValues(alpha: .78),
      messageBorder: isDark
          ? Colors.white.withValues(alpha: .25)
          : AppColors.lightDivider.withValues(alpha: .82),
      messageText: isDark ? Colors.white : scheme.onSurface,
      messageDetail: isDark
          ? Colors.white.withValues(alpha: .72)
          : scheme.onSurfaceVariant,
      messageShadow: isDark
          ? Colors.black.withValues(alpha: .16)
          : AppColors.lightTextSecondary.withValues(alpha: .13),
      brandTint: isDark
          ? AppColors.primary.withValues(alpha: .16)
          : AppColors.primary.withValues(alpha: .14),
      sparkle: isDark
          ? Colors.white.withValues(alpha: .44)
          : AppColors.primary.withValues(alpha: .38),
      glowOpacity: isDark ? .33 : .14,
      cyanGlow: AppColors.primary,
      limeGlow: AppColors.accent,
      violetGlow: const Color(0xFF8D2441),
    );
  }

  final Color canvas;
  final Color topCanvas;
  final Color bottomCanvas;
  final Color foreground;
  final Color muted;
  final Color detail;
  final Color messageSurface;
  final Color messageBorder;
  final Color messageText;
  final Color messageDetail;
  final Color messageShadow;
  final Color brandTint;
  final Color sparkle;
  final double glowOpacity;
  final Color cyanGlow;
  final Color limeGlow;
  final Color violetGlow;
}
