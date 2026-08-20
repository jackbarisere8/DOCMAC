import 'package:flutter/material.dart';

/// The shared Docmac link mark used throughout the app.
class DocmacMark extends StatelessWidget {
  const DocmacMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .25),
        child: Image.asset(
          'assets/images/docmac_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      );
}
