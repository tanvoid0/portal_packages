import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_icon_tile.dart';
import 'portal_pressable.dart';

/// A dashboard shortcut: a glyph over a short label on a tonal tile
/// ("Add expense", "Scan"). Lay several out in a `Row` of `Expanded`s or a
/// `GridView`; the tile fills the width it is given and is at least
/// `minTapTarget` tall.
///
/// The label is the accessible name; [tooltip] replaces it where the label is
/// ambiguous out of context ("Add expense to Rent"). [PortalQuickAction.builder]
/// takes any glyph (a `FaIcon`, an SVG).
class PortalQuickAction extends StatelessWidget {
  const PortalQuickAction({
    super.key,
    required IconData icon,
    required this.label,
    required this.onTap,
    this.tone = PortalListTone.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  })  : _icon = icon,
        _builder = null;

  const PortalQuickAction.builder({
    super.key,
    required Widget Function(BuildContext context, Color color) builder,
    required this.label,
    required this.onTap,
    this.tone = PortalListTone.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  })  : _icon = null,
        _builder = builder;

  final IconData? _icon;
  final Widget Function(BuildContext, Color)? _builder;
  final String label;
  final VoidCallback? onTap;
  final PortalListTone tone;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      PortalListTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      PortalListTone.tertiary => (cs.tertiaryContainer, cs.onTertiaryContainer),
      PortalListTone.error => (cs.errorContainer, cs.onErrorContainer),
    };
    final ink = foregroundColor ?? fg;
    final radius = BorderRadius.circular(tokens.radii.md);

    Widget tile = PortalPressable(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.minTapTarget),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sm,
          vertical: tokens.spacing.md,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? bg,
          borderRadius: radius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: _builder != null
                  ? _builder(context, ink)
                  : Icon(_icon, size: 24, color: ink),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.textStyles.caption.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
    if (tooltip != null) tile = Tooltip(message: tooltip!, child: tile);
    return tile;
  }
}
