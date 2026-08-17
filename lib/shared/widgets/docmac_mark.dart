import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A compact, code-drawn mark for Docmac: connected square signals inside a
/// soft-cornered tile, representing people finding their place together.
class DocmacMark extends StatelessWidget {
  const DocmacMark({
    super.key,
    this.size = 64,
    this.primary = AppColors.brandBase,
    this.accent = AppColors.primary,
  });

  final double size;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DocmacMarkPainter(primary: primary, accent: accent),
      ),
    );
  }
}

class _DocmacMarkPainter extends CustomPainter {
  const _DocmacMarkPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * .25),
    );
    canvas.drawRRect(tile, Paint()..color = primary);

    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .07
      ..strokeCap = StrokeCap.square;
    final path = Path()
      ..moveTo(size.width * .26, size.height * .34)
      ..lineTo(size.width * .50, size.height * .34)
      ..lineTo(size.width * .50, size.height * .61)
      ..lineTo(size.width * .75, size.height * .61);
    canvas.drawPath(path, linePaint);

    for (final point in const [
      Offset(.19, .27),
      Offset(.43, .27),
      Offset(.43, .54),
      Offset(.68, .54),
    ]) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * point.dx, size.height * point.dy),
        width: size.width * .17,
        height: size.width * .17,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * .035)),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_DocmacMarkPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.accent != accent;
  }
}
