import 'package:flutter/material.dart';

import '../../contrast_gate.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/portal_radii_utils.dart';

/// Tint of a tonal tile: `primaryContainer`, `tertiaryContainer` for
/// read-only status rows, `errorContainer` for destructive ones. Never a grey
/// secondary chip.
enum PortalListTone { primary, tertiary, error }

/// Outline of a [PortalIconTile]. [squircle] is `radii.md` in the theme's
/// corner family (continuous where the theme draws them): a detail hero's mark.
enum PortalIconTileShape { roundedSquare, circle, squircle }

/// The tonal tile of `PortalListLeading.tile`, usable anywhere (a card header,
/// a dashboard cell, a sheet row): a rounded square (or circle) holding a glyph.
///
/// Decorative unless [semanticLabel] is set. [PortalIconTile.builder] takes any
/// glyph (a `FaIcon`, an SVG) and hands it the ink to paint with.
class PortalIconTile extends StatelessWidget {
  const PortalIconTile(
    IconData icon, {
    super.key,
    this.tone = PortalListTone.primary,
    this.size = 40,
    this.shape = PortalIconTileShape.roundedSquare,
    this.glyphSize,
    this.backgroundColor,
    this.foregroundColor,
    this.autoContrastFrom,
    this.semanticLabel,
  })  : _icon = icon,
        _builder = null;

  const PortalIconTile.builder(
    Widget Function(BuildContext context, Color color) builder, {
    super.key,
    this.tone = PortalListTone.primary,
    this.size = 40,
    this.shape = PortalIconTileShape.roundedSquare,
    this.glyphSize,
    this.backgroundColor,
    this.foregroundColor,
    this.autoContrastFrom,
    this.semanticLabel,
  })  : _icon = null,
        _builder = builder;

  /// [PortalIconTile] with an emoji in the glyph's place (a habit's own mark),
  /// at the symbol's optical size -- the 20 live area of a 24 glyph -- so it
  /// weighs what the glyph it replaces does. Silent: the row's title names it.
  factory PortalIconTile.emoji(
    String emoji, {
    Key? key,
    PortalListTone tone = PortalListTone.primary,
    double size = 40,
    PortalIconTileShape shape = PortalIconTileShape.roundedSquare,
    double? glyphSize,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? autoContrastFrom,
    String? semanticLabel,
  }) {
    final glyph = glyphSize ?? size * .6;
    return PortalIconTile.builder(
      // Sized as an Icon is, and not scaled by text: the tile does not grow.
      (context, _) => Center(
        child: Text(
          emoji,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: glyph * 20 / 24, height: 1),
        ),
      ),
      key: key,
      tone: tone,
      size: size,
      shape: shape,
      glyphSize: glyphSize,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      autoContrastFrom: autoContrastFrom,
      semanticLabel: semanticLabel,
    );
  }

  /// The subject's mark on a detail hero: 56 across, a
  /// [PortalIconTileShape.squircle] round a 28 glyph.
  const PortalIconTile.hero(
    IconData icon, {
    Key? key,
    PortalListTone tone = PortalListTone.primary,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? autoContrastFrom,
    String? semanticLabel,
  }) : this(
          icon,
          key: key,
          tone: tone,
          size: 56,
          shape: PortalIconTileShape.squircle,
          glyphSize: 28,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          autoContrastFrom: autoContrastFrom,
          semanticLabel: semanticLabel,
        );

  /// [PortalIconTile.hero] with an emoji in the glyph's place.
  factory PortalIconTile.heroEmoji(
    String emoji, {
    Key? key,
    PortalListTone tone = PortalListTone.primary,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? autoContrastFrom,
    String? semanticLabel,
  }) =>
      PortalIconTile.emoji(
        emoji,
        key: key,
        tone: tone,
        size: 56,
        shape: PortalIconTileShape.squircle,
        glyphSize: 28,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        autoContrastFrom: autoContrastFrom,
        semanticLabel: semanticLabel,
      );

  final IconData? _icon;
  final Widget Function(BuildContext, Color)? _builder;
  final PortalListTone tone;

  /// `roundedSquare` (default, `radii.sm`), a `circle` or a `squircle`.
  final PortalIconTileShape shape;

  /// The painted square; the glyph is 60% of it (24 at the default 40).
  final double size;

  /// The glyph's size where 60% of [size] is not it (a mark at 50%).
  final double? glyphSize;

  /// Replace the [tone]'s pair.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// A category colour to derive the tile's (fill, glyph) pair from instead
  /// of [tone] — a tint of the surface, with the glyph stepped until it
  /// clears non-text contrast on it. See [categoryColors]. [backgroundColor]
  /// / [foregroundColor] still win when set.
  final Color? autoContrastFrom;

  /// Names the tile for a screen reader; null leaves it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = PortalUiTheme.of(context).tokens;
    final (bg, fg) = switch (tone) {
      PortalListTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      PortalListTone.tertiary => (cs.tertiaryContainer, cs.onTertiaryContainer),
      PortalListTone.error => (cs.errorContainer, cs.onErrorContainer),
    };
    final auto =
        autoContrastFrom == null ? null : categoryColors(context, autoContrastFrom!);
    final ink = foregroundColor ?? auto?.$2 ?? fg;
    final fill = backgroundColor ?? auto?.$1 ?? bg;
    final Decoration decoration = switch (shape) {
      PortalIconTileShape.circle =>
        BoxDecoration(color: fill, shape: BoxShape.circle),
      PortalIconTileShape.roundedSquare => BoxDecoration(
          color: fill, borderRadius: BorderRadius.circular(t.radii.sm)),
      PortalIconTileShape.squircle => ShapeDecoration(
          color: fill,
          shape: t.expressiveCorners
              ? t.radii.continuousBorder(
                  borderRadius: BorderRadius.circular(t.radii.md))
              : t.radii.roundedBorder(
                  borderRadius: BorderRadius.circular(t.radii.md)),
        ),
    };
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: _builder != null
          ? _builder(context, ink)
          : Icon(_icon, size: glyphSize ?? size * .6, color: ink),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: tile)
        : Semantics(
            label: semanticLabel,
            image: true,
            child: ExcludeSemantics(child: tile));
  }
}
