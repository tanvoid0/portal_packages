import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Tint of a tonal tile: `primaryContainer`, `tertiaryContainer` for
/// read-only status rows, `errorContainer` for destructive ones. Never a grey
/// secondary chip.
enum PortalListTone { primary, tertiary, error }

/// The tonal tile of `PortalListLeading.tile`, usable anywhere (a card header,
/// a dashboard cell, a sheet row): a rounded square holding a glyph.
///
/// Decorative unless [semanticLabel] is set. [PortalIconTile.builder] takes any
/// glyph (a `FaIcon`, an SVG) and hands it the ink to paint with.
class PortalIconTile extends StatelessWidget {
  const PortalIconTile(
    IconData icon, {
    super.key,
    this.tone = PortalListTone.primary,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  })  : _icon = icon,
        _builder = null;

  const PortalIconTile.builder(
    Widget Function(BuildContext context, Color color) builder, {
    super.key,
    this.tone = PortalListTone.primary,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  })  : _icon = null,
        _builder = builder;

  final IconData? _icon;
  final Widget Function(BuildContext, Color)? _builder;
  final PortalListTone tone;

  /// The painted square; the glyph is 60% of it (24 at the default 40).
  final double size;

  /// Replace the [tone]'s pair.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Names the tile for a screen reader; null leaves it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      PortalListTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      PortalListTone.tertiary => (cs.tertiaryContainer, cs.onTertiaryContainer),
      PortalListTone.error => (cs.errorContainer, cs.onErrorContainer),
    };
    final ink = foregroundColor ?? fg;
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? bg,
        borderRadius:
            BorderRadius.circular(PortalUiTheme.of(context).tokens.radii.sm),
      ),
      child: _builder != null
          ? _builder(context, ink)
          : Icon(_icon, size: size * .6, color: ink),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: tile)
        : Semantics(
            label: semanticLabel,
            image: true,
            child: ExcludeSemantics(child: tile));
  }
}
