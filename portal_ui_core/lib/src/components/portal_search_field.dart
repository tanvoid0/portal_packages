import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/portal_radii_utils.dart';

/// Filled, borderless, pill-shaped search field with a soft shadow.
///
/// Generalizes the search field six apps had each hand-rolled separately —
/// a [Container] carrying the fill/radius/shadow with a borderless [TextField]
/// inside it. Reads its fill, radius, spacing and text colors from
/// [PortalUiTheme] so it re-skins per-app like every other shared component.
class PortalSearchField extends StatefulWidget {
  const PortalSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
    this.onClear,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  /// Defaults to a search icon in the muted color.
  final Widget? leading;

  /// E.g. a filter button. Optional; sits after the clear button.
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Draws a "Clear search" button while there is text. It empties the field,
  /// calls [onChanged] with `''`, then this. Without a [controller] the field
  /// keeps its own to watch.
  final VoidCallback? onClear;

  @override
  State<PortalSearchField> createState() => _PortalSearchFieldState();
}

class _PortalSearchFieldState extends State<PortalSearchField> {
  TextEditingController? _own;

  // Null when the caller gave none and nothing here needs to watch the text.
  TextEditingController? get _c => widget.controller ??
      (widget.onClear == null ? null : _own ??= TextEditingController());

  void _clear() {
    _c!.clear();
    widget.onChanged?.call('');
    widget.onClear!();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final radius = t.radii.circular(t.radii.lg);
    final muted = portal.mutedForeground;
    final clearable = widget.onClear != null;

    return Container(
      decoration: BoxDecoration(
        color: portal.input,
        borderRadius: radius,
        boxShadow: t.elevation.soft(brightness),
      ),
      child: TextField(
        controller: _c,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        style: TextStyle(color: portal.onSurface),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: muted),
          prefixIcon:
              widget.leading ?? Icon(Symbols.search_rounded, color: muted),
          suffixIcon: clearable
              ? ListenableBuilder(
                  listenable: _c!,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_c!.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          icon: Icon(Symbols.close_rounded, color: muted),
                          onPressed: _clear,
                        ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                )
              : widget.trailing,
          // Nothing to reserve the end for while the field is empty.
          suffixIconConstraints: clearable ? const BoxConstraints() : null,
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.spacing.lg,
            vertical: t.spacing.md,
          ),
        ),
      ),
    );
  }
}
