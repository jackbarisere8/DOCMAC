import 'package:flutter/material.dart';

/// Avatar used by both the profile and the Connections hub.
///
/// The coloured tint comes from the person's record so the same face keeps the
/// same identity everywhere. A hairline ring separates it from busy surfaces.
class ConnectionAvatar extends StatelessWidget {
  const ConnectionAvatar({
    super.key,
    required this.initials,
    required this.tint,
    this.size = 48,
    this.isOnline = false,
    this.showRing = false,
  });

  final String initials;
  final Color tint;
  final double size;
  final bool isOnline;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : scheme.onSurface;

    return SizedBox(
      width: size + (isOnline ? 2 : 0),
      height: size + (isOnline ? 2 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: showRing ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: showRing
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tint.withValues(alpha: .95),
                        scheme.primary,
                        const Color(0xFF7AD7F0),
                      ],
                    )
                  : null,
              border: showRing
                  ? null
                  : Border.all(color: scheme.outlineVariant, width: 1),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(
                  tint.withValues(alpha: isDark ? .32 : .20),
                  scheme.surface,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: foreground,
                  fontSize: size * .32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * .26,
                height: size * .26,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
