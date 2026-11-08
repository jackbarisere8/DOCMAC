import 'package:flutter/material.dart';

/// A consistent, WhatsApp-style row for every three-dot popup menu.
///
/// Keeping the leading icon rail fixed means menu labels line up across the
/// app, while the quiet icon colour lets the label stay the focal point.
class DocmacMenuItem extends StatelessWidget {
  const DocmacMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = destructive ? scheme.error : scheme.onSurface;
    final iconColor = destructive ? scheme.error : scheme.onSurfaceVariant;

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
