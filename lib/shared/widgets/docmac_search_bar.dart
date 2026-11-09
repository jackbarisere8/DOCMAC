import 'package:flutter/material.dart';

import '../../core/ui/docmac_iconly.dart';

/// The app-wide search field.
///
/// A soft, fully rounded pill with a muted fill and a single leading search
/// icon. It deliberately has no outline or elevated shadow so every search
/// surface in Docmac reads as one consistent control.
class DocmacSearchBar extends StatefulWidget {
  const DocmacSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onCleared,
    this.autofocus = false,
    this.enabled = true,
    this.fieldKey,
    this.clearButtonKey,
    this.clearTooltip = 'Clear search',
    this.semanticsLabel,
    this.trailing,
    this.height = 50,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
    this.showClearButton = true,
  });

  /// Optional external controller. When omitted the field owns its value.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;

  /// Called after the built-in clear button empties the field.
  final VoidCallback? onCleared;
  final bool autofocus;
  final bool enabled;

  /// Key applied to the inner [TextField], useful for widget tests.
  final Key? fieldKey;

  /// Key applied to the built-in clear button.
  final Key? clearButtonKey;
  final String clearTooltip;
  final String? semanticsLabel;

  /// Optional action shown when the field is empty (for example a filter).
  /// It is replaced by the clear action while the field has text.
  final Widget? trailing;
  final double height;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool showClearButton;

  @override
  State<DocmacSearchBar> createState() => _DocmacSearchBarState();
}

class _DocmacSearchBarState extends State<DocmacSearchBar> {
  late final TextEditingController _ownedController = TextEditingController();

  TextEditingController get _controller =>
      widget.controller ?? _ownedController;

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fillColor = theme.colorScheme.surfaceContainerHigh;
    final iconColor = theme.colorScheme.onSurface;
    final hintColor =
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.82);
    final textColor = theme.colorScheme.onSurface;

    final radius = widget.height / 2;

    return Semantics(
      textField: true,
      label: widget.semanticsLabel ?? widget.hintText,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(DocmacIconlyLight.search, size: 21, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final showClear =
                      widget.showClearButton && value.text.isNotEmpty;

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: widget.fieldKey,
                          controller: _controller,
                          focusNode: widget.focusNode,
                          autofocus: widget.autofocus,
                          enabled: widget.enabled,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          onTap: widget.onTap,
                          textInputAction: widget.textInputAction,
                          textCapitalization: widget.textCapitalization,
                          cursorColor: iconColor,
                          cursorWidth: 1.6,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.1,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (showClear)
                        IconButton(
                          key: widget.clearButtonKey,
                          tooltip: widget.clearTooltip,
                          onPressed: _clear,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: iconColor,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                        )
                      else if (widget.trailing != null)
                        widget.trailing!,
                      const SizedBox(width: 12),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
