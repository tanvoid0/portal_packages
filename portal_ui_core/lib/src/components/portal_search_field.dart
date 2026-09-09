import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/portal_radii_utils.dart';

/// Filled, borderless, pill-shaped search field with a soft shadow.
///
/// Generalizes the search field six apps had each hand-rolled separately —
/// a [Container] carrying the fill/radius/shadow with a borderless [TextField]
/// inside it. Reads its fill, radius, spacing and text colors from
/// [PortalUiTheme] so it re-skins per-app like every other shared component.
class PortalSearchField extends StatelessWidget {
  const PortalSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  /// Defaults to a search icon in the muted color.
  final Widget? leading;

  /// E.g. a clear button. Optional.
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final radius = t.radii.circular(t.radii.lg);
    final muted = portal.mutedForeground;

    return Container(
      decoration: BoxDecoration(
        color: portal.input,
        borderRadius: radius,
        boxShadow: t.elevation.soft(brightness),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        focusNode: focusNode,
        style: TextStyle(color: portal.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: muted),
          prefixIcon: leading ?? Icon(Icons.search, color: muted),
          suffixIcon: trailing,
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
